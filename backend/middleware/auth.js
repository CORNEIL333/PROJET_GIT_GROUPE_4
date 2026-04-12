// backend/middleware/auth.js
// Vérifie que l'utilisateur est bien connecté et a le bon rôle

const jwt = require('jsonwebtoken');
const { findUserById } = require('../models/database');

// Vérifie le token JWT
function authenticate(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // "Bearer TOKEN"

  if (!token) {
    return res.status(401).json({ error: 'Accès refusé. Connexion requise.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = findUserById(decoded.id);
    if (!user) return res.status(401).json({ error: 'Utilisateur introuvable.' });
    req.user = user;
    next();
  } catch (err) {
    return res.status(403).json({ error: 'Token invalide ou expiré.' });
  }
}

// Vérifie le rôle (ex: authorizeRole('admin') ou authorizeRole('admin', 'teacher'))
function authorizeRole(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        error: `Accès refusé. Rôle requis : ${roles.join(' ou ')}.`,
      });
    }
    next();
  };
}

module.exports = { authenticate, authorizeRole };
