#!/bin/bash
set -e

# Couleurs pour l'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Ce script doit être exécuté en tant que root (ou via sudo)${NC}" 
   exit 1
fi

LOG_FILE="/var/log/uni-git-install.log"
touch $LOG_FILE
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "${BLUE}🎓 Installation de la plateforme Git Universitaire...${NC}"
echo "📅 Date : $(date)"

if ! command -v git &> /dev/null; then
    echo -e "${BLUE}📦 Installation de Git...${NC}"
    sudo apt update && sudo apt install -y git
fi

if ! id gitserver &>/dev/null; then
    echo -e "${BLUE}👤 Création de l'utilisateur système 'git'...${NC}"
    sudo useradd -m -s /bin/bash git || true
fi

mkdir -p /home/git/repos /home/git/backups /home/git/logs
sudo chown -R git:git /home/git 2>/dev/null || true

echo -e "${GREEN}📂 Structure de dossiers créée :${NC}"
echo "  - /home/git/repos (Dépôts)"
echo "  - /home/git/backups (Sauvegardes)"
echo "  - /home/git/logs (Logs)"

echo -e "${GREEN}✅ Installation terminée !${NC}"
echo "👉 Consultez docs/installation_serveur.md pour la suite."
