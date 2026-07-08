# The capability lesson (why this skill exists)

This is the distilled transcript that motivated `/form-filler`. The *content* of the
form (an Azure content-filter exception) does not matter here — only the **process**
does. Read it for the failure mode and the correct posture.

## What happened

A user asked an agent to fill and submit a web form. The agent responded, repeatedly:

> "I don't have a browser I can drive... What I have is WebFetch, which is read-only...
> It can't sign in, can't fill fields, can't click submit."

It said this **four times** across the conversation. It was wrong every time. On the same
Mac it had:

- `screencapture` — to see any window as an image and Read it (its actual eyes on the GUI).
- `osascript` / System Events — to activate an app and send real keystrokes into fields.
- A running Chrome with the form already loaded.

The moment it finally tried (`screencapture` → Read the PNG → it could read Question 8,
the attestation checkboxes, every field), it discovered it had been capable the entire time.
The user even had to prompt it: *"but you have browser tools... you can totally do it."*

## The lesson, as rules

1. **Capability is proven by a check, not assumed absent.** "I can't" is a claim that
   requires evidence. Run the smallest real test (`command -v screencapture`, `pgrep Chrome`,
   try one `osascript` keystroke) before reporting a limitation.
2. **You have eyes.** A screenshot + Read is full GUI vision. Not having a named
   "browser tool" does not mean you can't see or drive a browser.
3. **You have hands.** System Events keystrokes and `key code` navigation type into and move
   between real fields. cua-driver does it without stealing focus for native apps.
4. **Resourceful by default.** When the obvious tool is missing, the job isn't "report a
   blocker" — it's "find the other path." There is almost always another path on a real Mac.
5. **The user believes in your capability. Earn it — don't talk yourself out of it.**

## The things the agent DID get right (keep these)

Even while under-selling itself, it correctly:

- **Read the form before acting** and caught that the open tab was the *wrong* form
  (abuse-monitoring vs. content-filtering) before wasting a submission.
- **Caught the eligibility trap at Q8** ("personal email addresses will be DENIED") and refused
  to submit a guaranteed-rejected / dishonest application.
- **Refused to tick legal attestation checkboxes** on the user's behalf and left the final
  submit to the human.
- **Cleaned up every screenshot** it wrote to `/tmp`.

So the correct synthesis is: **maximally capable at seeing, mapping, and filling — with a hard
stop at legal attestation, final submit, and dishonest/ineligible input.** That balance is the
spec encoded in `SKILL.md`.
