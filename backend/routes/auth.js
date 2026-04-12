// backend/routes/auth.js
// Routes : inscription / connexion pour chaque rôle

const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const {
  findUserByEmail,
  createUser,
  findInviteCode,
  markCodeAsUsed,
} = require('../models/database');

// ─── Générer un token JWT ─────────────────────────────────────────────────────
function generateToken(user) {
  return jwt.sign(
    { id: user.id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN }
  );
}

// ─── POST /api/auth/register/student ─────────────────────────────────────────
// Un étudiant peut s'inscrire librement
router.post('/register/student', async (req, res) => {
  try {
    const { name, email, password, studentId } = req.body;

    if (!name || !email || !password || !studentId) {
      return res.status(400).json({ error: 'Tous les champs sont requis (nom, email, mot de passe, matricule).' });
    }

    if (findUserByEmail(email)) {
      return res.status(409).json({ error: 'Cet email est déjà utilisé.' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = createUser({
      name,
      email,
      password: hashedPassword,
      studentId,
      role: 'student',
    });

    const token = generateToken(user);
    res.status(201).json({
      message: '✅ Compte étudiant créé avec succès.',
      token,
      user: { id: user.id, name: user.name, email: user.email, role: user.role, studentId },
    });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur.' });
  }
});

// ─── POST /api/auth/register/teacher ─────────────────────────────────────────
// Un enseignant doit fournir un code d'invitation généré par l'admin
router.post('/register/teacher', async (req, res) => {
  try {
    const { name, email, password, inviteCode } = req.body;

    if (!name || !email || !password || !inviteCode) {
      return res.status(400).json({ error: 'Tous les champs sont requis (nom, email, mot de passe, code invitation).' });
    }

    const invite = findInviteCode(inviteCode);
    if (!invite) {
      return res.status(403).json({ error: 'Code d\'invitation invalide ou déjà utilisé.' });
    }

    if (findUserByEmail(email)) {
      return res.status(409).json({ error: 'Cet email est déjà utilisé.' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = createUser({
      name,
      email,
      password: hashedPassword,
      role: 'teacher',
    });

    markCodeAsUsed(inviteCode, user.id);

    const token = generateToken(user);
    res.status(201).json({
      message: '✅ Compte enseignant créé avec succès.',
      token,
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
    });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur.' });
  }
});

// ─── POST /api/auth/login ─────────────────────────────────────────────────────
// Connexion universelle — le rôle est détecté automatiquement
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email et mot de passe requis.' });
    }

    const user = findUserByEmail(email);
    if (!user) {
      return res.status(401).json({ error: 'Email ou mot de passe incorrect.' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Email ou mot de passe incorrect.' });
    }

    const token = generateToken(user);
    const { password: _, ...safeUser } = user;

    res.json({
      message: `✅ Bienvenue, ${user.name} !`,
      token,
      user: safeUser,
    });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur.' });
  }
});

module.exports = router;
