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
    [ -d "$repo" ] || continue
    name=$(basename "$repo")
    echo "  📦 Clonage de $name..."
    git clone --mirror "$repo" "$BACKUP_DIR/$DATE/$name"
    tar -czf "$BACKUP_DIR/$DATE/$name.tar.gz" -C "$BACKUP_DIR/$DATE" "$name"
    rm -rf "$BACKUP_DIR/$DATE/$name"
    echo "  ✅ $name sauvegardé"
done
echo "🎉 Sauvegarde terminée dans $BACKUP_DIR/$DATE"
SIZE=$(du -sh "$BACKUP_DIR/$DATE" | cut -f1)
echo "📊 Taille totale : $SIZE"

# Rétention : supprimer les sauvegardes de plus de 7 jours
echo "🧹 Nettoyage des anciennes sauvegardes (7j+)..."
find "$BACKUP_DIR" -type d -mtime +7 -exec rm -rf {} +
echo "✅ Nettoyage terminé."

# Ajouter au cron s'il n'y est pas déjà
SCRIPT_PATH=$(realpath "$0" 2>/dev/null || echo "$0")
if ! crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
    echo "⏰ Ajout de la tâche cron pour une exécution journalière à 2h du matin..."
    (crontab -l 2>/dev/null; echo "0 2 * * * /bin/bash $SCRIPT_PATH") | crontab -
fi
