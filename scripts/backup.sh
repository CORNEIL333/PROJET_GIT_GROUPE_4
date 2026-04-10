#!/bin/bash
REPOS_DIR="/home/git/repos"
BACKUP_DIR="/home/git/backups"
LOG_DIR="/home/git/logs"
DATE=$(date +%Y-%m-%d_%H-%M)
LOG_FILE="$LOG_DIR/backup_$DATE.log"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "💾 Sauvegarde en cours ($DATE)..."
mkdir -p "$BACKUP_DIR/$DATE"

for repo in "$REPOS_DIR"/*.git; do
    name=$(basename "$repo")
    git clone --mirror "$repo" "$BACKUP_DIR/$DATE/$name"
    echo "  ✅ $name"
done
echo "🎉 Sauvegarde terminée dans $BACKUP_DIR/$DATE"
