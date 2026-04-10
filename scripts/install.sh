#!/bin/bash
set -e
echo "🎓 Installation de la plateforme Git Universitaire..."

if ! command -v git &> /dev/null; then
    echo "📦 Installation de Git..."
    sudo apt update && sudo apt install -y git
fi

mkdir -p /home/git/repos /home/git/backups /home/git/logs
echo "✅ Installation terminée !"
echo "👉 Consultez docs/installation_serveur.md pour la suite."
