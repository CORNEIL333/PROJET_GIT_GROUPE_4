#!/bin/bash
# ============================================================================
# Script: backup_git_repos.sh
# Description: Sauvegarde complète des dépôts Git avec rotation et monitoring
# Author: GitUniversitaire
# Version: 2.0
# ============================================================================

set -euo pipefail  # Arrêt immédiat en cas d'erreur

# ============================================================================
# Configuration
# ============================================================================

# Répertoires (avec valeurs par défaut)
REPOS_DIR="${REPOS_DIR:-/home/git/repos}"
BACKUP_DIR="${BACKUP_DIR:-/home/git/backups}"
LOG_DIR="${LOG_DIR:-/home/git/logs}"

# Configuration de rétention (jours)
RETENTION_DAYS="${RETENTION_DAYS:-7}"
MAX_BACKUP_SIZE_GB="${MAX_BACKUP_SIZE_GB:-50}"  # Limite de taille en GB

# Options
COMPRESS=true
COMPRESSION_LEVEL=6  # 1=rapide, 9=maximum
PARALLEL_JOBS=4      # Nombre de clones parallèles
VERBOSE=false
SEND_ALERTS=false
ALERT_EMAIL="${ALERT_EMAIL:-admin@example.com}"

# Fichiers
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_PATH="$BACKUP_DIR/$DATE"
LOCK_FILE="/tmp/git_backup.lock"
STATUS_FILE="$BACKUP_DIR/backup_status.json"

# ============================================================================
# Couleurs et fonctions utilitaires
# ============================================================================

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $(date '+%H:%M:%S') - $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $(date '+%H:%M:%S') - $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $(date '+%H:%M:%S') - $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%H:%M:%S') - $1" >&2; }

send_alert() {
    local subject="$1"
    local message="$2"
    if $SEND_ALERTS && command -v mail &> /dev/null; then
        echo "$message" | mail -s "[Git Backup] $subject" "$ALERT_EMAIL"
    fi
}

