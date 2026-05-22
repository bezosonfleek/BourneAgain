#!/usr/bin/env bash
# =============================================================================
# ssh_key_rotation.sh
# Rotates SSH public keys across a fleet of servers. Generates a new key pair,
# deploys the new public key, verifies connectivity, then removes the old key.
#
# Usage:    ./ssh_key_rotation.sh --hosts hosts.txt --user deploy [--dry-run]
# Requires: ssh, ssh-keygen, ssh-copy-id, parallel (optional)
# =============================================================================

set -euo pipefail

# ─── Defaults ─────────────────────────────────────────────────────────────────
DRY_RUN=false
SSH_USER="${SSH_USER:-deploy}"
KEY_TYPE="ed25519"
KEY_BITS=""                              # Only used for rsa; ed25519 ignores it
OLD_KEY_PATH="${HOME}/.ssh/id_ed25519"
NEW_KEY_DIR="${HOME}/.ssh/rotated_$(date +%Y%m%d)"
NEW_KEY_PATH="${NEW_KEY_DIR}/id_${KEY_TYPE}"
HOSTS_FILE=""
PARALLEL=false
SSH_PORT=22
CONNECT_TIMEOUT=10
LOG_DIR="/var/log/ssh_key_rotation"
LOG_FILE="${LOG_DIR}/rotation_$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="${HOME}/.ssh/backup_$(date +%Y%m%d)"

# ─── Counters ─────────────────────────────────────────────────────────────────
SUCCESS=0
FAILED=0
SKIPPED=0

# ─── Helpers ──────────────────────────────────────────────────────────────────
log()     { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
info()    { log "INFO  $*"; }
warn()    { log "WARN  $*"; }
error()   { log "ERROR $*"; }
dry_run() { log "DRY   (would run): $*"; }

setup_dirs() {
    mkdir -p "$LOG_DIR" "$NEW_KEY_DIR" "$BACKUP_DIR"
    chmod 700 "$NEW_KEY_DIR" "$BACKUP_DIR"
}

# ─── Key Generation ───────────────────────────────────────────────────────────
generate_new_keypair() {
    info "Generating new ${KEY_TYPE} key pair → ${NEW_KEY_PATH}"

    if $DRY_RUN; then
        dry_run "ssh-keygen -t ${KEY_TYPE} -f ${NEW_KEY_PATH} -C 'rotated-$(date +%Y%m%d)' -N ''"
        return 0
    fi

    ssh-keygen -t "$KEY_TYPE" -f "$NEW_KEY_PATH" \
        -C "rotated-$(date +%Y%m%d)-${SSH_USER}" -N "" -q

    chmod 600 "$NEW_KEY_PATH"
    chmod 644 "${NEW_KEY_PATH}.pub"
    info "New public key fingerprint: $(ssh-keygen -lf "${NEW_KEY_PATH}.pub")"
}

backup_old_key() {
    if [[ -f "$OLD_KEY_PATH" ]]; then
        info "Backing up old key → ${BACKUP_DIR}/"
        $DRY_RUN || cp -p "$OLD_KEY_PATH" "${OLD_KEY_PATH}.pub" "$BACKUP_DIR/" 2>/dev/null || true
    fi
}

# ─── Per-Host Rotation ────────────────────────────────────────────────────────
rotate_host() {
    local host="$1"
    local status="SUCCESS"

    info "────────────────────────────────────"
    info "Processing: ${host}"

    # ── 1. Verify existing connectivity ──
    if ! ssh -o ConnectTimeout="$CONNECT_TIMEOUT" \
              -o StrictHostKeyChecking=no \
              -o BatchMode=yes \
              -i "$OLD_KEY_PATH" \
              -p "$SSH_PORT" \
              "${SSH_USER}@${host}" "echo ok" &>/dev/null; then
        warn "  Cannot connect to ${host} with old key — skipping."
        (( SKIPPED++ )) || true
        return 0
    fi

    if $DRY_RUN; then
        dry_run "ssh-copy-id -i ${NEW_KEY_PATH}.pub ${SSH_USER}@${host}"
        dry_run "Verify new key on ${host}"
        dry_run "Remove old key from ${host} authorized_keys"
        info "  [DRY RUN] ${host} — would rotate key."
        return 0
    fi

    # ── 2. Deploy new public key ──────────
    info "  Deploying new public key..."
    if ! ssh-copy-id -i "${NEW_KEY_PATH}.pub" \
            -o ConnectTimeout="$CONNECT_TIMEOUT" \
            -o StrictHostKeyChecking=no \
            -i "$OLD_KEY_PATH" \
            -p "$SSH_PORT" \
            "${SSH_USER}@${host}" &>/dev/null; then
        error "  Failed to deploy new key to ${host}"
        (( FAILED++ )) || true
        return 1
    fi

    # ── 3. Verify new key works ───────────
    info "  Verifying new key connectivity..."
    if ! ssh -o ConnectTimeout="$CONNECT_TIMEOUT" \
              -o StrictHostKeyChecking=no \
              -o BatchMode=yes \
              -i "$NEW_KEY_PATH" \
              -p "$SSH_PORT" \
              "${SSH_USER}@${host}" "echo ok" &>/dev/null; then
        error "  New key verification FAILED on ${host} — old key preserved!"
        (( FAILED++ )) || true
        return 1
    fi

    # ── 4. Remove old public key ──────────
    info "  Removing old public key from authorized_keys..."
    local old_pubkey
    old_pubkey=$(cat "${OLD_KEY_PATH}.pub")

    ssh -o BatchMode=yes \
        -i "$NEW_KEY_PATH" \
        -p "$SSH_PORT" \
        "${SSH_USER}@${host}" \
        "grep -v '${old_pubkey}' ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.tmp \
         && mv ~/.ssh/authorized_keys.tmp ~/.ssh/authorized_keys \
         && chmod 600 ~/.ssh/authorized_keys"

    info "  ✓ ${host} — rotation complete."
    (( SUCCESS++ )) || true
}

# ─── Replace local active key ─────────────────────────────────────────────────
finalize_local_key() {
    if $DRY_RUN; then
        dry_run "Replace ${OLD_KEY_PATH} with ${NEW_KEY_PATH}"
        return 0
    fi

    if (( FAILED == 0 )); then
        info "Replacing local active key with new key..."
        cp -p "$NEW_KEY_PATH" "$OLD_KEY_PATH"
        cp -p "${NEW_KEY_PATH}.pub" "${OLD_KEY_PATH}.pub"
        info "Local key updated."
    else
        warn "Some hosts failed — local key NOT replaced. Fix manually."
        warn "  New key:  ${NEW_KEY_PATH}"
        warn "  Old key:  ${OLD_KEY_PATH} (still active)"
    fi
}

# ─── Summary ──────────────────────────────────────────────────────────────────
print_summary() {
    info "════════════════════════════════════"
    info "Rotation Summary"
    info "  Succeeded : ${SUCCESS}"
    info "  Failed    : ${FAILED}"
    info "  Skipped   : ${SKIPPED}"
    info "  Log       : ${LOG_FILE}"
    info "  Backup    : ${BACKUP_DIR}"
    info "════════════════════════════════════"
    (( FAILED > 0 )) && exit 1 || exit 0
}

# ─── Argument Parsing ─────────────────────────────────────────────────────────
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --hosts)        HOSTS_FILE="$2";    shift 2 ;;
            --user)         SSH_USER="$2";      shift 2 ;;
            --old-key)      OLD_KEY_PATH="$2";  shift 2 ;;
            --key-type)     KEY_TYPE="$2";      shift 2 ;;
            --port)         SSH_PORT="$2";      shift 2 ;;
            --dry-run)      DRY_RUN=true;       shift   ;;
            --parallel)     PARALLEL=true;      shift   ;;
            --help)
                cat <<EOF
