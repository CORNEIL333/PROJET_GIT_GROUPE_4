// backend/routes/teacher.js
// Routes pour les enseignants

const express = require('express');
const router = express.Router();
const { authenticate, authorizeRole } = require('../middleware/auth');
const {
  createCourse,
  getCoursesByTeacher,
  getAllCourses,
  findUserById,
} = require('../models/database');

router.use(authenticate, authorizeRole('teacher', 'admin'));

// GET /api/teacher/courses — Cours de cet enseignant
router.get('/courses', (req, res) => {
  const courses = getCoursesByTeacher(req.user.id);
  res.json({ courses });
});

// POST /api/teacher/courses — Créer un cours
router.post('/courses', (req, res) => {
  const { code, name, description } = req.body;

  if (!code || !name) {
    return res.status(400).json({ error: 'Le code et le nom du cours sont requis.' });
  }

  const course = createCourse({
    code,
    name,
    description: description || '',
    teacherId: req.user.id,
    teacherName: req.user.name,
  });

  res.status(201).json({
    message: `✅ Cours "${name}" créé.`,
    course,
  });
});

// GET /api/teacher/profile — Profil de l'enseignant connecté
router.get('/profile', (req, res) => {
  const { password, ...safeUser } = req.user;
  res.json({ user: safeUser });
});

module.exports = router;
