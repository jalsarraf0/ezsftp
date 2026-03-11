#!/usr/bin/env bash
# ==============================================================
#  By: Jamal Al-Sarraf
#  Provision or revoke chrooted SFTP users with DRY-RUN support
# ==============================================================
set -Eeuo pipefail
VERSION="1.6"

# ─── Colour helpers ───────────────────────────────────────────
NC="$(tput sgr0  || true)"
CY="$(tput setaf 6 || true)"   # cyan
GR="$(tput setaf 2 || true)"   # green
YE="$(tput setaf 3 || true)"   # yellow
BD="$(tput bold   || true)"

banner() { printf "\n${BD}${CY}%s${NC}\n" "─── $* ───"; }

# ─── Configuration ───────────────────────────────────────────
CHROOT_BASE="${CHROOT_BASE:-/chroot}"
SHARED_DIR="${SHARED_DIR:-/shared}"
GROUP_NAME="${GROUP_NAME:-sftpaccess}"
KEY_DIR="${KEY_DIR:-/root/created_keys}"
FSTAB_FILE="${FSTAB_FILE:-/etc/fstab}"
SSHD_FRAG_DIR="${SSHD_FRAG_DIR:-/etc/ssh/sshd_config.d}"

# ─── Usage / man page ────────────────────────────────────────
usage() {
cat <<EOF
${BD}NAME${NC}
    manage_sftp_chroot_user — provision or revoke chrooted SFTP users

${BD}SYNOPSIS${NC}
    ${BD}manage_sftp_chroot_user.sh${NC} [-h] [-n] [--non-interactive --action add|remove --user <name>]

${BD}DESCRIPTION${NC}
    Adds or removes users that are jailed to /chroot/<user> for SFTP-only
    access and granted group read/write to /shared. Generates OpenSSH + PuTTY
    keys, edits /etc/fstab, drops per-user sshd_config fragments, and reloads
    sshd.  All actions are idempotent.

${BD}OPTIONS${NC}
    -h, --help             Show help and exit.
    -n, --dry-run          Start in DRY-RUN mode (preview only, no changes).
    --non-interactive      Disable menu and execute one action.
    --action add|remove    Action to execute in non-interactive mode.
    --user <username>      Username for non-interactive add/remove action.

${BD}MENU SHORTCUTS${NC}
      1   Add user         (live/dry depending on mode)
      2   Remove user
      3   Toggle DRY-RUN   (switch LIVE ↔ DRY)
      4   Show this help
      Q   Quit

${BD}ENVIRONMENT${NC}
    DRY_RUN=1             Same effect as --dry-run flag.
    CHROOT_BASE=...       Override chroot base path.
    SHARED_DIR=...        Override shared directory path.
    GROUP_NAME=...        Override managed access group.
    KEY_DIR=...           Override generated SSH key output directory.
    FSTAB_FILE=...        Override fstab target file.
    SSHD_FRAG_DIR=...     Override sshd fragment output directory.

EOF
}