Usage: $0 --hosts <file> [OPTIONS]

Options:
  --hosts FILE      File with one hostname/IP per line (required)
  --user USER       SSH user to rotate keys for (default: deploy)
  --old-key PATH    Path to current private key (default: ~/.ssh/id_ed25519)
  --key-type TYPE   Key type: ed25519 or rsa (default: ed25519)
  --port PORT       SSH port (default: 22)
  --dry-run         Preview actions without making changes
  --parallel        Rotate hosts in parallel (requires GNU parallel)
  --help            Show this help
EOF
                exit 0 ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
    done

    if [[ -z "$HOSTS_FILE" ]]; then
        echo "Error: --hosts is required."
        exit 1
    fi

    if [[ ! -f "$HOSTS_FILE" ]]; then
        echo "Error: hosts file not found: $HOSTS_FILE"
        exit 1
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    parse_args "$@"
    setup_dirs

    info "SSH Key Rotation — $(date)"
    info "User: ${SSH_USER} | Key type: ${KEY_TYPE} | Port: ${SSH_PORT}"
    $DRY_RUN && warn "DRY RUN MODE — no changes will be made."

    generate_new_keypair
    backup_old_key

    # Read hosts, skip blank lines and comments
    mapfile -t HOSTS < <(grep -v '^\s*#' "$HOSTS_FILE" | grep -v '^\s*$')
    info "Hosts to rotate: ${#HOSTS[@]}"

    if $PARALLEL && command -v parallel &>/dev/null; then
        export -f rotate_host log info warn error dry_run
        export OLD_KEY_PATH NEW_KEY_PATH SSH_USER SSH_PORT CONNECT_TIMEOUT DRY_RUN LOG_FILE
        parallel --jobs 10 rotate_host ::: "${HOSTS[@]}"
    else
        for host in "${HOSTS[@]}"; do
            rotate_host "$host" || true
        done
    fi

    finalize_local_key
    print_summary
}

main "$@"
