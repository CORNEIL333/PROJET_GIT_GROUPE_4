// app.js — GitUniversitaire — Membre 3
function showToast(message) {
  const toast = document.getElementById('toast');
  if (!toast) return;
  toast.textContent = message;
  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 2800);
}
function openModal() {
  const overlay = document.getElementById('modalOverlay');
  if (overlay) overlay.classList.add('open');
}
function closeModal() {
  const overlay = document.getElementById('modalOverlay');
  if (overlay) overlay.classList.remove('open');
}
function animateCounter(elementId, target, duration) {
  const el = document.getElementById(elementId);
  if (!el) return;
  const step = target / (duration / 16);
  let current = 0;
  const timer = setInterval(function () {
    current += step;
    if (current >= target) { current = target; clearInterval(timer); }
    el.textContent = Math.floor(current).toLocaleString();
  }, 16);
}
function initCounters() {
  const statsBar = document.querySelector('.stats-bar');
  if (!statsBar) return;
  const observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        animateCounter('cnt-etudiants', 1248, 1500);
        animateCounter('cnt-depots', 347, 1500);
        animateCounter('cnt-commits', 892, 1500);
        animateCounter('cnt-cours', 43, 1000);
        observer.disconnect();
      }
    });
  }, { threshold: 0.3 });
  observer.observe(statsBar);
}
document.addEventListener('DOMContentLoaded', function () {
  initCounters();
  console.log('GitUniversitaire chargé !');
});