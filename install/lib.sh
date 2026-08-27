#!/usr/bin/env bash
# hstack shared helpers.
#
# CONTRACT: every filesystem mutation in this repo goes through a helper here.
# No module calls ln, cp, mkdir, rm, curl, or defaults write directly. That is
# what makes --dry-run honest and re-runs safe.

HSTACK_DRY_RUN="${HSTACK_DRY_RUN:-0}"
HSTACK_QUIET="${HSTACK_QUIET:-0}"
HSTACK_BACKUP_DIR="${HSTACK_BACKUP_DIR:-}"

# ── output ──────────────────────────────────────────────────────────────────
_hs_c() { if [ -t 1 ]; then printf '\033[%sm' "$1"; fi; }
hs_log()  { [ "$HSTACK_QUIET" = 1 ] && return 0; printf '%s  %s%s\n' "$(_hs_c 34)··$(_hs_c 0)" "$*" ""; }
hs_ok()   { [ "$HSTACK_QUIET" = 1 ] && return 0; printf '%s  %s\n' "$(_hs_c 32)ok$(_hs_c 0)" "$*"; }
hs_skip() { [ "$HSTACK_QUIET" = 1 ] && return 0; printf '%s  %s\n' "$(_hs_c 90)--$(_hs_c 0)" "$*"; }
hs_warn() { printf '%s  %s\n' "$(_hs_c 33)!!$(_hs_c 0)" "$*" >&2; }
hs_die()  { printf '%s  %s\n' "$(_hs_c 31)xx$(_hs_c 0)" "$*" >&2; exit 1; }
hs_head() { [ "$HSTACK_QUIET" = 1 ] && return 0; printf '\n%s%s%s\n' "$(_hs_c '1;36')" "$*" "$(_hs_c 0)"; }
# hs_done — like hs_ok but silent under --dry-run, so we never claim to have
# done something the dry run did not do.
hs_done() { [ "$HSTACK_DRY_RUN" = 1 ] && return 0; hs_ok "$@"; }

# ── the single mutation choke point ─────────────────────────────────────────
# hs_run <cmd> [args...]  — echo under --dry-run, execute otherwise.
hs_run() {
  if [ "$HSTACK_DRY_RUN" = 1 ]; then
    printf '%s  %s\n' "$(_hs_c 35)DRY$(_hs_c 0)" "$*"
    return 0
  fi
  "$@"
}

# hs_sh <shell-string> — same, for pipelines/redirects that need a shell.
hs_sh() {
  if [ "$HSTACK_DRY_RUN" = 1 ]; then
    printf '%s  %s\n' "$(_hs_c 35)DRY$(_hs_c 0)" "sh -c: $1"
    return 0
  fi
  bash -c "$1"
}

# hs_write <dest> — read content from stdin, write it only if it differs.
# Idempotent by content, so re-runs report "unchanged" instead of rewriting.
hs_write() {
  local dest="$1" tmp
  tmp="$(mktemp)"
  cat > "$tmp"
  if [ -f "$dest" ] && cmp -s "$tmp" "$dest"; then
    rm -f "$tmp"; hs_skip "unchanged  $dest"; return 0
  fi
  if [ "$HSTACK_DRY_RUN" = 1 ]; then
    printf '%s  %s\n' "$(_hs_c 35)DRY$(_hs_c 0)" "write $dest ($(wc -l < "$tmp" | tr -d ' ') lines)"
    rm -f "$tmp"; return 0
  fi
  [ -f "$dest" ] && hs_backup "$dest"
  mkdir -p "$(dirname "$dest")"
  mv "$tmp" "$dest"
  hs_ok "wrote      $dest"
}

# ── backups ─────────────────────────────────────────────────────────────────
# One timestamped directory per run, created lazily so a fully idempotent
# re-run leaves no empty backup dir behind.
# NOTE: this must NOT be called through $(...). Command substitution runs in a
# subshell, so the assignment to HSTACK_BACKUP_DIR would be discarded and every
# call would mint a fresh timestamp — one backup directory per file instead of
# one per run.
_hs_backup_dir() {
  if [ -z "$HSTACK_BACKUP_DIR" ]; then
    HSTACK_BACKUP_DIR="$HOME/.hstack-backup/$(date +%Y%m%d-%H%M%S)"
    export HSTACK_BACKUP_DIR
  fi
  [ -d "$HSTACK_BACKUP_DIR" ] || mkdir -p "$HSTACK_BACKUP_DIR"
}

