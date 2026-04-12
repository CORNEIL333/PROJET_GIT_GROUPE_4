#!/bin/bash
set -euo pipefail

LOG_DIR="/home/git/logs"
HOOK_LOG="$LOG_DIR/post-receive.log"
mkdir -p "$LOG_DIR"

REPO_NAME=$(basename "$(pwd)" .git)
REPO_DESC=$(cat description 2>/dev/null || echo "Dépôt Git")

ENABLE_EMAIL=true
ENABLE_TELEGRAM=false
ENABLE_DISCORD=false
ADMIN_EMAIL="admin@universite.fr"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"
DISCORD_WEBHOOK="${DISCORD_WEBHOOK:-}"

MAX_COMMIT_SIZE=10485760
ALLOW_FORCE_PUSH=false

log() {
    local level="$1"
    local msg="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg" >> "$HOOK_LOG"
    case "$level" in
        ERROR)   echo -e "\033[0;31m❌ $msg\033[0m" >&2 ;;
        WARNING) echo -e "\033[1;33m⚠️  $msg\033[0m" >&2 ;;
        SUCCESS) echo -e "\033[0;32m✅ $msg\033[0m" ;;
        INFO)    echo -e "\033[0;34mℹ️  $msg\033[0m" ;;
    esac
}

send_telegram() {
    $ENABLE_TELEGRAM || return 0
    [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]] && return 0
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" -d "text=$1" -d "parse_mode=HTML" &>/dev/null
}

send_discord() {
    $ENABLE_DISCORD || return 0
    [[ -z "$DISCORD_WEBHOOK" ]] && return 0
    curl -s -X POST -H "Content-Type: application/json" \
        -d "{\"content\":\"$1\"}" "$DISCORD_WEBHOOK" &>/dev/null
}

send_email() {
    $ENABLE_EMAIL || return 0
    command -v mail &>/dev/null && echo "$2" | mail -s "[Git] $1" "$ADMIN_EMAIL"
}

check_force_push() {
    $ALLOW_FORCE_PUSH && return 0
    local lost=$(git rev-list "$2..$1" 2>/dev/null | wc -l)
    if [[ $lost -gt 0 ]]; then
        log ERROR "Force push interdit sur $3 - $lost commits perdus"
        send_email "Force push bloqué - $REPO_NAME" "Tentative sur $3"
        exit 1
    fi
}

notify_team() {
    local branch="$1" rev="$2"
    local author=$(git log -1 --format=%an "$rev" 2>/dev/null || echo "Inconnu")
    local hash=$(git log -1 --format=%h "$rev" 2>/dev/null || echo "${rev:0:7}")
    local subject=$(git log -1 --format=%s "$rev" 2>/dev/null || echo "Push effectué")
    
    local msg="📦 <b>$REPO_NAME</b> - $branch\n👤 $author\n🔖 $hash\n📝 $subject"
    send_telegram "$msg"
    send_discord "$msg"
}

main() {
    while read -r oldrev newrev refname; do
        branch=$(git rev-parse --symbolic --abbrev-ref "$refname" 2>/dev/null || echo "$refname")
        
        log INFO "════════════════════════════════════════"
        log INFO "📥 Push sur $REPO_NAME - Branche: $branch"
        log INFO "🔄 ${oldrev:0:7} → ${newrev:0:7}"
        
        check_force_push "$oldrev" "$newrev" "$refname"
        
        if [[ "$oldrev" != "0000000000000000000000000000000000000000" && "$newrev" != "0000000000000000000000000000000000000000" ]]; then
            local count=$(git rev-list --count "$oldrev..$newrev" 2>/dev/null || echo 0)
            log INFO "📊 $count nouveau(x) commit(s)"
        fi
        
        local author=$(git log -1 --format=%an "$newrev" 2>/dev/null || echo "Système")
        log SUCCESS "👤 $author - Dernier commit: ${newrev:0:7}"
        
        notify_team "$branch" "$newrev"
        
        echo "$(date +%s) | $REPO_NAME | $branch | $author | ${newrev:0:7}" >> "$LOG_DIR/git_metrics.log"
    done
    
    log SUCCESS "✅ Hook post-receive exécuté"
    find "$LOG_DIR" -name "*.log" -mtime +30 -delete 2>/dev/null || true
}

main
exit 0