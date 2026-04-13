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
<<<<<<< HEAD
git push origin correction-tp1
=======
git push origin correction-tp1
```
## 5. Créer un dépôt de cours
```bash
bash scripts/create_course_repo.sh INFO301 "Réseaux Informatiques"
```

## 6. Voir les soumissions des étudiants
Connectez-vous à l'interface web et accédez à **Dashboard → Soumissions**.

## 7. Exporter les notes
Allez dans **Dashboard → Exporter** pour télécharger un fichier CSV des notes.

## 8. Bonnes pratiques pour les enseignants
- Créez un dépôt par cours et par semestre
- Donnez des instructions claires dans le README du dépôt cours
- Utilisez les Issues GitHub pour les questions/réponses
- Protégez la branche main pour éviter les modifications accidentelles
>>>>>>> origin/feature/membre3-amelioration-frontend
