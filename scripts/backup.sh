#!/bin/bash
REPOS_DIR="/home/git/repos"
BACKUP_DIR="/home/git/backups"
DATE=$(date +%Y-%m-%d_%H-%M)

echo "💾 Sauvegarde en cours ($DATE)..."
mkdir -p "$BACKUP_DIR/$DATE"

for repo in "$REPOS_DIR"/*.git; do
    name=$(basename "$repo")
    git clone --mirror "$repo" "$BACKUP_DIR/$DATE/$name"
    echo "  ✅ $name"
done
echo "🎉 Sauvegarde terminée dans $BACKUP_DIR/$DATE"
