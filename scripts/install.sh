#!/bin/bash
# ============================================================================
# Script: install_uni_git_platform.sh
# Description: Installation automatisée de la plateforme Git Universitaire
# Author: GitUniversitaire
# Version: 3.0
# ============================================================================

set -euo pipefail  # Arrêt immédiat en cas d'erreur

# ============================================================================
# Configuration
# ============================================================================

# Versions minimales requises
GIT_MIN_VERSION="2.25.0"
DOCKER_MIN_VERSION="20.10.0"
NODE_MIN_VERSION="16.0.0"

# Options d'installation
INSTALL_GIT=true
INSTALL_DOCKER=false
INSTALL_NODE=false
INSTALL_POSTGRES=false
INSTALL_NGINX=false
SETUP_SSH=true
CREATE_ADMIN=true
ENABLE_HTTPS=false
VERBOSE=false
DRY_RUN=false

# Configuration réseau
SSH_PORT=22
HTTP_PORT=80
HTTPS_PORT=443
GIT_USER="git"
GIT_HOME="/home/git"

<<<<<<< HEAD
# URLs de téléchargement
NODE_VERSION="18.19.0"
DOCKER_COMPOSE_VERSION="2.24.0"
=======
if ! id gitserver &>/dev/null; then
    echo -e "${BLUE}👤 Création de l'utilisateur système 'git'...${NC}"
    sudo useradd -m -s /bin/bash git || true
fi

mkdir -p /home/git/repos /home/git/backups /home/git/logs
sudo chown -R git:git /home/git 2>/dev/null || true
>>>>>>> origin/INESS

# ============================================================================
# Couleurs et fonctions utilitaires
# ============================================================================

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_debug() { if $VERBOSE; then echo -e "${MAGENTA}[DEBUG]${NC} $1"; fi; }
log_header() { echo -e "\n${CYAN}════════════════════════════════════════════════════════════════${NC}"; echo -e "${BOLD}$1${NC}"; echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}\n"; }

# ============================================================================
# Vérifications système
# ============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Ce script doit être exécuté en tant que root (ou via sudo)"
        echo "   Utilisez: sudo $0"
        exit 1
    fi
    log_success "Privilèges root vérifiés"
}

check_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        log_info "Système détecté: $OS $VER"
        
        # Vérifier si c'est Ubuntu/Debian
        if [[ ! "$OS" =~ (Ubuntu|Debian) ]]; then
            log_warning "Ce script est optimisé pour Ubuntu/Debian. Compatibilité non garantie."
        fi
    else
        log_warning "Impossible de détecter le système d'exploitation"
    fi
}

check_disk_space() {
    local required_gb=10
    local available_gb=$(df --output=avail / | tail -1 | awk '{print int($1/1024/1024)}')
    
    if [[ $available_gb -lt $required_gb ]]; then
        log_error "Espace disque insuffisant! Disponible: ${available_gb}GB, Requis: ${required_gb}GB"
        exit 1
    fi
    log_success "Espace disque: ${available_gb}GB disponibles"
}

check_memory() {
    local total_mem=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $total_mem -lt 2 ]]; then
        log_warning "Mémoire RAM faible: ${total_mem}GB (recommandé: 2GB+)"
    else
        log_success "Mémoire RAM: ${total_mem}GB"
    fi
}

check_network() {
    if ping -c 1 google.com &> /dev/null; then
        log_success "Connectivité internet vérifiée"
    else
        log_error "Pas de connexion internet détectée"
        exit 1
    fi
}

# ============================================================================
# Installation des dépendances
# ============================================================================

install_git() {
    if ! $INSTALL_GIT; then
        log_info "Installation Git ignorée (--no-git)"
        return 0
    fi
    
    if command -v git &> /dev/null; then
        local git_version=$(git --version | awk '{print $3}')
        log_info "Git déjà installé (version $git_version)"
        
        if [[ "$(printf '%s\n' "$GIT_MIN_VERSION" "$git_version" | sort -V | head -n1)" != "$GIT_MIN_VERSION" ]]; then
            log_warning "Version Git $git_version < $GIT_MIN_VERSION, mise à jour recommandée"
        else
            log_success "Version Git OK"
            return 0
        fi
    fi
    
    log_info "Installation de Git..."
    if $DRY_RUN; then
        log_info "[DRY RUN] sudo apt update && sudo apt install -y git"
    else
        apt update -qq
        apt install -y git
        log_success "Git $(git --version | awk '{print $3}') installé"
    fi
}

