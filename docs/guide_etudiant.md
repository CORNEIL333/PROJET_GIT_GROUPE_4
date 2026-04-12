# 📘 Guide Étudiant – Git Universitaire

## 1. Configurer Git sur votre machine
```bash
git config --global user.name "Votre Nom"
git config --global user.email "votre.email@univ.cm"
```

## 2. Cloner votre dépôt de cours
```bash
git clone http://git.univ.cm/cours/INFO101.git
```

## 3. Soumettre un travail
```bash
git add .
git commit -m "TP1 - Algorithmes de tri"
git push origin main
```

## 4. Bonnes pratiques
- Faites des commits réguliers avec des messages clairs
- Ne commitez jamais de mots de passe ou données sensibles
- Créez une branche pour chaque nouvelle fonctionnalité
## 5. Créer une nouvelle branche
```bash
git checkout -b feature/mon-tp
```

## 6. Voir l'historique de ses commits
```bash
git log --oneline
```

## 7. Vérifier l'état de son dépôt
```bash
git status
```

## 8. Mettre à jour son dépôt local
```bash
git pull origin main
```

## 9. En cas de conflit
- Ouvre le fichier en conflit
- Cherche les balises `<<<<<<`, `=======`, `>>>>>>`
- Garde la bonne version et supprime les balises
- Refais `git add .` et `git commit`

## 10. Ressources utiles
- [Documentation Git officielle](https://git-scm.com/doc)
- [GitHub Student Pack](https://education.github.com/pack)
