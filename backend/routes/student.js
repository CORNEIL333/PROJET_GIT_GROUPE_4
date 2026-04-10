// backend/routes/student.js
// Routes pour les étudiants

const express = require('express');
const router = express.Router();
const { authenticate, authorizeRole } = require('../middleware/auth');
const { getCoursesByStudent, getAllCourses } = require('../models/database');

router.use(authenticate, authorizeRole('student', 'teacher', 'admin'));

// GET /api/student/courses — Cours auxquels l'étudiant est inscrit
router.get('/courses', (req, res) => {
  const courses = getCoursesByStudent(req.user.id);
  res.json({ courses });
});

// GET /api/student/all-courses — Tous les cours disponibles (pour s'inscrire)
router.get('/all-courses', (req, res) => {
  const courses = getAllCourses();
  res.json({ courses });
});

// GET /api/student/profile — Profil de l'étudiant connecté
router.get('/profile', (req, res) => {
  const { password, ...safeUser } = req.user;
  res.json({ user: safeUser });
});

module.exports = router;
