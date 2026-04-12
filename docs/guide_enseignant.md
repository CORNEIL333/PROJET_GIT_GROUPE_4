 # 📗 Guide Enseignant – Git Universitaire

## Créer un dépôt de cours
```bash
bash scripts/create_course_repo.sh INFO101 "Algorithmique"
```

## Ajouter des étudiants à un cours
```bash
bash scripts/add_students.sh INFO101 liste_etudiants.txt
```

## Consulter les soumissions
```bash
git log --author="NomEtudiant" --oneline
```

## Créer une correction de TP
```bash
git checkout -b correction-tp1
git push origin correction-tp1