# hs_backup <path> — move a real file/dir aside. No-op for symlinks and
# missing paths, which is what keeps re-runs from stacking backups.
hs_backup() {
  local p="$1"
  [ -e "$p" ] || return 0
  [ -L "$p" ] && return 0
  if [ "$HSTACK_DRY_RUN" = 1 ]; then
    printf '%s  %s\n' "$(_hs_c 35)DRY$(_hs_c 0)" "backup $p -> ~/.hstack-backup/<ts>/"
    return 0
  fi
  _hs_backup_dir
  mv "$p" "$HSTACK_BACKUP_DIR/$(basename "$p")"
  hs_log "backed up  $p -> $HSTACK_BACKUP_DIR/"
}

# ── linking ─────────────────────────────────────────────────────────────────
# hs_link <src> <dst> — symlink, backing up any real file already there.
hs_link() {
  local src="$1" dst="$2"
  [ -e "$src" ] || hs_die "hs_link: source missing: $src"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    hs_skip "linked     $dst"; return 0
  fi
  hs_backup "$dst"
  hs_run mkdir -p "$(dirname "$dst")"
  hs_run ln -sfn "$src" "$dst"
  hs_done "linked     $dst -> $src"
}

# hs_copy_if_absent <src> <dst> — for files a tool rewrites itself (gh config).
hs_copy_if_absent() {
  local src="$1" dst="$2"
  if [ -e "$dst" ]; then hs_skip "present    $dst"; return 0; fi
  hs_run mkdir -p "$(dirname "$dst")"
  hs_run cp "$src" "$dst"
  hs_done "copied     $dst"
}

# ── git ─────────────────────────────────────────────────────────────────────
# hs_clone_or_pull <url> <dir> [--depth N]
hs_clone_or_pull() {
  local url="$1" dir="$2"; shift 2
  if [ -d "$dir/.git" ]; then
    hs_log "updating   $dir"
    hs_run git -C "$dir" pull --ff-only --quiet || hs_warn "pull failed (local changes?): $dir"
    hs_done "current    $dir"
  elif [ -e "$dir" ]; then
    hs_warn "exists but is not a git repo, leaving alone: $dir"
  else
    hs_run git clone --quiet "$@" "$url" "$dir"
    hs_done "cloned     $dir"
  fi
}

# ── marker blocks ───────────────────────────────────────────────────────────
# hs_marker_block <file> <name> <<< "content"
# Replaces an existing block instead of appending, so re-runs never duplicate.
# <comment> defaults to '#'; pass a third arg for other comment syntaxes.
hs_marker_block() {
  local file="$1" name="$2" cmt="${3:-#}"
  local begin="$cmt >>> hstack:$name >>>"
  local end="$cmt <<< hstack:$name <<<"
  local body tmp
  body="$(cat)"

  tmp="$(mktemp)"
  if [ -f "$file" ] && grep -qF "$begin" "$file"; then
    # Replace in place. Removing and re-appending would reorder blocks on every
    # run when a file holds more than one, so the file would never stabilize.
    awk -v b="$begin" -v e="$end" -v body="$body" '
      $0 == b { print; print body; skip = 1; next }
      $0 == e { print; skip = 0; next }
      !skip   { print }
    ' "$file" > "$tmp"
  else
    [ -f "$file" ] && cat "$file" > "$tmp"
    # Compute the separator before opening $tmp for append, so the size test
    # and the write are not in the same pipeline.
    local sep=""
    [ -s "$tmp" ] && sep=$'\n'
    printf '%s%s\n%s\n%s\n' "$sep" "$begin" "$body" "$end" >> "$tmp"
  fi

  if [ -f "$file" ] && cmp -s "$tmp" "$file"; then
    rm -f "$tmp"; hs_skip "unchanged  $file [$name]"; return 0
  fi
  if [ "$HSTACK_DRY_RUN" = 1 ]; then
    printf '%s  %s\n' "$(_hs_c 35)DRY$(_hs_c 0)" "update block '$name' in $file"
    rm -f "$tmp"; return 0
  fi
  mkdir -p "$(dirname "$file")"
  mv "$tmp" "$file"
  hs_ok "block      $file [$name]"
}

# ── misc ────────────────────────────────────────────────────────────────────
hs_have() { command -v "$1" >/dev/null 2>&1; }

# hs_fetch <url> <dest> — download only when the destination is missing.
hs_fetch() {
  local url="$1" dest="$2"
  if [ -e "$dest" ]; then hs_skip "present    $dest"; return 0; fi
  hs_run mkdir -p "$(dirname "$dest")"
  hs_run curl -fsSL "$url" -o "$dest" || hs_die "download failed: $url"
  hs_done "fetched    $dest"
}

# hs_defaults <domain> <key> <type> <value> — write only on change.
hs_defaults() {
  local domain="$1" key="$2" type="$3" value="$4" cur
  cur="$(defaults read "$domain" "$key" 2>/dev/null || true)"
  if [ "$cur" = "$value" ]; then hs_skip "default    $key = $value"; return 0; fi
  hs_run defaults write "$domain" "$key" "-$type" "$value"
  hs_done "default    $key = $value"
}
