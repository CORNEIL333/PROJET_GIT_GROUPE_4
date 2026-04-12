# 🎓 Plateforme Git Universitaire

Plateforme de gestion académique des dépôts Git, avec 3 interfaces distinctes selon le rôle.

## 👥 3 Rôles — 3 Interfaces

| Rôle | Accès | Inscription |
|---|---|---|
| **Étudiant** | `/student` | Libre (email + matricule) |
| **Enseignant** | `/teacher` | Code d'invitation requis (fourni par l'admin) |
| **Admin** | `/admin` | Compte unique créé au démarrage |

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

## ⚙️ Installation

```bash
# 1. Installer les dépendances
npm install

# 2. Démarrer le serveur
npm start

# Ou en mode développement (redémarre automatiquement)
npm run dev
```

## 🌐 Accès

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
