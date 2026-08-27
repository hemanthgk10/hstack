#!/usr/bin/env bash
# Xcode Command Line Tools and Homebrew. Everything else depends on these.

hs_head "preflight"

[ "$(uname -s)" = "Darwin" ] || hs_die "hstack targets macOS. Found: $(uname -s)"
case "$(uname -m)" in
  arm64) : ;;
  *) hs_warn "built and tested on Apple silicon; $(uname -m) may need Brewfile edits" ;;
esac

# Xcode CLT — git and cc come from here.
if xcode-select -p >/dev/null 2>&1; then
  hs_skip "present    Xcode Command Line Tools"
else
  hs_log "installing Xcode Command Line Tools (a GUI dialog will open)"
  hs_run xcode-select --install || true
  hs_die "Finish the Xcode Command Line Tools install, then re-run this script."
fi

# Homebrew
if hs_have brew; then
  hs_skip "present    homebrew ($(brew --version | head -1))"
else
  hs_log "installing homebrew"
  hs_sh '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
fi

# Put brew on PATH for the rest of this run regardless of shell config.
for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [ -x "$p" ] && eval "$("$p" shellenv)" && break
done
hs_have brew || [ "$HSTACK_DRY_RUN" = 1 ] || hs_die "brew still not on PATH"
