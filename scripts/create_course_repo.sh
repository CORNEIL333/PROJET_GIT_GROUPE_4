#!/bin/bash
# Usage: bash create_course_repo.sh CODE_COURS "Nom du Cours" [BRANCHE]
COURSE_CODE=$1
COURSE_NAME=$2
DEFAULT_BRANCH=${3:-main}
REPO_DIR="/home/git/repos"

if [ -z "$COURSE_CODE" ] || [ -z "$COURSE_NAME" ]; then
    echo "❌ Usage: $0 CODE_COURS 'Nom du Cours' [BRANCHE]"
    exit 1
fi

REPO_PATH="$REPO_DIR/$COURSE_CODE.git"

if [ -d "$REPO_PATH" ]; then
    echo "❌ Erreur : Le dépôt $COURSE_CODE existe déjà."
    exit 1
fi

echo "📁 Création du dépôt : $COURSE_NAME ($COURSE_CODE)"
sudo -u git git init --bare --initial-branch="$DEFAULT_BRANCH" "$REPO_PATH"
echo "$COURSE_NAME" | sudo tee "$REPO_PATH/description" > /dev/null

# Installation du hook par défaut
HOOK_SRC="config/hooks_post-receive.sh"
if [ -f "$HOOK_SRC" ]; then
    sudo cp "$HOOK_SRC" "$REPO_PATH/hooks/post-receive"
    sudo chmod +x "$REPO_PATH/hooks/post-receive"
    echo "  ⚓ Hook post-receive installé."
fi

echo "✅ Dépôt créé : $REPO_PATH"
echo "👉 Cloner avec : git clone git@serveur:$COURSE_CODE.git"