cleanup() {
    log_info "Nettoyage des ressources temporaires..."
    rm -f "$LOCK_FILE"
    if [[ -n "${TEMP_DIR:-}" ]] && [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT INT TERM

# ============================================================================
# Vérifications préalables
# ============================================================================

# Vérifier si le script est déjà en cours d'exécution
if [[ -f "$LOCK_FILE" ]]; then
    pid=$(cat "$LOCK_FILE")
    if kill -0 "$pid" 2>/dev/null; then
        log_error "Le script est déjà en cours d'exécution (PID: $pid)"
        exit 1
    else
        log_warning "Fichier lock obsolète trouvé, suppression..."
        rm -f "$LOCK_FILE"
    fi
fi
echo $$ > "$LOCK_FILE"

# Création des répertoires
mkdir -p "$LOG_DIR" "$BACKUP_DIR" || {
    log_error "Impossible de créer les répertoires nécessaires"
    exit 1
}

# Configuration des logs
LOG_FILE="$LOG_DIR/backup_${DATE}.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Vérification des répertoires sources
if [[ ! -d "$REPOS_DIR" ]]; then
    log_error "Répertoire des dépôts introuvable : $REPOS_DIR"
    send_alert "ERREUR: Répertoire source introuvable" "$REPOS_DIR n'existe pas"
    exit 1
fi

# Vérification de l'espace disque
check_disk_space() {
    local available_gb=$(df --output=avail "$BACKUP_DIR" | tail -1 | awk '{print int($1/1024/1024)}')
    local required_gb=$(find "$REPOS_DIR" -name "*.git" -type d -exec du -sb {} + 2>/dev/null | awk '{sum+=$1} END {print int(sum/1024/1024/1024)}')
    
    if [[ $available_gb -lt $required_gb ]]; then
        log_error "Espace disque insuffisant! Disponible: ${available_gb}GB, Requis: ${required_gb}GB"
        send_alert "ERREUR: Espace disque insuffisant" "Backup impossible"
        return 1
    fi
    log_info "Espace disque OK (${available_gb}GB disponibles)"
    return 0
}

# ============================================================================
# Fonction de sauvegarde d'un dépôt
# ============================================================================

backup_repo() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path" .git)
    local temp_dir="$BACKUP_PATH/temp/$repo_name"
    local backup_file="$BACKUP_PATH/$repo_name.tar.gz"
    
    log_info "📦 Traitement de: $repo_name"
    
    # Mesure du temps
    local start_time=$(date +%s)
    
    # Clone mirror
    if $COMPRESS; then
        if git clone --mirror --quiet "$repo_path" "$temp_dir" 2>/dev/null; then
            # Compression
            tar -czf "$backup_file" -C "$BACKUP_PATH/temp" "$repo_name" 2>/dev/null
            local size=$(du -h "$backup_file" | cut -f1)
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            
            log_success "✅ $repo_name sauvegardé (${size}, ${duration}s)"
            
            # Nettoyage
            rm -rf "$temp_dir"
        else
            log_error "❌ Échec du clonage: $repo_name"
            return 1
        fi
    else
        # Backup sans compression
        cp -r "$repo_path" "$backup_file"
        log_success "✅ $repo_name sauvegardé (non compressé)"
    fi
    
    return 0
}

# ============================================================================
# Sauvegarde avec parallélisation
# ============================================================================

backup_repos_parallel() {
    local repos=("$@")
    local total=${#repos[@]}
    local success=0
    local failed=0
    
    log_info "Démarrage de la sauvegarde parallèle (${PARALLEL_JOBS} jobs max)..."
    
    # Utilisation de xargs pour le parallélisme
    printf "%s\n" "${repos[@]}" | xargs -P "$PARALLEL_JOBS" -I {} bash -c '
        source <(declare -f backup_repo log_info log_success log_error)
        backup_repo "{}"
    '
    
    # Comptage (simplifié, peut être amélioré)
    for repo in "${repos[@]}"; do
        local repo_name=$(basename "$repo" .git)
        if [[ -f "$BACKUP_PATH/$repo_name.tar.gz" ]]; then
            ((success++))
        else
            ((failed++))
        fi
    done
    
    echo "$success $failed"
}

# ============================================================================
# Génération du rapport JSON
# ============================================================================

generate_json_report() {
    local success=$1
    local failed=$2
    local total_size=$3
    
    cat > "$STATUS_FILE" << EOF
{
    "backup_date": "$DATE",
    "status": "$([ $failed -eq 0 ] && echo "success" || echo "partial")",
    "repositories": {
        "total": $((success + failed)),
        "success": $success,
        "failed": $failed
    },
    "size_bytes": $total_size,
    "size_human": "$(numfmt --to=iec $total_size)",
    "backup_path": "$BACKUP_PATH",
    "retention_days": $RETENTION_DAYS,
    "timestamp": "$(date -Iseconds)"
}
EOF
}

# ============================================================================
# Nettoyage des anciennes sauvegardes
# ============================================================================

cleanup_old_backups() {
    log_info "🧹 Nettoyage des sauvegardes de plus de ${RETENTION_DAYS} jours..."
    
    local old_backups=$(find "$BACKUP_DIR" -maxdepth 1 -type d -name "20*" -mtime +$RETENTION_DAYS 2>/dev/null)
    local count=0
    
    if [[ -n "$old_backups" ]]; then
        while IFS= read -r backup; do
            if [[ -d "$backup" ]]; then
                local size=$(du -sh "$backup" | cut -f1)
                rm -rf "$backup"
                log_info "   Supprimé: $(basename "$backup") (${size})"
                ((count++))
            fi
        done <<< "$old_backups"
        
        log_success "Nettoyage terminé: $count sauvegarde(s) supprimée(s)"
    else
        log_info "Aucune ancienne sauvegarde à supprimer"
    fi
    
    # Vérification de la taille totale des backups
    local total_backup_size=$(du -sb "$BACKUP_DIR" | cut -f1)
    local total_backup_size_gb=$((total_backup_size / 1024 / 1024 / 1024))
    
    if [[ $total_backup_size_gb -gt $MAX_BACKUP_SIZE_GB ]]; then
        log_warning "Taille totale des backups (${total_backup_size_gb}GB) dépasse la limite (${MAX_BACKUP_SIZE_GB}GB)"
        send_alert "Alerte: Taille des backups excessive" "Total: ${total_backup_size_gb}GB"
    fi
}

# ============================================================================
# Fonction principale
# ============================================================================

main() {
    echo "================================================================================"
    echo "💾 SAUVEGARDE GIT - $DATE"
    echo "================================================================================"
    
    # Vérification de l'espace
    check_disk_space || exit 1
    
    # Collecte des dépôts
    mapfile -t repos < <(find "$REPOS_DIR" -maxdepth 1 -name "*.git" -type d 2>/dev/null | sort)
    
    if [[ ${#repos[@]} -eq 0 ]]; then
        log_warning "Aucun dépôt Git trouvé dans $REPOS_DIR"
        exit 0
    fi
    
    log_info "Dépôts trouvés: ${#repos[@]}"
    
    # Création des répertoires de backup
    mkdir -p "$BACKUP_PATH/temp"
    
    # Sauvegarde
    local start_total=$(date +%s)
    
    if [[ $PARALLEL_JOBS -gt 1 ]] && command -v xargs &> /dev/null; then
        # Backup parallèle
        local result=($(backup_repos_parallel "${repos[@]}"))
        local success=${result[0]}
        local failed=${result[1]}
    else
        # Backup séquentiel
        local success=0
        local failed=0
        for repo in "${repos[@]}"; do
            if backup_repo "$repo"; then
                ((success++))
            else
                ((failed++))
            fi
        done
    fi
    
    local end_total=$(date +%s)
    local duration_total=$((end_total - start_total))
    
    # Nettoyage du répertoire temporaire
    rm -rf "$BACKUP_PATH/temp"
    
    # Calcul de la taille totale
    local total_size=$(du -sb "$BACKUP_PATH" | cut -f1)
    local total_size_human=$(numfmt --to=iec $total_size 2>/dev/null || echo "${total_size} bytes")
    
    # Génération du rapport
    generate_json_report "$success" "$failed" "$total_size"
    
    # Nettoyage anciennes sauvegardes
    cleanup_old_backups
    
    # Rapport final
    echo "================================================================================"
    if [[ $failed -eq 0 ]]; then
        log_success "🎉 Sauvegarde complète terminée avec succès!"
    else
        log_warning "⚠️ Sauvegarde partielle: $failed dépôt(s) en échec"
        send_alert "Backup partiel" "$failed dépôts échoués sur ${#repos[@]}"
    fi
    echo "📁 Emplacement: $BACKUP_PATH"
    echo "📊 Taille totale: $total_size_human"
    echo "⏱️  Durée totale: ${duration_total}s"
    echo "✅ Taux de succès: $((success * 100 / ${#repos[@]}))%"
    echo "📝 Log: $LOG_FILE"
    echo "================================================================================"
    
    # Envoi d'alerte si échec
    if [[ $failed -gt 0 ]]; then
        send_alert "ERREURS détectées lors du backup" "Consultez $LOG_FILE"
        exit 1
    fi
    
    exit 0
}

# ============================================================================
# Exécution
# ============================================================================

main "$@"