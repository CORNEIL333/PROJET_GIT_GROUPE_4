#!/bin/bash
# ============================================================================
# Script: create_course_repo.sh
# Description: Crée un dépôt Git pour un cours avec configuration avancée
# Author: GitUniversitaire
# Version: 2.0
# ============================================================================

set -euo pipefail  # Arrêt immédiat en cas d'erreur

# ============================================================================
# Configuration
# ============================================================================

# Répertoires (avec valeurs par défaut)
REPO_DIR="${REPO_DIR:-/home/git/repos}"
TEMPLATE_DIR="${TEMPLATE_DIR:-/home/git/templates}"
HOOKS_DIR="${HOOKS_DIR:-/home/git/hooks}"
CONFIG_DIR="${CONFIG_DIR:-/home/git/config}"

# Options par défaut
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
DEFAULT_VISIBILITY="${DEFAULT_VISIBILITY:-private}"  # private ou public
ENABLE_WIKI="${ENABLE_WIKI:-false}"
ENABLE_ISSUES="${ENABLE_ISSUES:-false}"
CREATE_README="${CREATE_README:-true}"
SETUP_WEBHOOKS="${SETUP_WEBHOOKS:-false}"
VERBOSE=false
DRY_RUN=false

# Webhooks (exemple)
WEBHOOK_URL="${WEBHOOK_URL:-}"

# ============================================================================
# Couleurs et fonctions utilitaires
# ============================================================================

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_debug() { if $VERBOSE; then echo -e "${MAGENTA}[DEBUG]${NC} $1"; fi; }

show_usage() {
    cat << EOF
Usage: $0 CODE_COURS "Nom du Cours" [OPTIONS]

Arguments:
  CODE_COURS           Code unique du cours (ex: L3INFO, M1GL2025)
  "Nom du Cours"       Nom descriptif du cours

Options:
  -b, --branch NAME    Branche par défaut (défaut: main)
  -v, --visibility     Visibilité du dépôt (private|public) (défaut: private)
  --wiki               Activer le wiki pour le cours
  --issues             Activer le système d'issues
  --no-readme          Ne pas créer de README automatique
  --webhooks           Configurer les webhooks par défaut
  --template NAME      Utiliser un template de dépôt
  --owner USER         Propriétaire du dépôt (défaut: git)
  --description TEXT   Description personnalisée
  --dry-run            Simulation sans création réelle
  --verbose, -v        Mode verbeux
  --help, -h           Afficher cette aide

Examples:
  $0 L3INFO "Licence 3 Informatique"
  $0 M1GL2025 "Master 1 Genie Logiciel" --wiki --issues
  $0 L2MATH "Mathématiques L2" --branch master --visibility public
  $0 L3INFO "Projet Annuel" --template projet-template --webhooks

EOF
}

# Validation du code cours
validate_course_code() {
    local code="$1"
    if [[ ! "$code" =~ ^[A-Za-z0-9][A-Za-z0-9_-]{2,49}$ ]]; then
        log_error "Code cours invalide: $code"
        echo "   Le code doit contenir 3-50 caractères alphanumériques, tirets ou underscores"
        return 1
    fi
    return 0
}

