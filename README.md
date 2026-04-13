# 🎓 Plateforme Git Universitaire

Plateforme de gestion académique des dépôts Git, avec 3 interfaces distinctes selon le rôle.

<<<<<<< HEAD
## 👥 3 Rôles — 3 Interfaces

| Rôle | Accès | Inscription |
|---|---|---|
| **Étudiant** | `/student` | Libre (email + matricule) |
| **Enseignant** | `/teacher` | Code d'invitation requis (fourni par l'admin) |
| **Admin** | `/admin` | Compte unique créé au démarrage |
=======
## 🚀 Fonctionnalités
- Gestion des dépôts par étudiant / groupe
- Interface d'administration pour les enseignants
- Scripts d'automatisation (création de comptes, dépôts, backups)
  - `install.sh` : Configure l'environnement serveur
  - `backup.sh` : Sauvegarde périodique des dépôts
  - `add_students.sh` : Importation massive d'étudiants
  - `create_course_repo.sh` : Création rapide de dépôts de cours
- Documentation complète
>>>>>>> origin/HUGO

## 📁 Structure du projet

```
uni-git-project/
├── backend/
│   ├── server.js              ← Point d'entrée Node.js
│   ├── models/
│   │   └── database.js        ← Base de données en mémoire
│   ├── middleware/
│   │   └── auth.js            ← Vérification JWT + rôles
│   └── routes/
│       ├── auth.js            ← Inscription / Connexion
│       ├── admin.js           ← Routes admin
│       ├── teacher.js         ← Routes enseignant
│       └── student.js         ← Routes étudiant
├── frontend/
│   ├── index.html             ← Page de connexion (accueil)
│   ├── student/index.html     ← Dashboard étudiant
│   ├── teacher/index.html     ← Dashboard enseignant
│   └── admin/index.html       ← Dashboard admin
├── config/                    ← Config Git (hooks, gitconfig)
├── scripts/                   ← Scripts Bash (backup, création dépôts)
├── docs/                      ← Guides utilisateur
├── .env                       ← Variables d'environnement
├── .gitignore
└── package.json
```

<<<<<<< HEAD
## ⚙️ Installation

```bash
# 1. Installer les dépendances
npm install
=======
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
>>>>>>> origin/HUGO

# 2. Démarrer le serveur
npm start

# Ou en mode développement (redémarre automatiquement)
npm run dev
```

<<<<<<< HEAD
## 🌐 Accès
=======
## 👥 Équipe (Groupe 4)
- **Chef de projet** : Coordination et architecture
- **Développeurs Backend** : Scripts Bash et configuration serveur
- **Développeur Frontend** : Interface web et UX
- **Responsable Documentation** : Guides et manuels d'utilisation

## 🤝 Contribution
Les contributions sont les bienvenues !
1. Forkez le projet
2. Créez votre branche (`git checkout -b feature/AmazingFeature`)
3. Committez vos changements (`git commit -m 'Add AmazingFeature'`)
4. Pushez sur la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request
>>>>>>> origin/HUGO

<<<<<<< HEAD
- Accueil / Login : http://localhost:3000
- Interface étudiant : http://localhost:3000/student
- Interface enseignant : http://localhost:3000/teacher
- Interface admin : http://localhost:3000/admin

## 🔑 Compte admin par défaut

```
Email    : admin@univ.cm
Password : admin1234
```

## 🔗 API Endpoints

```
GET  /api/health                      → Vérifier que le serveur tourne
POST /api/auth/login                  → Connexion (tous rôles)
POST /api/auth/register/student       → Inscription étudiant
POST /api/auth/register/teacher       → Inscription enseignant (code requis)

GET  /api/admin/stats                 → Statistiques (admin)
POST /api/admin/invite-code           → Générer un code enseignant (admin)
GET  /api/admin/users                 → Liste tous les utilisateurs (admin)

GET  /api/teacher/courses             → Cours de l'enseignant
POST /api/teacher/courses             → Créer un cours

GET  /api/student/courses             → Cours de l'étudiant
GET  /api/student/all-courses         → Tous les cours disponibles
```
=======
## 📄 Licence
Usage interne universitaire uniquement.
## 🖥️ Interface Frontend
Le frontend est une interface HTML/CSS/JS pure, sans framework.

### Pages disponibles
- `frontend/index.html` — Page d'accueil principale
- `frontend/404.html` — Page d'erreur 404
- `frontend/style.css` — Styles globaux
- `frontend/app.js` — Logique JavaScript

### Fonctionnalités de l'interface
- Navbar sticky avec navigation fluide
- Modal de connexion avec 3 rôles (étudiant, enseignant, admin)
- Compteurs animés en temps réel
- Design responsive (mobile et desktop)
- Toasts de notification interactifs

### Membre 3 — Interface Frontend
Responsable de toute l'interface utilisateur du projet.
>>>>>>> origin/feature/membre3-amelioration-frontend
