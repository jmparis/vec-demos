#!/usr/bin/env bash
set -euo pipefail

ARCH_PACKAGES=(
  base-devel
  git
  make
  python
  mame
  flatpak
  podman
)

FEDORA_PACKAGES=(
  lwtools
  make
  python3
  mame
  flatpak
  podman
)

RETROARCH_FLATPAK_ID=org.libretro.RetroArch
FLATHUB_URL=https://dl.flathub.org/repo/flathub.flatpakrepo
VECX_CORE="${HOME}/.var/app/${RETROARCH_FLATPAK_ID}/config/retroarch/cores/vecx_libretro.so"

ASSUME_YES=0
CHECK_ONLY=0

usage() {
  cat <<'EOF'
Usage: tools/install-deps.sh [options]

Installe les dependances utilisees par les targets du Makefile:
  make all, test, test_container, run_mame, run_retroarch, run_jsvecx

Options:
  -y, --yes      Repond oui aux prompts des gestionnaires de paquets
  --check        Verifie les commandes attendues sans installer
  -h, --help     Affiche cette aide
EOF
}

log() {
  printf '\033[1;32m==>\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2
}

die() {
  printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2
  exit 1
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

sudo_cmd() {
  if (( EUID == 0 )); then
    "$@"
  else
    have_cmd sudo || die "sudo est necessaire pour installer les paquets systeme."
    sudo "$@"
  fi
}

detect_distro() {
  [[ -r /etc/os-release ]] || die "Impossible de detecter la distribution: /etc/os-release absent."
  # shellcheck disable=SC1091
  source /etc/os-release

  case " ${ID:-} ${ID_LIKE:-} " in
    *" arch "*|*" cachyos "*)
      printf '%s\n' arch
      ;;
    *" fedora "*)
      printf '%s\n' fedora
      ;;
    *)
      die "Distribution non supportee (${PRETTY_NAME:-inconnue}). Support actuel: CachyOS/Arch et Fedora."
      ;;
  esac
}

missing_commands() {
  local missing=()
  local command_name

  for command_name in make python3 lwasm mame flatpak podman; do
    if ! have_cmd "$command_name"; then
      missing+=("$command_name")
    fi
  done

  if have_cmd flatpak && ! flatpak info "$RETROARCH_FLATPAK_ID" >/dev/null 2>&1; then
    missing+=("flatpak:${RETROARCH_FLATPAK_ID}")
  fi

  printf '%s\n' "${missing[@]}"
}

run_check_only() {
  local missing
  mapfile -t missing < <(missing_commands)

  if ((${#missing[@]} == 0)); then
    log "Toutes les commandes principales sont disponibles."
  else
    warn "Dependances manquantes:"
    printf '  - %s\n' "${missing[@]}" >&2
  fi

  if [[ -f "$VECX_CORE" ]]; then
    log "Core RetroArch VecX trouve: $VECX_CORE"
  else
    warn "Core RetroArch VecX absent: $VECX_CORE"
    warn "Lance RetroArch puis installe le core GCE Vectrex (vecx) via Online Updater > Core Downloader."
  fi
}

install_arch_packages() {
  have_cmd pacman || die "pacman introuvable sur cette distribution de type Arch."

  log "Installation des paquets Arch/CachyOS avec pacman"
  local args=(-S --needed)
  if (( ASSUME_YES )); then
    args+=(--noconfirm)
  fi
  sudo_cmd pacman "${args[@]}" "${ARCH_PACKAGES[@]}"
}

install_lwtools_from_aur() {
  if have_cmd lwasm; then
    log "lwtools deja disponible: $(command -v lwasm)"
    return
  fi

  log "Installation de lwtools depuis l'AUR"
  if have_cmd paru; then
    local args=(-S --needed lwtools)
    if (( ASSUME_YES )); then
      args+=(--noconfirm)
    fi
    paru "${args[@]}"
    return
  fi

  if have_cmd yay; then
    local args=(-S --needed lwtools)
    if (( ASSUME_YES )); then
      args+=(--noconfirm)
    fi
    yay "${args[@]}"
    return
  fi

  (( EUID != 0 )) || die "makepkg ne doit pas etre lance en root. Relance le script avec un utilisateur normal."

  local workdir
  workdir=$(mktemp -d)
  trap "rm -rf '$workdir'" EXIT

  git clone https://aur.archlinux.org/lwtools.git "$workdir/lwtools"
  local args=(-si --needed)
  if (( ASSUME_YES )); then
    args+=(--noconfirm)
  fi
  (cd "$workdir/lwtools" && makepkg "${args[@]}")
}

install_fedora_packages() {
  have_cmd dnf || die "dnf introuvable sur cette distribution Fedora."

  log "Installation des paquets Fedora avec dnf"
  local args=(install)
  if (( ASSUME_YES )); then
    args+=(-y)
  fi
  sudo_cmd dnf "${args[@]}" "${FEDORA_PACKAGES[@]}"
}

install_retroarch_flatpak() {
  have_cmd flatpak || die "flatpak devrait etre installe mais reste introuvable."

  log "Configuration de Flathub pour l'utilisateur courant"
  flatpak remote-add --if-not-exists --user flathub "$FLATHUB_URL"

  if flatpak info "$RETROARCH_FLATPAK_ID" >/dev/null 2>&1; then
    log "RetroArch Flatpak deja installe."
    return
  fi

  log "Installation de RetroArch Flatpak"
  local args=(install --user flathub "$RETROARCH_FLATPAK_ID")
  if (( ASSUME_YES )); then
    args+=(--assumeyes)
  fi
  flatpak "${args[@]}"
}

print_summary() {
  log "Verification finale"
  run_check_only

  cat <<EOF

Commandes utiles:
  make all
  make test
  make run_mame
  make run_retroarch
  make run_jsvecx

Note RetroArch:
  Le Makefile attend le core VecX ici:
  $VECX_CORE
EOF
}

while (($#)); do
  case "$1" in
    -y|--yes)
      ASSUME_YES=1
      ;;
    --check)
      CHECK_ONLY=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      die "Option inconnue: $1"
      ;;
  esac
  shift
done

if (( CHECK_ONLY )); then
  run_check_only
  exit 0
fi

distro=$(detect_distro)

case "$distro" in
  arch)
    install_arch_packages
    install_lwtools_from_aur
    ;;
  fedora)
    install_fedora_packages
    ;;
esac

install_retroarch_flatpak
print_summary
