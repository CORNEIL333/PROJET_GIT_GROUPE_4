const express = require('express');
const cors = require('cors');
const { exec } = require('child_process');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

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
});