# ─── Parse CLI flags ─────────────────────────────────────────
DRY=${DRY_RUN:-0}
NON_INTERACTIVE=0
ACTION=""
TARGET_USER=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -n|--dry-run) DRY=1; shift ;;
    --non-interactive) NON_INTERACTIVE=1; shift ;;
    --action)
      [[ $# -ge 2 ]] || { printf 'Missing value for --action\n' >&2; usage; exit 1; }
      ACTION="$2"
      shift 2
      ;;
    --user)
      [[ $# -ge 2 ]] || { printf 'Missing value for --user\n' >&2; usage; exit 1; }
      TARGET_USER="$2"
      shift 2
      ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage; exit 1 ;;
  esac
done

validate_username() {
  local candidate="$1"
  [[ "$candidate" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || {
    printf "Invalid username: %s\n" "$candidate" >&2
    exit 1
  }
}

if [[ "$NON_INTERACTIVE" == "1" ]]; then
  case "$ACTION" in
    add|remove) ;;
    *)
      printf "Non-interactive mode requires --action add|remove\n" >&2
      usage
      exit 1
      ;;
  esac
  [[ -n "$TARGET_USER" ]] || {
    printf "Non-interactive mode requires --user <username>\n" >&2
    usage
    exit 1
  }
  validate_username "$TARGET_USER"
fi

# ─── Dry-run wrapper ─────────────────────────────────────────
run() {
  if [[ "$DRY" == "1" ]]; then
    printf "%b %b %s\n" "${YE}DRY-RUN${NC}" "${CY}➜${NC}" "$*"
  else
    "$@"
  fi
}

# ─── Pre-flight ──────────────────────────────────────────────
[[ $EUID -eq 0 ]] || { echo "❌  Must run as root." >&2; exit 1; }
mkdir -p "$KEY_DIR" "$SSHD_FRAG_DIR" "$SHARED_DIR" "$CHROOT_BASE"
touch "$FSTAB_FILE"

# ─── add_user() ──────────────────────────────────────────────
add_user() {
  local U="$1"
  banner "Provisioning ${U}${DRY:+  (DRY-RUN)}"

  local HR="/home/${U}"
  local CR="${CHROOT_BASE}/${U}"
  local CH="${CR}/home/${U}"
  local CS="${CR}/shared"
  local KF="${KEY_DIR}/${U}_key"
  local PPK="${SHARED_DIR}/${U}.ppk"
  local FRAG="${SSHD_FRAG_DIR}/${U}.conf"

  # 1 ▸ group & user
  getent group "$GROUP_NAME" >/dev/null || run groupadd "$GROUP_NAME"
  id -u "$U" &>/dev/null || run useradd -M -d "$HR" -s /bin/bash "$U"
  run usermod -aG "$GROUP_NAME" "$U"

  # 2 ▸ directory tree & permissions
  run mkdir -p "$HR" "$CH" "$CS"
  run chown root:root "$CR" && run chmod 755 "$CR"
  run chown -R "$U:$U" "$HR" "$CH" && run chmod 700 "$HR" "$CH"
  run chown root:"$GROUP_NAME" "$SHARED_DIR" "$CS" && run chmod 2770 "$SHARED_DIR" "$CS"

  # 3 ▸ fstab + bind mounts
  for LINE in \
      "${HR}  ${CH}  none  bind  0 0" \
      "${SHARED_DIR} ${CS} none  bind  0 0"; do
        grep -Fqx "$LINE" "$FSTAB_FILE" || run bash -c "echo '$LINE' >> '$FSTAB_FILE'"
        TARGET=$(awk '{print $2}' <<<"$LINE")
        mountpoint -q "$TARGET" || run mount "$TARGET"
  done
  run systemctl daemon-reload

  # 4 ▸ keys
  [[ -f "$KF" ]] || run ssh-keygen -t rsa -b 4096 -N "" -C "${U}@$(hostname -s)" -f "$KF"
  run install -d -m700 -o "$U" -g "$U" "${CH}/.ssh"
  run install -m600 -o "$U" -g "$U" "${KF}.pub" "${CH}/.ssh/authorized_keys"
  command -v puttygen >/dev/null || run dnf -qy install putty-tools
  run puttygen "$KF" -O private -o "$PPK"
  run chown root:"$GROUP_NAME" "$PPK" && run chmod 660 "$PPK"

  # 5 ▸ sshd fragment
  run bash -c "cat > '$FRAG' <<EOF
Match User ${U}
    ChrootDirectory ${CR}
    ForceCommand    internal-sftp
    AllowTCPForwarding no
    X11Forwarding     no
    AuthorizedKeysFile /home/${U}/.ssh/authorized_keys
EOF"
  run chmod 644 "$FRAG"
  run systemctl reload sshd

  printf "${GR}✓${NC} User '%s' provisioned.%s\n" "$U" "${DRY:+  (dry-run only)}"
}

# ─── remove_user() ───────────────────────────────────────────
remove_user() {
  local U="$1"
  banner "Revoking ${U}${DRY:+  (DRY-RUN)}"

  local HR="/home/${U}"
  local CR="${CHROOT_BASE}/${U}"
  local CH="${CR}/home/${U}"
  local CS="${CR}/shared"
  local KF="${KEY_DIR}/${U}_key"
  local PPK="${SHARED_DIR}/${U}.ppk"
  local FRAG="${SSHD_FRAG_DIR}/${U}.conf"

  if id -u "$U" &>/dev/null; then
    run gpasswd -d "$U" "$GROUP_NAME" || true
  fi

  # unmount
  for T in "$CH" "$CS"; do
    if mountpoint -q "$T"; then
      run umount "$T" || true
    fi
  done

  # fstab cleanup — use grep -F (fixed-string) to avoid regex issues with path chars
  if [[ "$DRY" == "1" ]]; then
    printf "%b %b %s\n" "${YE}DRY-RUN${NC}" "${CY}➜${NC}" "grep -Fv '${HR}' '${FSTAB_FILE}' > '${FSTAB_FILE}.tmp' && mv '${FSTAB_FILE}.tmp' '${FSTAB_FILE}'"
    printf "%b %b %s\n" "${YE}DRY-RUN${NC}" "${CY}➜${NC}" "grep -Fv '${SHARED_DIR}' '${FSTAB_FILE}' > '${FSTAB_FILE}.tmp' && mv '${FSTAB_FILE}.tmp' '${FSTAB_FILE}'"
  else
    grep -Fv "${HR}" "${FSTAB_FILE}" > "${FSTAB_FILE}.tmp" && mv "${FSTAB_FILE}.tmp" "${FSTAB_FILE}"
    grep -Fv "${SHARED_DIR}" "${FSTAB_FILE}" > "${FSTAB_FILE}.tmp" && mv "${FSTAB_FILE}.tmp" "${FSTAB_FILE}"
  fi
  run systemctl daemon-reload

  # sshd fragment
  [[ -f "$FRAG" ]] && run rm -f "$FRAG" && run systemctl reload sshd

  # keys & directories
  run rm -f "${KF}" "${KF}.pub" "${PPK}"
  run rm -rf "$CR" "$HR"
  if id -u "$U" &>/dev/null; then
    run userdel "$U" || true
  fi

  printf "${GR}✓${NC} User '%s' removed.%s\n" "$U" "${DRY:+  (dry-run only)}"
}

# ─── Interactive menu ─────────────────────────────────────────
while true; do
  if [[ "$NON_INTERACTIVE" == "1" ]]; then
    case "$ACTION" in
      add) add_user "$TARGET_USER" ;;
      remove) remove_user "$TARGET_USER" ;;
    esac
    exit 0
  fi

  if [[ $DRY == 1 ]]; then
    MODE_STATE="${YE}DRY-RUN${NC}"
  else
    MODE_STATE="${GR}LIVE${NC}"
  fi
  MODE_TXT="${BD}MODE:${NC} ${MODE_STATE}"
  banner "Chroot-SFTP User Manager v${VERSION} — ${MODE_TXT}"
  printf "%s\n" \
         "${BD}1${NC}) Add user" \
         "${BD}2${NC}) Remove user" \
         "${BD}3${NC}) Toggle dry-run" \
         "${BD}4${NC}) Help / man page" \
         "${BD}Q${NC}) Quit"
  read -rp "Select: " choice
  case "${choice^^}" in
    1) read -rp "Username to ADD: " u && [[ $u ]] && add_user "$u" ;;
    2) read -rp "Username to REMOVE: " u && [[ $u ]] && remove_user "$u" ;;
    3)
       if [[ $DRY == 1 ]]; then DRY=0; echo -e "${GR}▶ LIVE mode enabled.${NC}"
       else                       DRY=1; echo -e "${YE}▶ DRY-RUN mode enabled.${NC}"; fi
       ;;
    4) usage ;;
    Q) echo 'Good-bye.'; exit 0 ;;
    *) echo "Invalid choice." ;;
  esac
done
