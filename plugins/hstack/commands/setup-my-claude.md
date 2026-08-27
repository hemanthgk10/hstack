---
description: Configure Claude Code from the hstack repo — plugins, settings, preferences.
allowed-tools:
  - Bash
  - Read
---

Run the hstack Claude Code setup and report what changed.

1. Find the hstack repo. It is the directory containing this plugin, two levels
   up from `plugins/hstack`. If `claude plugin marketplace list` shows an
   `hstack` marketplace with a directory source, use that path. Otherwise ask
   where the clone is.

2. Run `bin/hstack-setup-claude` from that directory. Pass `--dry-run` first if
   the user asked to preview.

3. Report the result as a short summary: which marketplaces and plugins were
   newly installed, which were already present, whether settings and
   preferences changed. Do not paste the raw output unless something failed.

4. If any plugin failed to install, say which one and why. Do not retry
   silently.

5. Tell the user to restart Claude Code if anything was installed. Plugin
   changes do not apply to the session that installed them.

The script is idempotent, so running it again is always safe.
