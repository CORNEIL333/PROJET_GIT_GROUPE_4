// backend/models/database.js
// Base de données en mémoire (à remplacer par SQLite ou MongoDB plus tard)

const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');

// ─── DONNÉES INITIALES ────────────────────────────────────────────────────────

const db = {
  users: [],
  courses: [],
  inviteCodes: [], // codes générés par admin pour les enseignants
};

// Créer l'admin par défaut au démarrage
async function initDB() {
  const hashedPassword = await bcrypt.hash('admin1234', 10);
  db.users.push({
    id: uuidv4(),
    name: 'Administrateur',
    email: 'admin@univ.cm',
    password: hashedPassword,
    role: 'admin',
    createdAt: new Date().toISOString(),
  });
  console.log('✅ Base de données initialisée');
  console.log('👤 Admin par défaut : admin@univ.cm / admin1234');
}

// ─── FONCTIONS UTILISATEURS ───────────────────────────────────────────────────

function findUserByEmail(email) {
  return db.users.find(u => u.email === email);
}

function findUserById(id) {
  return db.users.find(u => u.id === id);
}

function createUser(data) {
  const user = { id: uuidv4(), ...data, createdAt: new Date().toISOString() };
  db.users.push(user);
  return user;
}

function getAllUsers() {
  return db.users.map(({ password, ...u }) => u); // ne pas exposer le mot de passe
}

function getUsersByRole(role) {
  return db.users.filter(u => u.role === role).map(({ password, ...u }) => u);
}

// ─── CODES D'INVITATION (pour enseignants) ────────────────────────────────────

function createInviteCode(createdByAdminId) {
  const code = {
    id: uuidv4(),
    code: Math.random().toString(36).substring(2, 10).toUpperCase(), // ex: "A3FX9K2B"
    createdBy: createdByAdminId,
    usedBy: null,
    used: false,
    createdAt: new Date().toISOString(),
  };
  db.inviteCodes.push(code);
  return code;
}

function findInviteCode(code) {
  return db.inviteCodes.find(c => c.code === code && !c.used);
}

function markCodeAsUsed(code, userId) {
  const invite = db.inviteCodes.find(c => c.code === code);
  if (invite) {
    invite.used = true;
    invite.usedBy = userId;
  }
}

function getAllInviteCodes() {
  return db.inviteCodes;
}

// ─── COURS ────────────────────────────────────────────────────────────────────

function createCourse(data) {
  const course = { id: uuidv4(), ...data, students: [], createdAt: new Date().toISOString() };
  db.courses.push(course);
  return course;
}

function getAllCourses() {
  return db.courses;
}

function getCoursesByTeacher(teacherId) {
  return db.courses.filter(c => c.teacherId === teacherId);
}

function getCoursesByStudent(studentId) {
  return db.courses.filter(c => c.students.includes(studentId));
}

async function updateUserPassword(userId, newPassword) {
  const user = db.users.find(u => u.id === userId);
  if (user) {
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    return true;
  }
  return false;
}

module.exports = {
  initDB,
  findUserByEmail,
  findUserById,
  createUser,
  getAllUsers,
  getUsersByRole,
  createInviteCode,
  findInviteCode,
  markCodeAsUsed,
  getAllInviteCodes,
  createCourse,
  getAllCourses,
  getCoursesByTeacher,
  getCoursesByStudent,
  updateUserPassword,
};
