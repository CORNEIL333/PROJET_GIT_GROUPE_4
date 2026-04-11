#!/bin/bash
# ============================================================================
# Hook: post-receive
# Description: Notifications et actions automatiques après un push Git
# Emplacement: /home/git/repos/MON_DEPOT.git/hooks/post-receive
# Version: 3.0
# ============================================================================

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

# Fichiers de log
LOG_DIR="/home/git/logs"
HOOK_LOG="$LOG_DIR/post-receive.log"
ALERT_LOG="$LOG_DIR/alerts.log"

# Configuration notifications
ENABLE_EMAIL=true
ENABLE_WEBHOOK=false
ENABLE_TELEGRAM=false
ENABLE_DISCORD=false
ENABLE_SLACK=false

# Destinataires
ADMIN_EMAIL="admin@universite.fr"
WEBHOOK_URL="${WEBHOOK_URL:-https://webhook.site/xxx}"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"
DISCORD_WEBHOOK="${DISCORD_WEBHOOK:-}"
SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"

# Configuration dépôt
REPO_NAME=$(basename "$(pwd)" .git)
REPO_DESC=$(cat description 2>/dev/null || echo "Dépôt Git")
REPO_OWNER="${REPO_OWNER:-git}"

# Configuration sécurité
MAX_COMMIT_SIZE=10485760  # 10MB
ALLOW_FORCE_PUSH=false

# ============================================================================
# Fonctions utilitaires
# ============================================================================

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    mkdir -p "$LOG_DIR"
    echo "[$timestamp] [$level] $message" >> "$HOOK_LOG"
    
    # Affichage console
    case "$level" in
        "ERROR")   echo -e "\033[0;31m❌ $message\033[0m" >&2 ;;
        "WARNING") echo -e "\033[1;33m⚠️  $message\033[0m" >&2 ;;
        "SUCCESS") echo -e "\033[0;32m✅ $message\033[0m" ;;
        "INFO")    echo -e "\033[0;34mℹ️  $message\033[0m" ;;
        *)         echo "$message" ;;
    esac
}

send_email() {
    local subject="$1"
    local body="$2"
    
    if ! $ENABLE_EMAIL; then return 0; fi
    
    if command -v mail &> /dev/null; then
        echo "$body" | mail -s "[Git] $subject" "$ADMIN_EMAIL"
        log_message "INFO" "Email envoyé à $ADMIN_EMAIL"
    else
        log_message "WARNING" "mail command not found. Install mailutils or sendmail"
    fi
}

send_webhook() {
    local payload="$1"
    
    if ! $ENABLE_WEBHOOK; then return 0; fi
    
    if command -v curl &> /dev/null; then
        curl -X POST -H "Content-Type: application/json" \
             -d "$payload" \
             "$WEBHOOK_URL" &> /dev/null || true
        log_message "INFO" "Webhook déclenché"
    fi
}

send_telegram() {
    local message="$1"
    
    if ! $ENABLE_TELEGRAM; then return 0; fi
    if [[ -z "$TELEGRAM_BOT_TOKEN" ]] || [[ -z "$TELEGRAM_CHAT_ID" ]]; then return 0; fi
    
    local url="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
    curl -s -X POST "$url" \
         -d "chat_id=${TELEGRAM_CHAT_ID}" \
         -d "text=${message}" \
         -d "parse_mode=HTML" &> /dev/null || true
    log_message "INFO" "Notification Telegram envoyée"
}

send_discord() {
    local message="$1"
    
    if ! $ENABLE_DISCORD; then return 0; fi
    if [[ -z "$DISCORD_WEBHOOK" ]]; then return 0; fi
    
    local payload=$(jq -n --arg content "$message" '{content: $content}')
    curl -s -X POST -H "Content-Type: application/json" \
         -d "$payload" \
         "$DISCORD_WEBHOOK" &> /dev/null || true
    log_message "INFO" "Notification Discord envoyée"
}

