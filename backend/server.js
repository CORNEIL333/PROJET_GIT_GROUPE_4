<<<<<<< HEAD
// backend/server.js
// Point d'entrée principal du serveur Node.js

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const { initDB } = require('./models/database');
=======
const express = require('express');
const cors = require('cors');
const { exec } = require('child_process');
const path = require('path');
>>>>>>> origin/INESS

const app = express();
const PORT = process.env.PORT || 3000;

<<<<<<< HEAD
// ─── MIDDLEWARES ──────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Servir les fichiers statiques (les pages HTML)
app.use(express.static(path.join(__dirname, '../frontend')));

// ─── ROUTES API ───────────────────────────────────────────────────────────────
app.use('/api/auth', require('./routes/auth'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/teacher', require('./routes/teacher'));
app.use('/api/student', require('./routes/student'));

// ─── ROUTE DE SANTÉ (pour vérifier que le serveur tourne) ────────────────────
app.get('/api/health', (req, res) => {
  res.json({
    status: '✅ Serveur opérationnel',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// ─── PAGES HTML PAR RÔLE ─────────────────────────────────────────────────────
app.get('/student', (req, res) => {
  res.sendFile(path.join(__dirname, '../frontend/student/index.html'));
});

app.get('/teacher', (req, res) => {
  res.sendFile(path.join(__dirname, '../frontend/teacher/index.html'));
});

app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, '../frontend/admin/index.html'));
});

// Page d'accueil (login)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../frontend/index.html'));
});

// ─── DÉMARRAGE ────────────────────────────────────────────────────────────────
initDB().then(() => {
  app.listen(PORT, () => {
    console.log(`\n🚀 Serveur démarré sur http://localhost:${PORT}`);
    console.log(`📋 Routes disponibles :`);
    console.log(`   GET  http://localhost:${PORT}/api/health`);
    console.log(`   POST http://localhost:${PORT}/api/auth/login`);
    console.log(`   POST http://localhost:${PORT}/api/auth/register/student`);
    console.log(`   POST http://localhost:${PORT}/api/auth/register/teacher`);
    console.log(`   GET  http://localhost:${PORT}/api/admin/stats`);
    console.log(`\n👤 Compte admin par défaut :`);
    console.log(`   Email    : admin@univ.cm`);
    console.log(`   Password : admin1234\n`);
  });
=======
app.use(cors());
app.use(express.json());

// Servir statiquement le dossier frontend
app.use(express.static(path.join(__dirname, '../frontend')));

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', message: 'GitUniversitaire API is operational' });
});

// Route mock pour lister l'activité / dépôts (remplace les hardcodes de la page HTML)
app.get('/api/repos', (req, res) => {
    res.json([
        { id: 1, name: 'groupe-L3-info/projet-S8', status: '✅ 3 commits · fusion interface il y a 2h', icon: 'git-alt', color: '#d35400' },
        { id: 2, name: 'crypto-M1/TP2-RSA', status: '📚 Enseignant a ajouté des ressources · 12 étoiles ⭐', icon: 'chalkboard', color: '#16a085' },
        { id: 3, name: 'club-robotique/ros2_ws', status: '🤖 5 contributeurs actifs · dernier push: "fix lidar"', icon: 'users', color: '#2980b9' }
    ]);
});

// Route simulée ou réelle pour déclencher les scripts Bash
app.post('/api/run-backup', (req, res) => {
    const scriptPath = path.join(__dirname, '../scripts/backup.sh');
    // Pour une vraie exécution, utiliser sudo si nécessaire
    exec(`bash "${scriptPath}"`, (error, stdout, stderr) => {
        if (error) {
            console.error(error);
            return res.status(500).json({ error: 'Erreur lors de la sauvegarde.', logs: stderr });
        }
        res.json({ message: 'Sauvegarde effectuée avec succès!', logs: stdout });
    });
});

app.listen(PORT, () => {
    console.log(`🚀 Serveur Git Universitaire en ligne: http://localhost:${PORT}`);
>>>>>>> origin/INESS
});
