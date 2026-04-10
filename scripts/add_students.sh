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

if [[ ! "$COURSE_CODE" =~ ^[A-Z0-9]+$ ]]; then
    echo "❌ Erreur : Le code cours doit être alphanumérique (ex: L3INFO)."
    exit 1
fi

if $DRY_RUN; then echo "🧪 MODE SIMULATION (aucune modification réelle)"; fi

COUNT=0
echo "👥 Ajout des étudiants au cours $COURSE_CODE..."
while IFS= read -r student; do
    [ -z "$student" ] && continue
    ((COUNT++))
    if $DRY_RUN; then
        echo "  [$COUNT] [SIMUL] ➕ $student"
    else
        echo "  [$COUNT] ➕ $student"
    fi
done < "$STUDENT_FILE"
echo "✅ $COUNT étudiants traités."