send_slack() {
    local message="$1"
    
    if ! $ENABLE_SLACK; then return 0; fi
    if [[ -z "$SLACK_WEBHOOK" ]]; then return 0; fi
    
    local payload=$(jq -n --arg text "$message" '{text: $text}')
    curl -s -X POST -H "Content-Type: application/json" \
         -d "$payload" \
         "$SLACK_WEBHOOK" &> /dev/null || true
    log_message "INFO" "Notification Slack envoyée"
}

# ============================================================================
# Analyse des commits
# ============================================================================

analyze_commits() {
    local oldrev="$1"
    local newrev="$2"
    
    # Si c'est un nouveau dépôt ou création de branche
    if [[ "$oldrev" == "0000000000000000000000000000000000000000" ]]; then
        echo "📝 Nouvelle branche créée"
        return 0
    fi
    
    # Si c'est une suppression de branche
    if [[ "$newrev" == "0000000000000000000000000000000000000000" ]]; then
        echo "🗑️  Branche supprimée"
        return 0
    fi
    
    # Récupérer la liste des commits
    local commits=$(git rev-list --reverse "$oldrev..$newrev" 2>/dev/null || echo "")
    
    if [[ -n "$commits" ]]; then
        local commit_count=$(echo "$commits" | wc -l)
        echo "📊 $commit_count nouveau(x) commit(s) :"
        
        local count=0
        echo "$commits" | while read -r commit; do
            count=$((count + 1))
            local short_hash=$(git log -1 --format=%h "$commit" 2>/dev/null || echo "$commit" | cut -c1-7)
            local author=$(git log -1 --format=%an "$commit" 2>/dev/null || echo "Inconnu")
            local subject=$(git log -1 --format=%s "$commit" 2>/dev/null || echo "Sans message")
            
            echo "  $count. [$short_hash] $subject ($author)"
            
            # Vérifier la taille du commit
            local commit_size=$(git cat-file -s "$commit" 2>/dev/null || echo 0)
            if [[ $commit_size -gt $MAX_COMMIT_SIZE ]]; then
                log_message "WARNING" "Commit $short_hash dépasse la taille maximale (${commit_size} bytes)"
            fi
        done
    fi
}

# ============================================================================
# Vérifications de sécurité
# ============================================================================

check_force_push() {
    local oldrev="$1"
    local newrev="$2"
    local refname="$3"
    
    if ! $ALLOW_FORCE_PUSH; then
        # Vérifier si c'est un force push
        local is_force=false
        
        # Vérifier si des commits ont été perdus
        local lost_commits=$(git rev-list "$newrev..$oldrev" 2>/dev/null | wc -l)
        if [[ $lost_commits -gt 0 ]]; then
            is_force=true
        fi
        
        if $is_force; then
            log_message "ERROR" "Force push détecté et interdit sur $refname"
            log_message "ERROR" "Commits perdus : $lost_commits"
            send_email "Force push bloqué - $REPO_NAME" "Un force push a été tenté sur $refname et a été bloqué."
            exit 1
        fi
    fi
}

check_branch_protection() {
    local branch="$1"
    
    # Branches protégées
    local protected_branches=("main" "master" "develop" "production" "staging")
    
    for protected in "${protected_branches[@]}"; do
        if [[ "$branch" == "$protected" ]]; then
            log_message "INFO" "Push sur branche protégée: $branch"
            return 0
        fi
    done
    return 1
}

# ============================================================================
# Actions automatiques
# ============================================================================

update_team_notification() {
    local branch="$1"
    local newrev="$2"
    local author=$(git log -1 --format=%an "$newrev" 2>/dev/null || echo "Inconnu")
    local short_hash=$(git log -1 --format=%h "$newrev" 2>/dev/null || echo "${newrev:0:7}")
    local subject=$(git log -1 --format=%s "$newrev" 2>/dev/null || echo "Push effectué")
    
    local message="📦 <b>${REPO_NAME}</b> - ${branch}
👤 ${author}
🔖 ${short_hash}
📝 ${subject}
🔗 ${GIT_URL:-git@localhost:${REPO_NAME}.git}"
    
    # Envoyer aux différentes plateformes
    send_telegram "$message"
    send_discord "$message"
    send_slack "$message"
}

