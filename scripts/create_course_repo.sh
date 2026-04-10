#!/bin/bash
# Usage: bash create_course_repo.sh CODE_COURS "Nom du Cours"
COURSE_CODE=$1
COURSE_NAME=$2
REPO_DIR="/home/git/repos"

if [ -z "$COURSE_CODE" ] || [ -z "$COURSE_NAME" ]; then
    echo "❌ Usage: $0 CODE_COURS 'Nom du Cours'"
    exit 1
fi

REPO_PATH="$REPO_DIR/$COURSE_CODE.git"
echo "📁 Création du dépôt : $COURSE_NAME ($COURSE_CODE)"
sudo -u git git init --bare "$REPO_PATH"
echo "$COURSE_NAME" | sudo tee "$REPO_PATH/description" > /dev/null
echo "✅ Dépôt créé : $REPO_PATH"
echo "👉 Cloner avec : git clone git@serveur:$COURSE_CODE.git"
