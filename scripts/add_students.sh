#!/bin/bash
# Usage: bash add_students.sh CODE_COURS liste_etudiants.txt
COURSE_CODE=$1
STUDENT_FILE=$2

if [ -z "$COURSE_CODE" ] || [ ! -f "$STUDENT_FILE" ]; then
    echo "❌ Usage: $0 CODE_COURS liste_etudiants.txt"
    exit 1
fi

echo "👥 Ajout des étudiants au cours $COURSE_CODE..."
while IFS= read -r student; do
    [ -z "$student" ] && continue
    echo "  ➕ $student"
done < "$STUDENT_FILE"
echo "✅ Étudiants ajoutés."