install_docker() {
    if ! $INSTALL_DOCKER; then
        log_info "Installation Docker ignorée (--no-docker)"
        return 0
    fi
    
    if command -v docker &> /dev/null; then
        log_success "Docker déjà installé: $(docker --version)"
        return 0
    fi
    
    log_info "Installation de Docker..."
    if $DRY_RUN; then
        log_info "[DRY RUN] Installation Docker via script officiel"
    else
        curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
        sh /tmp/get-docker.sh
        rm /tmp/get-docker.sh
        
        # Installation Docker Compose
        curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        
        log_success "Docker $(docker --version) et Docker Compose installés"
    fi
}

install_node() {
    if ! $INSTALL_NODE; then
        log_info "Installation Node.js ignorée (--no-node)"
        return 0
    fi
    
    if command -v node &> /dev/null; then
        local node_version=$(node --version | sed 's/v//')
        log_info "Node.js déjà installé (version $node_version)"
        return 0
    fi
    
    log_info "Installation de Node.js $NODE_VERSION..."
    if $DRY_RUN; then
        log_info "[DRY RUN] Installation NodeSource"
    else
        curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION%.*}.x" | bash -
        apt install -y nodejs
        log_success "Node.js $(node --version) installé"
    fi
}

install_postgres() {
    if ! $INSTALL_POSTGRES; then
        log_info "Installation PostgreSQL ignorée"
        return 0
    fi
    
    if command -v psql &> /dev/null; then
        log_success "PostgreSQL déjà installé"
        return 0
    fi
    
    log_info "Installation de PostgreSQL..."
    if $DRY_RUN; then
        log_info "[DRY RUN] apt install postgresql postgresql-contrib"
    else
        apt install -y postgresql postgresql-contrib
        systemctl enable postgresql
        systemctl start postgresql
        log_success "PostgreSQL installé et démarré"
    fi
}

install_nginx() {
    if ! $INSTALL_NGINX; then
        log_info "Installation Nginx ignorée"
        return 0
    fi
    
    if command -v nginx &> /dev/null; then
        log_success "Nginx déjà installé"
        return 0
    fi
    
    log_info "Installation de Nginx..."
    if $DRY_RUN; then
        log_info "[DRY RUN] apt install nginx"
    else
        apt install -y nginx
        systemctl enable nginx
        systemctl start nginx
        log_success "Nginx installé et démarré"
    fi
}

# ============================================================================
# Configuration utilisateur Git
# ============================================================================

setup_git_user() {
    if id "$GIT_USER" &>/dev/null; then
        log_info "Utilisateur $GIT_USER existe déjà"
    else
        log_info "Création de l'utilisateur $GIT_USER..."
        if $DRY_RUN; then
            log_info "[DRY RUN] useradd -m -s /bin/bash $GIT_USER"
        else
            useradd -m -s /bin/bash "$GIT_USER"
            log_success "Utilisateur $GIT_USER créé"
        fi
    fi
    
    # Ajouter l'utilisateur courant au groupe git
    if [[ -n "${SUDO_USER:-}" ]]; then
        usermod -a -G "$GIT_USER" "$SUDO_USER"
        log_info "Utilisateur $SUDO_USER ajouté au groupe $GIT_USER"
    fi
}

setup_directories() {
    local dirs=("$GIT_HOME/repos" "$GIT_HOME/backups" "$GIT_HOME/logs" "$GIT_HOME/scripts" "$GIT_HOME/config")
    
    log_info "Création de la structure de dossiers..."
    for dir in "${dirs[@]}"; do
        if $DRY_RUN; then
            log_debug "[DRY RUN] mkdir -p $dir"
        else
            mkdir -p "$dir"
            chown "$GIT_USER:$GIT_USER" "$dir"
            chmod 755 "$dir"
        fi
    done
    
    log_success "Structure créée:"
    echo "  📁 $GIT_HOME/repos     (Dépôts Git)"
    echo "  💾 $GIT_HOME/backups   (Sauvegardes)"
    echo "  📝 $GIT_HOME/logs      (Fichiers de log)"
    echo "  🔧 $GIT_HOME/scripts   (Scripts utilitaires)"
    echo "  ⚙️  $GIT_HOME/config    (Configuration)"
}

