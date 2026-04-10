// backend/routes/admin.js
// Routes accessibles uniquement par l'administrateur

const express = require('express');
const router = express.Router();
const { authenticate, authorizeRole } = require('../middleware/auth');
const {
  getAllUsers,
  getUsersByRole,
  createInviteCode,
  getAllInviteCodes,
  getAllCourses,
} = require('../models/database');

// Toutes les routes admin nécessitent d'être connecté ET d'être admin
router.use(authenticate, authorizeRole('admin'));

// GET /api/admin/users — Liste tous les utilisateurs
router.get('/users', (req, res) => {
  res.json({ users: getAllUsers() });
});

// GET /api/admin/teachers — Liste tous les enseignants
router.get('/teachers', (req, res) => {
  res.json({ teachers: getUsersByRole('teacher') });
});

// GET /api/admin/students — Liste tous les étudiants
router.get('/students', (req, res) => {
  res.json({ students: getUsersByRole('student') });
});

// POST /api/admin/invite-code — Génère un code d'invitation pour un enseignant
router.post('/invite-code', (req, res) => {
  const invite = createInviteCode(req.user.id);
  res.status(201).json({
    message: '✅ Code d\'invitation généré.',
    inviteCode: invite.code,
    expiresNote: 'Ce code est à usage unique. Transmettez-le à l\'enseignant.',
  });
});

// GET /api/admin/invite-codes — Liste tous les codes générés
router.get('/invite-codes', (req, res) => {
  res.json({ codes: getAllInviteCodes() });
});

// GET /api/admin/courses — Liste tous les cours
router.get('/courses', (req, res) => {
  res.json({ courses: getAllCourses() });
});

// GET /api/admin/stats — Statistiques globales
router.get('/stats', (req, res) => {
  const users = getAllUsers();
  res.json({
    stats: {
      totalUsers: users.length,
      students: users.filter(u => u.role === 'student').length,
      teachers: users.filter(u => u.role === 'teacher').length,
      admins: users.filter(u => u.role === 'admin').length,
      courses: getAllCourses().length,
      inviteCodes: getAllInviteCodes().length,
    },
  });
});

module.exports = router;
