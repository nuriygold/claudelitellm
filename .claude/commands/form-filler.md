---
description: Fill out a form (web, native macOS, or PDF) end-to-end and remember every field for next time
disable-model-invocation: false
---

Run the **form-filler** skill (`/Users/aaliyathewarrior/.claude/skills/form-filler/SKILL.md`) to complete the form the user is pointing at.

Operate from its core conviction: **you are already capable.** Before ever telling the user you can't drive a form, prove it with a real check (`command -v screencapture`, `pgrep -x "Google Chrome"`, one `osascript` keystroke). You see via screenshots and type via System Events / the cua-driver skill.

Follow the skill's fill loop exactly:
1. Identify the target and pick the driver (cua-driver for native apps; Chrome + `screencapture` + System Events for web; headless lib for PDFs).
2. Load the profile at `/Users/aaliyathewarrior/openclaw/workspace/form-profile.json`.
3. Read the WHOLE form before typing anything.
4. Map each field to a canonical key via `references/field-aliases.md`.
5. Auto-fill everything already known from the profile.
6. Batch-ask the user for only the fields you genuinely don't have.
7. Verify the filled form by re-reading it.
8. **Learn:** write every new/corrected value back to the profile so the next form asks less.
9. Stop at the human-only lines: final submit, legal/attestation checkboxes, and any dishonest or ineligible input — surface these, never do them silently.

Clean up any screenshots you write to `/tmp`. Report what was auto-filled, what you asked for, what was newly learned, and what's left for the user to click.

$ARGUMENTS