setup_ssh() {
    if ! $SETUP_SSH; then
        log_info "Configuration SSH ignorée (--no-ssh)"
        return 0
    fi
    
    local ssh_dir="$GIT_HOME/.ssh"
    
    if $DRY_RUN; then
        log_info "[DRY RUN] Configuration SSH pour l'utilisateur git"
        return 0
    fi
    
    mkdir -p "$ssh_dir"
    chown "$GIT_USER:$GIT_USER" "$ssh_dir"
    chmod 700 "$ssh_dir"
    
    # Créer authorized_keys s'il n'existe pas
    touch "$ssh_dir/authorized_keys"
    chown "$GIT_USER:$GIT_USER" "$ssh_dir/authorized_keys"
    chmod 600 "$ssh_dir/authorized_keys"
    
    # Configurer SSH pour les dépôts Git
    cat >> /etc/ssh/sshd_config.d/git.conf << EOF
# Configuration Git Universitaire
AllowUsers $GIT_USER
Match User $GIT_USER
    PermitTTY no
    ForceCommand git-shell
EOF
    
    # Redémarrer SSH si config modifiée
    if [[ -f /etc/ssh/sshd_config.d/git.conf ]]; then
        systemctl restart sshd || systemctl restart ssh
        log_success "SSH configuré pour l'utilisateur $GIT_USER"
    fi
}

# ============================================================================
# Configuration supplémentaire
# ============================================================================

setup_git_config() {
    if $DRY_RUN; then
        log_info "[DRY RUN] Configuration Git globale"
        return 0
    fi
    
    sudo -u "$GIT_USER" git config --global user.name "Git Universitaire"
    sudo -u "$GIT_USER" git config --global user.email "admin@uni-git.local"
    sudo -u "$GIT_USER" git config --global init.defaultBranch main
    sudo -u "$GIT_USER" git config --global core.editor nano
    
    log_success "Configuration Git globale effectuée"
}

