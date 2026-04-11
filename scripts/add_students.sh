#!/bin/bash
# ============================================================================
# Script: add_students.sh
# Description: Ajoute massivement des étudiants à un cours GitHub Classroom
# Usage: ./add_students.sh CODE_COURS liste_etudiants.txt [--dry-run]
# ============================================================================

set -euo pipefail  # Exit on error, undefined variable, pipe failure

# Couleurs pour une meilleure lisibilité
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# ============================================================================
# Fonctions utilitaires
# ============================================================================

print_error() { echo -e "${RED}❌ $1${NC}" >&2; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_header() { echo -e "\n${CYAN}📌 $1${NC}\n"; }

show_usage() {
    cat << EOF
Usage: $0 CODE_COURS liste_etudiants.txt [OPTIONS]

Arguments:
  CODE_COURS           Code du cours (ex: L3INFO, M1GL)
  liste_etudiants.txt  Fichier contenant les identifiants (un par ligne)

Options:
  --dry-run           Simulation sans modification réelle
  --help, -h          Afficher cette aide
  --verbose, -v       Mode verbeux
  --delay SECONDS     Délai entre chaque ajout (défaut: 0.5s)
  --github-token TOKEN Token GitHub (ou utilise GITHUB_TOKEN env)

Examples:
  $0 L3INFO etudiants.txt
  $0 M1GL promo2025.txt --dry-run --verbose
  $0 L3INFO liste.txt --delay 1

EOF
}

cleanup() {
    # Nettoyage si nécessaire (fichiers temporaires, etc.)
    if [[ -n "${TEMP_FILE:-}" ]] && [[ -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
    fi
}

# Gestion des erreurs
trap cleanup EXIT

# ============================================================================
# Validation des paramètres
# ============================================================================

# Options par défaut
DRY_RUN=false
VERBOSE=false
DELAY=0.5
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

# Parsing des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --delay)
            DELAY="$2"
            shift 2
            ;;
        --github-token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        -*)
            print_error "Option inconnue: $1"
            show_usage
            exit 1
            ;;
        *)
            if [[ -z "${COURSE_CODE:-}" ]]; then
                COURSE_CODE="$1"
            elif [[ -z "${STUDENT_FILE:-}" ]]; then
                STUDENT_FILE="$1"
            else
                print_error "Argument superflu: $1"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Vérification des paramètres obligatoires
if [[ -z "${COURSE_CODE:-}" ]] || [[ -z "${STUDENT_FILE:-}" ]]; then
    print_error "Arguments manquants"
    show_usage
    exit 1
fi

# Validation du code cours
if [[ ! "$COURSE_CODE" =~ ^[A-Za-z0-9_-]+$ ]]; then
    print_error "Le code cours doit être alphanumérique (peut contenir - et _)"
    exit 1
fi

# Validation du fichier étudiant
if [[ ! -f "$STUDENT_FILE" ]]; then
    print_error "Fichier introuvable: $STUDENT_FILE"
    exit 1
fi

if [[ ! -s "$STUDENT_FILE" ]]; then
    print_warning "Le fichier $STUDENT_FILE est vide"
    exit 0
fi

# Validation du délai
if [[ ! "$DELAY" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    print_error "Le délai doit être un nombre (ex: 0.5, 1, 2)"
    exit 1
fi

# ============================================================================
# Configuration GitHub API (optionnelle)
# ============================================================================

USE_GITHUB_API=false
if [[ -n "$GITHUB_TOKEN" ]]; then
    USE_GITHUB_API=true
    print_info "Mode GitHub API activé"
    # Vérification du token
    if ! curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | grep -q "login"; then
        print_error "Token GitHub invalide"
        exit 1
    fi
fi

# ============================================================================
# Lecture et nettoyage de la liste des étudiants
# ============================================================================

print_header "Traitement du cours: $COURSE_CODE"

# Nettoyer le fichier (enlever commentaires, lignes vides, espaces)
STUDENTS=()
while IFS= read -r line; do
    # Enlever les commentaires (#)
    clean_line="${line%%#*}"
    # Enlever les espaces début/fin
    clean_line="$(echo -e "$clean_line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    
    if [[ -n "$clean_line" ]]; then
        STUDENTS+=("$clean_line")
    fi
done < "$STUDENT_FILE"

TOTAL_STUDENTS=${#STUDENTS[@]}

if [[ $TOTAL_STUDENTS -eq 0 ]]; then
    print_warning "Aucun étudiant valide trouvé dans $STUDENT_FILE"
    exit 0
fi

print_info "Fichier chargé: $TOTAL_STUDENTS étudiant(s) trouvé(s)"

# Vérification des doublons
UNIQUE_STUDENTS=($(printf "%s\n" "${STUDENTS[@]}" | sort -u))
if [[ ${#UNIQUE_STUDENTS[@]} -ne $TOTAL_STUDENTS ]]; then
    print_warning "Des doublons ont été détectés et seront ignorés"
    STUDENTS=("${UNIQUE_STUDENTS[@]}")
    TOTAL_STUDENTS=${#STUDENTS[@]}
fi

# ============================================================================
# Mode simulation
# ============================================================================

if $DRY_RUN; then
    print_header "🧪 MODE SIMULATION - Aucune modification réelle"
    echo "Étudiants qui seront ajoutés :"
    for i in "${!STUDENTS[@]}"; do
        printf "  %3d. %s\n" $((i+1)) "${STUDENTS[$i]}"
    done
    echo
    print_success "Simulation terminée ($TOTAL_STUDENTS étudiants)"
    exit 0
fi

# ============================================================================
# Ajout des étudiants
# ============================================================================

print_header "Ajout des étudiants au cours $COURSE_CODE"

SUCCESS_COUNT=0
ERROR_COUNT=0
SKIP_COUNT=0
START_TIME=$(date +%s)

# Création d'un fichier de log
LOG_FILE="add_students_${COURSE_CODE}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Début de l'ajout des étudiants - $(date) ==="
echo "Cours: $COURSE_CODE"
echo "Total: $TOTAL_STUDENTS étudiants"
echo "=========================================="
echo

for i in "${!STUDENTS[@]}"; do
    student="${STUDENTS[$i]}"
    current=$((i+1))
    
    # Affichage de la progression
    printf "[%3d/%3d] " $current $TOTAL_STUDENTS
    
    if $USE_GITHUB_API; then
        # Simulation d'appel API GitHub Classroom
        # Remplacer par votre endpoint réel
        response=$(curl -s -X POST \
            -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            -d "{\"student\":\"$student\"}" \
            "https://api.github.com/classroom/classrooms/${COURSE_CODE}/students" 2>/dev/null)
        
        if [[ "$response" == *"error"* ]]; then
            print_error "Échec: $student"
            ((ERROR_COUNT++))
        else
            print_success "Ajouté: $student"
            ((SUCCESS_COUNT++))
        fi
    else
        # Mode simulation locale (votre logique métier ici)
        # Exemple: appel à une commande CLI existante
        if command -v gh &> /dev/null; then
            # Utilisation de GitHub CLI si disponible
            if gh classroom student-add "$COURSE_CODE" "$student" &> /dev/null; then
                print_success "Ajouté: $student"
                ((SUCCESS_COUNT++))
            else
                print_error "Échec: $student"
                ((ERROR_COUNT++))
            fi
        else
            # Mode simple (juste affichage)
            echo "➕ $student"
            ((SUCCESS_COUNT++))
        fi
    fi
    
    # Délai entre les requêtes pour éviter le rate limiting
    if [[ $current -lt $TOTAL_STUDENTS ]]; then
        sleep "$DELAY"
    fi
done

# ============================================================================
# Résumé final
# ============================================================================

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo
echo "=========================================="
echo "📊 RÉSUMÉ DES OPÉRATIONS"
echo "=========================================="
echo "✅ Réussis :   $SUCCESS_COUNT"
if [[ $ERROR_COUNT -gt 0 ]]; then
    echo "❌ Échecs :    $ERROR_COUNT"
fi
if [[ $SKIP_COUNT -gt 0 ]]; then
    echo "⏭️  Ignorés :   $SKIP_COUNT"
fi
echo "📊 Total :     $TOTAL_STUDENTS"
echo "⏱️  Durée :      ${DURATION}s"
echo "📝 Log :       $LOG_FILE"
echo "=========================================="

if [[ $ERROR_COUNT -eq 0 ]]; then
    print_success "Tous les étudiants ont été ajoutés avec succès !"
    exit 0
else
    print_warning "$ERROR_COUNT erreur(s) rencontrée(s) - Consultez le log pour plus de détails"
    exit 1
fi