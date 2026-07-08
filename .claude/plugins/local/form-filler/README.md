# form-filler

Capable, learning form completion for Claude Code.

Fills forms (web in a browser, native macOS app, or PDF) end-to-end and remembers every
field in a persistent profile, so each new form auto-fills from what earlier forms taught it
— a DOB entered once is known on every form after.

**Core ethos:** the agent is already capable. It verifies its real tools before ever claiming
it can't (screenshots are its eyes, System Events / cua-driver are its hands), and stops only
at the lines a human must own: final submit, legal attestations, and dishonest/ineligible input.

## Slash command

`/form-filler` — point it at a form and it runs the fill loop.

## Contents

- `commands/form-filler.md` — the slash command
- `skills/form-filler/` — the skill: fill loop, drivers, guardrails, and references
  (`capability-lesson.md`, `profile-schema.md`, `field-aliases.md`)

## Profile store

`/Users/claw/openclaw/workspace/form-profile.json` — the durable, growing record of the user's
reusable form data. Canonical snake_case keys, label→key aliasing, confidence + provenance per field.

## Install (as a plugin)

```
/plugin marketplace add /Users/claw/.claude/plugins/local
/plugin install form-filler@local-fleet
```

The skill also works standalone from `/Users/claw/.claude/skills/form-filler/` after a skills reload.