# Validation du nom
validate_course_name() {
    local name="$1"
    if [[ ${#name} -lt 3 ]] || [[ ${#name} -gt 100 ]]; then
        log_error "Le nom du cours doit contenir entre 3 et 100 caractères"
        return 1
    fi
    return 0
}

# Vérification des privilèges
check_permissions() {
    if [[ $DRY_RUN == false ]]; then
        if [[ $EUID -ne 0 ]] && ! groups | grep -q "git"; then
            log_warning "Vous n'êtes pas dans le groupe 'git'. Certaines opérations peuvent échouer."
        fi
        
        # Vérifier qu'on peut écrire dans REPO_DIR
        if [[ ! -w "$REPO_DIR" ]]; then
            log_error "Pas de permission d'écriture dans $REPO_DIR"
            return 1
        fi
    fi
    return 0
}

# ============================================================================
# Création du README
# ============================================================================

create_readme() {
    local repo_path="$1"
    local course_code="$2"
    local course_name="$3"
    local branch="$4"
    local readme_path="/tmp/README_${course_code}.md"
    
    cat > "$readme_path" << EOF
# ${course_name}

## 📚 Description
Bienvenue dans le dépôt officiel du cours **${course_name}** (${course_code}).

## 📁 Structure
- \`/cours/\` - Supports de cours et diapositives
- \`/tps/\` - Travaux pratiques et exercices
- \`/projets/\` - Projets et évaluations
- \`/ressources/\` - Documentation et liens utiles

## 🎯 Objectifs
- Maîtriser les concepts fondamentaux
- Développer des compétences pratiques
- Collaborer efficacement en équipe

## 👥 Équipe pédagogique
- Responsable: À définir
- Enseignants: À définir

## 📅 Planning
| Semaine | Sujet | Rendu |
|---------|------|-------|
| 1 | Introduction | - |
| 2 | Fondamentaux | - |

## 🔗 Liens utiles
- [GitHub Classroom](https://classroom.github.com)
- [Documentation](https://docs.github.com)

## 📝 Règles du dépôt
1. Respectez la structure des dossiers
2. Commentez votre code
3. Utilisez des messages de commit explicites
4. Créez une branche par fonctionnalité

---
*Dernière mise à jour: $(date '+%d/%m/%Y')*
EOF
    
    if [[ $DRY_RUN == false ]]; then
        # Cloner temporairement pour ajouter le README
        local temp_dir="/tmp/git_temp_${course_code}"
        git clone "file://$repo_path" "$temp_dir" 2>/dev/null
        cd "$temp_dir"
        cp "$readme_path" "README.md"
        git add README.md
        git commit -m "docs: ajout du README initial du cours" 2>/dev/null || true
        git push origin "$branch" 2>/dev/null
        cd - > /dev/null
        rm -rf "$temp_dir"
        rm -f "$readme_path"
        log_success "README.md créé et poussé sur la branche $branch"
    else
        log_info "[DRY RUN] README.md serait créé"
    fi
}

# ============================================================================
# Configuration des hooks avancés
# ============================================================================

setup_hooks() {
    local repo_path="$1"
    local course_code="$2"
    
    # Hook post-receive amélioré
    cat > "/tmp/post-receive-${course_code}" << 'EOF'
#!/bin/bash
# Post-receive hook pour notifications et automatisations

while read oldrev newrev refname; do
    branch=$(git rev-parse --symbolic --abbrev-ref $refname)
    echo "🔔 Push détecté sur la branche: $branch"
    
    # Envoyer une notification (exemple avec curl)
    # curl -X POST https://webhook.site/xxx -d "branch=$branch"
    
    # Mettre à jour les permissions si nécessaire
    # ./hooks/update-permissions.sh
done

echo "✅ Hook post-receive exécuté avec succès"
EOF
    
    if [[ $DRY_RUN == false ]]; then
        sudo cp "/tmp/post-receive-${course_code}" "$repo_path/hooks/post-receive"
        sudo chmod +x "$repo_path/hooks/post-receive"
        rm -f "/tmp/post-receive-${course_code}"
        log_success "Hook post-receive installé"
        
        # Hook pre-receive pour validation
        cat > "$repo_path/hooks/pre-receive" << 'EOF'
#!/bin/bash
# Vérification des conventions avant push
echo "🔍 Validation du push en cours..."
# Ajoutez vos règles de validation ici
exit 0
EOF
        sudo chmod +x "$repo_path/hooks/pre-receive"
        
    else
        log_info "[DRY RUN] Hooks seraient installés"
    fi
}

# ============================================================================
# Configuration des webhooks
# ============================================================================

setup_webhooks() {
    local repo_path="$1"
    local course_code="$2"
    local webhooks_file="$repo_path/webhooks.config"
    
    if [[ -n "$WEBHOOK_URL" ]]; then
        if [[ $DRY_RUN == false ]]; then
            cat > "$webhooks_file" << EOF
# Webhooks configurés pour $course_code
# Format: URL|EVENTS|SECRET
$WEBHOOK_URL|push,issues|webhook_secret_$(openssl rand -hex 8)
EOF
            log_success "Webhook configuré: $WEBHOOK_URL"
        else
            log_info "[DRY RUN] Webhook serait configuré: $WEBHOOK_URL"
        fi
    fi
}

# ============================================================================
# Fonction principale
# ============================================================================

main() {
    # Parsing des arguments
    local course_code=""
    local course_name=""
    local branch="$DEFAULT_BRANCH"
    local visibility="$DEFAULT_VISIBILITY"
    local owner="git"
    local custom_description=""
    local template_name=""
    
    # Premier argument: CODE_COURS
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi
    
    course_code="$1"
    shift
    
    # Deuxième argument: Nom du Cours
    if [[ $# -eq 0 ]]; then
        log_error "Nom du cours manquant"
        show_usage
        exit 1
    fi
    
    course_name="$1"
    shift
    
    # Options restantes
    while [[ $# -gt 0 ]]; do
        case $1 in
            -b|--branch)
                branch="$2"
                shift 2
                ;;
            -v|--visibility)
                visibility="$2"
                if [[ "$visibility" != "private" && "$visibility" != "public" ]]; then
                    log_error "Visibilité invalide. Utilisez 'private' ou 'public'"
                    exit 1
                fi
                shift 2
                ;;
            --wiki)
                ENABLE_WIKI=true
                shift
                ;;
            --issues)
                ENABLE_ISSUES=true
                shift
                ;;
            --no-readme)
                CREATE_README=false
                shift
                ;;
            --webhooks)
                SETUP_WEBHOOKS=true
                shift
                ;;
            --template)
                template_name="$2"
                shift 2
                ;;
            --owner)
                owner="$2"
                shift 2
                ;;
            --description)
                custom_description="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                log_error "Option inconnue: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validations
    validate_course_code "$course_code" || exit 1
    validate_course_name "$course_name" || exit 1
    check_permissions || exit 1
    
    local repo_path="$REPO_DIR/$course_code.git"
    
    # Vérification si le dépôt existe déjà
    if [[ -d "$repo_path" ]]; then
        log_error "Le dépôt $course_code existe déjà dans $REPO_DIR"
        exit 1
    fi
    
    # Affichage du résumé
    echo "================================================================================"
    echo "📚 CRÉATION DU DÉPÔT COURS"
    echo "================================================================================"
    log_info "Code cours:     $course_code"
    log_info "Nom:            $course_name"
    log_info "Chemin:         $repo_path"
    log_info "Branche par défaut: $branch"
    log_info "Visibilité:     $visibility"
    log_info "Propriétaire:   $owner"
    [[ -n "$custom_description" ]] && log_info "Description:    $custom_description"
    echo "================================================================================"
    
    if $DRY_RUN; then
        log_warning "🧪 MODE SIMULATION - Aucune modification réelle"
        echo ""
        log_info "Commandes qui seraient exécutées:"
        echo "  git init --bare --initial-branch=$branch \"$repo_path\""
        echo "  echo \"$course_name\" > \"$repo_path/description\""
        [[ $CREATE_README == true ]] && echo "  Création d'un README.md personnalisé"
        [[ $SETUP_WEBHOOKS == true ]] && echo "  Configuration des webhooks"
        echo ""
        log_success "Simulation terminée"
        exit 0
    fi
    
    # Création du dépôt
    log_info "Création du dépôt Git bare..."
    if command -v sudo &> /dev/null; then
        sudo -u "$owner" git init --bare --initial-branch="$branch" "$repo_path" 2>&1 | log_debug
    else
        git init --bare --initial-branch="$branch" "$repo_path" 2>&1 | log_debug
    fi
    
    # Description du dépôt
    if [[ -n "$custom_description" ]]; then
        echo "$custom_description" | sudo tee "$repo_path/description" > /dev/null
    else
        echo "$course_name - Dépôt officiel du cours" | sudo tee "$repo_path/description" > /dev/null
    fi
    log_success "Dépôt créé avec succès"
    
    # Configuration Git du dépôt
    cd "$repo_path"
    git config --file config core.sharedRepository group 2>/dev/null || true
    git config --file config receive.denyNonFastforwards true 2>/dev/null || true
    cd - > /dev/null
    
    # Utilisation d'un template si spécifié
    if [[ -n "$template_name" ]] && [[ -d "$TEMPLATE_DIR/$template_name" ]]; then
        log_info "Application du template: $template_name"
        local temp_clone="/tmp/template_apply_${course_code}"
        git clone "file://$TEMPLATE_DIR/$template_name" "$temp_clone" 2>/dev/null
        cd "$temp_clone"
        git push --mirror "file://$repo_path" 2>/dev/null
        cd - > /dev/null
        rm -rf "$temp_clone"
        log_success "Template appliqué"
    fi
    
    # Installation des hooks
    setup_hooks "$repo_path" "$course_code"
    
    # Configuration des webhooks
    if $SETUP_WEBHOOKS; then
        setup_webhooks "$repo_path" "$course_code"
    fi
    
    # Création du README
    if $CREATE_README; then
        create_readme "$repo_path" "$course_code" "$course_name" "$branch"
    fi
    
    # Configuration des fonctionnalités additionnelles
    local config_file="$repo_path/gitweb.conf"
    cat > "/tmp/gitweb_${course_code}.conf" << EOF
# Configuration GitWeb pour $course_code
description = $course_name
owner = $owner
category = Courses
EOF
    sudo cp "/tmp/gitweb_${course_code}.conf" "$config_file" 2>/dev/null || true
    rm -f "/tmp/gitweb_${course_code}.conf"
    
    # Génération d'un rapport
    echo "================================================================================"
    log_success "✅ Dépôt créé avec succès!"
    echo "📁 Emplacement: $repo_path"
    echo "🔗 Clone URL:   git clone git@$(hostname):$course_code.git"
    echo "🌐 Web accès:   http://$(hostname)/gitweb/?p=$course_code.git"
    echo "📊 Taille:      $(du -sh "$repo_path" 2>/dev/null | cut -f1)"
    echo "================================================================================"
    
    # Log pour traçabilité
    local log_entry="[$(date '+%Y-%m-%d %H:%M:%S')] Création dépôt: $course_code | $course_name | owner=$owner | branch=$branch"
    echo "$log_entry" >> "$REPO_DIR/.creation_log"
    
    exit 0
}

# ============================================================================
# Exécution
# ============================================================================

main "$@"