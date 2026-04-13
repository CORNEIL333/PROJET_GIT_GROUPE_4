#!/bin/bash
# Usage: bash add_students.sh CODE_COURS liste_etudiants.txt [--dry-run]
COURSE_CODE=$1
STUDENT_FILE=$2
DRY_RUN=false
[ "$3" == "--dry-run" ] && DRY_RUN=true

if [ -z "$COURSE_CODE" ] || [ ! -f "$STUDENT_FILE" ]; then
    echo "❌ Usage: $0 CODE_COURS liste_etudiants.txt [--dry-run]"
    exit 1
fi

if [ ! -s "$STUDENT_FILE" ]; then
    echo "⚠️ Le fichier $STUDENT_FILE est vide."
    exit 0
fi

if [[ ! "$COURSE_CODE" =~ ^[A-Z0-9]+$ ]]; then
    echo "❌ Erreur : Le code cours doit être alphanumérique (ex: L3INFO)."
    exit 1
fi

if $DRY_RUN; then echo "🧪 MODE SIMULATION (aucune modification réelle)"; fi

COUNT=0
echo "👥 Ajout des étudiants au cours $COURSE_CODE..."
while IFS= read -r student; do
    # Nettoyer les espaces et sauts de ligne
    student=$(echo "$student" | tr -d '\r')
    [ -z "$student" ] && continue
    ((COUNT++))
    if $DRY_RUN; then
        echo "  [$COUNT] [SIMUL] ➕ $student"
    else
        echo "  [$COUNT] ➕ $student"
        # Ajout réel (Simulation de gestion des droits système / htpasswd)
        sudo -u git mkdir -p "/home/git/repos/$COURSE_CODE.git" 2>/dev/null || mkdir -p "/home/git/repos/$COURSE_CODE.git" 2>/dev/null
        echo "$student" >> "/home/git/repos/$COURSE_CODE.git/authorized_students.txt" 2>/dev/null || true
    fi
done < "$STUDENT_FILE"
echo "✅ $COUNT étudiants traités et inscrits au cours $COURSE_CODE."
