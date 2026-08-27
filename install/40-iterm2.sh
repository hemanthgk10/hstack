#!/usr/bin/env bash
# iTerm2 profile and app-level preferences.
#
# The profile ships as a Dynamic Profile, which iTerm2 reads from a directory
# and reloads without a restart. Overwriting the file is inherently idempotent
# and avoids poking at the preferences plist while iTerm2 has it open.
#
# Trade-off: Dynamic Profiles cannot be edited in the GUI. Tweak the profile in
# iTerm2's own Default profile instead, then run bin/hstack-iterm2-export to
# pull those changes back into this repo.

hs_head "iterm2"

DEST_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
hs_run mkdir -p "$DEST_DIR"

if [ -f "$DEST_DIR/hstack.json" ] && cmp -s "$HSTACK_ROOT/iterm2/hstack.json" "$DEST_DIR/hstack.json"; then
  hs_skip "current    hstack dynamic profile"
else
  hs_run cp "$HSTACK_ROOT/iterm2/hstack.json" "$DEST_DIR/hstack.json"
  hs_done "installed  hstack dynamic profile"
fi

# App-level preferences. These are not part of a profile.
hs_defaults com.googlecode.iterm2 NoSyncTipsDisabled bool 1
hs_defaults com.googlecode.iterm2 SoundForEsc bool 0
hs_defaults com.googlecode.iterm2 HapticFeedbackForEsc bool 0
hs_defaults com.googlecode.iterm2 VisualIndicatorForEsc bool 0
hs_defaults com.googlecode.iterm2 PreventEscapeSequenceFromClearingHistory bool 0
hs_defaults com.googlecode.iterm2 SUSendProfileInfo bool 0
hs_defaults com.googlecode.iterm2 AppleWindowTabbingMode string manual

# Three-finger swipe moves between windows. defaults write cannot merge a
# dictionary, so this is written whole via PlistBuddy-free plutil replace.
if [ "$HSTACK_DRY_RUN" = 1 ]; then
  hs_log "DRY  set PointerActions (three-finger swipe -> prev/next window)"
else
  current="$(defaults read com.googlecode.iterm2 PointerActions 2>/dev/null || true)"
  case "$current" in
    *ThreeFingerSwipeDown*) hs_skip "default    PointerActions" ;;
    *)
      defaults write com.googlecode.iterm2 PointerActions -dict-add \
        "Gesture,ThreeFingerSwipeDown,," '{Action = kPrevWindowPointerAction;}' \
        "Gesture,ThreeFingerSwipeUp,," '{Action = kNextWindowPointerAction;}'
      hs_ok "default    PointerActions"
      ;;
  esac
fi

hs_log "select the 'hstack' profile in iTerm2 > Settings > Profiles"