trigger_ci_cd() {
    local branch="$1"
    local newrev="$2"
    
    # Exemple: Déclencher un webhook CI/CD
    if [[ -n "$WEBHOOK_URL" ]]; then
        local payload=$(cat <<EOF
{
    "repository": "$REPO_NAME",
    "branch": "$branch",
    "commit": "$newrev",
    "event": "push",
    "timestamp": "$(date -Iseconds)"
}
EOF
)
        send_webhook "$payload"
    fi
}

# ============================================================================
# Génération de rapport
# ============================================================================

generate_report() {
    local branch="$1"
    local oldrev="$2"
    local newrev="$3"
    local start_time="$4"
    local end_time="$5"
    local duration=$((end_time - start_time))
    
    local report=$(cat <<EOF
=== RAPPORT POST-RECEIVE ===
Dépôt: $REPO_NAME ($REPO_DESC)
Branche: $branch
Ancien commit: ${oldrev:0:7}
Nouveau commit: ${newrev:0:7}
Durée traitement: ${duration}s
Date: $(date)
=============================
EOF
)
    
    log_message "INFO" "Rapport généré"
    echo "$report" >> "$HOOK_LOG"
}

# ============================================================================
# Fonction principale
# ============================================================================

main() {
    local start_time=$(date +%s)
    
    # Création du répertoire de log si nécessaire
    mkdir -p "$LOG_DIR"
    
    # Lire chaque référence poussée
    while read -r oldrev newrev refname; do
        local branch=$(git rev-parse --symbolic --abbrev-ref "$refname" 2>/dev/null || echo "$refname")
        
        log_message "INFO" "═══════════════════════════════════════════════════════════"
        log_message "INFO" "📥 Push reçu sur $REPO_NAME"
        log_message "INFO" "🌿 Branche : $branch"
        log_message "INFO" "🔄 Old: ${oldrev:0:7} → New: ${newrev:0:7}"
        
        # Vérifications de sécurité
        check_force_push "$oldrev" "$newrev" "$refname"
        
        # Analyse des commits
        local commit_analysis=$(analyze_commits "$oldrev" "$newrev")
        log_message "INFO" "$commit_analysis"
        
        # Notifications
        local author=$(git log -1 --format=%an "$newrev" 2>/dev/null || echo "Système")
        local email=$(git log -1 --format=%ae "$newrev" 2>/dev/null || echo "unknown@localhost")
        
        log_message "SUCCESS" "👤 Auteur : $author ($email)"
        log_message "SUCCESS" "🔔 Nouveau push sur la branche : $branch"
        log_message "SUCCESS" "📝 Dernier commit : ${newrev:0:7}"
        
        # Envoi des notifications
        update_team_notification "$branch" "$newrev"
        
        # Déclenchement CI/CD
        trigger_ci_cd "$branch" "$newrev"
        
        # Vérification des branches protégées
        check_branch_protection "$branch"
        
        # Log supplémentaire pour les métriques
        local commit_count=$(git rev-list --count "$oldrev..$newrev" 2>/dev/null || echo 0)
        echo "$(date +%s) | $REPO_NAME | $branch | $author | $commit_count | ${newrev:0:7}" >> "$LOG_DIR/git_metrics.log"
        
    done
    
    local end_time=$(date +%s)
    generate_report "$branch" "$oldrev" "$newrev" "$start_time" "$end_time"
    
    log_message "SUCCESS" "✅ Hook post-receive exécuté avec succès"
    
    # Nettoyage des logs anciens (30 jours)
    find "$LOG_DIR" -name "*.log" -type f -mtime +30 -delete 2>/dev/null || true
}

# ============================================================================
# Exécution
# ============================================================================

# Vérification des prérequis
if [[ ! -d "$LOG_DIR" ]]; then
    mkdir -p "$LOG_DIR"
fi

# Exécution principale
main

exit 0