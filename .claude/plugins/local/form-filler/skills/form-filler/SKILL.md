---
name: form-filler
description: Fill out forms (web forms in a browser, native macOS app forms, or PDFs) end-to-end, then remember every field value in a persistent profile so each new form auto-fills from what earlier forms taught it. Use when the user says "fill out this form", "/form-filler", "complete this application", "fill in the intake/registration/signup", or points you at a form and asks you to complete it. Progressive: a DOB entered on form #2 is known automatically on form #3.
version: 1.0.0
---

# /form-filler — Capable, learning form completion

You CAN fill forms. This skill exists because an agent once insisted, four times
in a row, that it "had no browser tools" and could only read pages — while sitting
on a Mac with `screencapture`, Chrome, and `osascript` System Events keystrokes, i.e.
everything needed to see and drive a real form. It was capable the whole time and
didn't know it. **Never repeat that.** Before you tell a user you can't do something,
you must prove it by checking your actual tools (see the capability precheck below).
The default posture is: *I can see the screen, I can move the pointer of automation,
I can type — let me find the path.*

Read `references/capability-lesson.md` once before your first fill so the failure
mode is concrete.

## The one-paragraph mental model

A form is a set of `(label → value)` slots. You have a **profile store** of values you
already know. To fill a form: read the form, map each slot to a known profile field,
type the ones you know, ask the user only for the ones you genuinely don't, then —
this is the point of the skill — **write the newly-learned values back to the profile**
so the next form needs fewer questions. Over time the profile converges and forms fill
themselves.

## Profile store

Path: `/Users/aaliyathewarrior/openclaw/workspace/form-profile.json`
Schema and canonical field keys: `references/profile-schema.md`
Label→key aliases (so "Date of Birth", "DOB", "Birthdate" all resolve to `dob`):
`references/field-aliases.md`

If the file does not exist, create it from the schema with an empty `fields` object.
It already ships as an empty scaffold, so normally you just read and update it.

Rules:
- One canonical snake_case key per real-world field. Resolve labels through the alias map.
- Every field carries `value`, `source`, `confidence`, `updated`. Never silently overwrite
  a `high`-confidence value with a `low`-confidence one — if they conflict, ask.
- Append a `history` entry per form so you can explain provenance later.
- Treat the store as durable memory of the *user's data*, not of one conversation.

## The fill loop

Run this loop. Do not skip the read-before-type and verify-after-type steps — those are
exactly what turn "I think I typed it" into "I confirmed it landed."

1. **Identify the target.** Web form in a browser? Native macOS app? PDF? Pick the driver
   (next section). Get the URL/app/file.
2. **Capability precheck** (only the first time in a session, or when unsure) — see below.
3. **Load the profile.** Read `form-profile.json` into working memory.
4. **Read the whole form first.** Capture/snapshot and read *every* field top to bottom
   before typing anything. Note: required (*) fields, field types (text, dropdown, radio,
   checkbox, date), and any legal/attestation checkboxes.
5. **Map slots → keys.** For each form field, resolve its label to a canonical key via the
   alias map. Build three lists: `known` (in profile, confident), `uncertain` (in profile but
   low confidence or stale), `missing` (not in profile).
6. **Fill the `known` fields.** Type/select them via the driver. Re-read after each cluster to
   verify the value landed (values can fail silently on custom widgets).
7. **Resolve `uncertain` + `missing` in ONE batched question.** Don't dribble out one prompt
   per field. List everything you need, offer the profile's best guess where you have one, and
   let the user answer in a single message. Then fill those too.
8. **Verify the filled form.** Re-read the full form. Confirm every required field is populated
   and correct. Report anything still blank.
9. **Learn.** Write every newly-collected or user-corrected value back to the profile with
   `source` = `form:<slug>` and appropriate confidence. Add a `history` entry.
10. **Stop at the submit line.** See "What you must NOT auto-do" — you fill; the user commits.

## Drivers — how you actually touch the form

Prefer the driver that keeps the user's foreground app untouched.

### A. Native macOS forms → `cua-driver` skill (preferred, foreground-safe)
If the form is in a native macOS app, use the `cua-driver` skill's snapshot→act→re-snapshot
loop. It fills by accessibility element index without stealing focus or warping the cursor.
This is the cleanest path and should be your first choice for native apps.

### B. Web forms → Chrome + screenshot + System Events (the transcript's real path)
This is what actually works for browser forms on this Mac and is proven in
`references/capability-lesson.md`:

- **See the form:** `screencapture -x /tmp/ff_$$.png` then Read the PNG. This is your eyes.
  A ~700KB+ file means it captured real content, not a black frame.
- **Bring the form forward when you need to type into it:**
  `osascript -e 'tell application "Google Chrome" to activate'`. (Note: this *does* foreground
  Chrome — only do it when the task is explicitly a foreground GUI task the user asked for. For
  background work, prefer cua-driver or a driver that doesn't steal focus.)
- **Focus a field and type:** use System Events keystrokes, e.g.
  `osascript -e 'tell application "System Events" to keystroke "Jane"'`, and
  `key code` for Tab (`48`), Return (`36`), arrows, etc., to move between fields. Read a fresh
  screenshot after each field to confirm.
- **Scroll to see/reach lower fields:** `key code 121` (Page Down) / `123`–`126` arrows, or
  scroll, then re-screenshot.
- **Clean up every screenshot** you write to `/tmp` when done (`rm -f /tmp/ff_*.png`). Leave no
  scratch files.

### C. PDFs → fill programmatically
For fillable PDFs, prefer a headless path (e.g. a Python lib like `pypdf`/`pdfrw`, or `pdftk`)
so you write field values directly rather than screenshotting. Read the PDF's field names first,
map to profile keys, write, and save a copy (never overwrite the original in place without a backup).

## Capability precheck — do this instead of claiming you can't

Before saying "I don't have the tools to do X," run the smallest real test:
- Web form? Confirm: does `screencapture` exist (`command -v screencapture`)? Is a browser
  running (`pgrep -x "Google Chrome"` / Safari)? Can `osascript` run? If yes to these, you can
  drive it — the transcript proves it.
- Native app? Is `cua-driver` available? (It's a listed skill here — yes.)
- Only after a concrete check comes back negative do you report a limitation, and then you name
  the *specific* missing capability and the *next* thing that would unblock it — never a vague
  "I can't."

The failure to avoid, verbatim from the lesson: repeating "I only have read-only WebFetch" when
`screencapture` + `osascript` were right there. Check first. You are resourceful by default.

## What you must NOT auto-do (the human-in-the-loop line)

Being maximally capable does not mean submitting things in the user's name. Fill everything up to
these lines, then hand back for one action:
- **Final Submit / Send** on any form that transmits to a third party — fill it, verify it, then
  let the user click submit (or explicitly confirm "submit it"). This is outward-facing and often
  irreversible.
- **Legal attestation / "I agree" / consent checkboxes** — never tick these on the user's behalf.
  They are the user certifying something. Surface them, explain what each asserts, and leave the
  click to them.
- **Sensitive data** (SSN, full card numbers, passwords, government IDs) — do not pull these into
  the profile or type them without explicit, per-use confirmation. Store a reference/marker, not
  the raw secret, unless the user directs otherwise.
- **Eligibility honesty** — if the form itself says an input will be rejected (e.g. "personal email
  addresses will be DENIED") or the truthful values don't fit, say so *before* filling. Don't
  submit a guaranteed-rejected or dishonest application. (The transcript caught exactly this at Q8.)

## Progressive learning — the whole point

Worked example of the intended behavior:
- **Form #1** (signup): user gives name + email. You fill, verify, and write `first_name`,
  `last_name`, `email` to the profile.
- **Form #2** (intake): asks name, email, **DOB**, address. Name+email auto-fill from the profile;
  you ask only for DOB + address; you fill; then you write `dob` and `address_*` back.
- **Form #3** (application): asks name, email, DOB, phone. Name, email, and **DOB now auto-fill** —
  you only ask for phone. Each form the question list shrinks.

State this compounding to the user when it happens ("DOB carried over from the intake form"). That
visible payoff is why the profile exists.

## Reporting

After a fill, report concisely:
- form identified + driver used
- fields auto-filled from profile (with where each came from)
- fields you had to ask for
- fields newly learned and saved to the profile
- verification result (all required populated? anything blank?)
- what's left for the user (submit click, attestation boxes)
- cleanup done (screenshots removed)

## Guardrails recap
- Read before typing; verify after typing. No blind fills.
- Canonical keys + alias resolution; never fork the same field into two keys.
- Don't overwrite high-confidence data with a guess.
- Don't submit, don't attest, don't handle raw secrets without explicit go-ahead.
- Clean up scratch files.
- If a real check proves a capability is missing, say precisely what's missing — otherwise, find
  the path and do it.
