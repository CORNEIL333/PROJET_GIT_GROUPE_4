# 🎓 Plateforme Git Universitaire

Bienvenue sur le dépôt central de la plateforme Git de notre université.  
Ce projet permet aux étudiants et enseignants de gérer leurs projets académiques avec Git.

## 🚀 Fonctionnalités
- Gestion des dépôts par étudiant / groupe
- Interface d'administration pour les enseignants
- Scripts d'automatisation (création de comptes, dépôts, backups)
  - `install.sh` : Configure l'environnement serveur
  - `backup.sh` : Sauvegarde périodique des dépôts
  - `add_students.sh` : Importation massive d'étudiants
  - `create_course_repo.sh` : Création rapide de dépôts de cours
- Documentation complète

## 📁 Structure du projet
```
uni-git-project/
├── README.md
├── docs/           → Documentation
├── scripts/        → Scripts d'automatisation (Bash / Python)
├── config/         → Fichiers de configuration
└── frontend/       → Interface web simple (HTML/CSS/JS)
```

## 📋 Prérequis
Avant de commencer, assurez-vous d'avoir :
- Un serveur Linux (Ubuntu 22.04+ recommandé)
- Accès `sudo` ou utilisateur `root`
- Git installé (si absent, le script d'installation le fera)
- Bash 4.0+

## ⚙️ Installation rapide
```bash
# Cloner le projet
git clone https://github.com/CORNEIL333/PROJET_GIT_GROUPE_4.git
cd PROJET_GIT_GROUPE_4

# Lancer le script d'installation
bash scripts/install.sh
```

## 👥 Équipe
- Administrateurs : gérer les utilisateurs et les dépôts
- Enseignants : créer des dépôts de cours, corriger les travaux
- Étudiants : soumettre leurs projets via Git

## 🤝 Contribution
Les contributions sont les bienvenues !
1. Forkez le projet
2. Créez votre branche (`git checkout -b feature/AmazingFeature`)
3. Committez vos changements (`git commit -m 'Add AmazingFeature'`)
4. Pushez sur la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

## 📄 Licence
Usage interne universitaire uniquement.