create_admin_script() {
    if ! $CREATE_ADMIN; then
        log_info "Création script admin ignorée"
        return 0
    fi
    
    local admin_script="$GIT_HOME/scripts/admin_tools.sh"
    
    if $DRY_RUN; then
        log_info "[DRY RUN] Création script d'administration"
        return 0
    fi
    
    cat > "$admin_script" << 'EOF'
#!/bin/bash
# Script d'administration Git Universitaire

echo "🔧 Outils d'administration Git Universitaire"
echo "1. Lister les dépôts"
echo "2. Créer un dépôt"
echo "3. Sauvegarder les dépôts"
echo "4. Voir les logs"
read -p "Choix: " choice

case $choice in
    1) ls -la /home/git/repos/ ;;
    2) read -p "Nom du dépôt: " repo; git init --bare "/home/git/repos/$repo.git" ;;
    3) /home/git/scripts/backup.sh ;;
    4) tail -50 /home/git/logs/*.log ;;
    *) echo "Option invalide" ;;
esac
EOF
    
    chmod +x "$admin_script"
    chown "$GIT_USER:$GIT_USER" "$admin_script"
    log_success "Script d'administration créé: $admin_script"
}

generate_ssl_cert() {
    if ! $ENABLE_HTTPS; then
        return 0
    fi
    
    local cert_dir="/etc/ssl/uni-git"
    
    if $DRY_RUN; then
        log_info "[DRY RUN] Génération certificat SSL auto-signé"
        return 0
    fi
    
    mkdir -p "$cert_dir"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$cert_dir/uni-git.key" \
        -out "$cert_dir/uni-git.crt" \
        -subj "/C=FR/ST=Paris/L=Paris/O=UniGit/CN=git.university.local"
    
    log_success "Certificat SSL généré dans $cert_dir"
}

# ============================================================================
# Rapport final
# ============================================================================

generate_report() {
    log_header "📊 RAPPORT D'INSTALLATION"
    
    echo -e "${BOLD}✓ Services installés:${NC}"
    command -v git &> /dev/null && echo "  ✅ Git: $(git --version)"
    command -v docker &> /dev/null && echo "  ✅ Docker: $(docker --version 2>/dev/null)"
    command -v node &> /dev/null && echo "  ✅ Node.js: $(node --version)"
    command -v psql &> /dev/null && echo "  ✅ PostgreSQL: $(psql --version)"
    command -v nginx &> /dev/null && echo "  ✅ Nginx: $(nginx -v 2>&1)"
    
    echo -e "\n${BOLD}✓ Configuration:${NC}"
    echo "  📁 Dépôts: $GIT_HOME/repos"
    echo "  💾 Backups: $GIT_HOME/backups"
    echo "  📝 Logs: $GIT_HOME/logs"
    echo "  👤 Utilisateur Git: $GIT_USER"
    
    if $SETUP_SSH; then
        echo -e "\n${BOLD}✓ Accès SSH:${NC}"
        echo "  🔑 git clone git@$(hostname):mon-repo.git"
    fi
    
    echo -e "\n${BOLD}📝 Logs d'installation:${NC}"
    echo "  📄 $LOG_FILE"
}

# ============================================================================
# Fonction principale
# ============================================================================

show_usage() {
    cat << EOF
Usage: sudo $0 [OPTIONS]

Options:
  --no-git               Ne pas installer Git
  --docker               Installer Docker et Docker Compose
  --node                 Installer Node.js
  --postgres             Installer PostgreSQL
  --nginx                Installer Nginx
  --no-ssh               Ne pas configurer l'accès SSH
  --no-admin             Ne pas créer le script d'administration
  --https                Générer un certificat SSL auto-signé
  --verbose, -v          Mode verbeux
  --dry-run              Simulation sans installation
  --help, -h             Afficher cette aide

Examples:
  sudo $0                              # Installation standard
  sudo $0 --docker --postgres          # Avec Docker et PostgreSQL
  sudo $0 --verbose --dry-run          # Simulation en mode verbeux
  sudo $0 --https --nginx              # Avec HTTPS et Nginx

EOF
}

main() {
    # Parsing des arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-git) INSTALL_GIT=false ;;
            --docker) INSTALL_DOCKER=true ;;
            --node) INSTALL_NODE=true ;;
            --postgres) INSTALL_POSTGRES=true ;;
            --nginx) INSTALL_NGINX=true ;;
            --no-ssh) SETUP_SSH=false ;;
            --no-admin) CREATE_ADMIN=false ;;
            --https) ENABLE_HTTPS=true ;;
            --verbose|-v) VERBOSE=true ;;
            --dry-run) DRY_RUN=true ;;
            --help|-h) show_usage; exit 0 ;;
            *) log_error "Option inconnue: $1"; show_usage; exit 1 ;;
        esac
        shift
    done
    
    # Initialisation des logs
    LOG_FILE="/var/log/uni-git-install-$(date +%Y%m%d-%H%M%S).log"
    touch "$LOG_FILE"
    exec > >(tee -a "$LOG_FILE") 2>&1
    
    # Vérifications préalables
    check_root
    check_os
    check_disk_space
    check_memory
    check_network
    
    log_header "🎓 INSTALLATION PLATEFORME GIT UNIVERSITAIRE"
    log_info "Date: $(date)"
    log_info "Log: $LOG_FILE"
    
    if $DRY_RUN; then
        log_warning "🧪 MODE SIMULATION - Aucune modification réelle"
    fi
    
    # Installation
    install_git
    install_docker
    install_node
    install_postgres
    install_nginx
    
    # Configuration
    setup_git_user
    setup_directories
    setup_ssh
    setup_git_config
    create_admin_script
    generate_ssl_cert
    
    # Rapport final
    generate_report
    
    if $DRY_RUN; then
        log_success "Simulation terminée - Aucune modification réelle effectuée"
    else
        log_success "✅ Installation terminée avec succès!"
        echo -e "\n${YELLOW}👉 Consultez docs/installation_serveur.md pour la configuration avancée.${NC}"
        echo -e "${YELLOW}👉 Redémarrez votre session pour appliquer les changements de groupe.${NC}"
    fi
    
    exit 0
}

# ============================================================================
# Exécution
# ============================================================================

main "$@"