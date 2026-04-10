// backend/server.js
// Point d'entrée principal du serveur Node.js

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const { initDB } = require('./models/database');

const app = express();
const PORT = process.env.PORT || 3000;

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
});
