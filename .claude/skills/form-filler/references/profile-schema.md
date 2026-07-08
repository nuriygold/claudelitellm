# Profile store schema

File: `/Users/claw/openclaw/workspace/form-profile.json`

The profile is the durable memory of the *user's* reusable form data. It grows every time a
form teaches a new field.

## Shape

```json
{
  "version": 1,
  "updated": "2026-07-08T00:00:00Z",
  "fields": {
    "<canonical_key>": {
      "value": "string | number | array",
      "source": "user | form:<slug> | mcp:<server> | inferred",
      "confidence": "high | medium | low",
      "sensitive": false,
      "updated": "ISO-8601"
    }
  },
  "history": [
    {
      "form": "<slug>",
      "url_or_app": "https://... or App name or file.pdf",
      "date": "ISO-8601",
      "driver": "cua-driver | chrome-systemevents | pdf",
      "fields_used": ["first_name", "email"],
      "fields_learned": ["dob", "address_line1"],
      "submitted": false
    }
  ]
}
```

## Rules

- **Canonical keys** are snake_case and singular in meaning. Resolve every form label to a key
  via `field-aliases.md`. Never create `dob` and `date_of_birth` as two keys.
- **confidence**: `high` = user typed it or confirmed it; `medium` = carried from a prior form
  unconfirmed; `low` = inferred/guessed. Never overwrite `high` with `low` silently — ask.
- **source**: where the value came from. `form:<slug>` means a form the user completed; that is
  the compounding-learning path.
- **sensitive**: true for SSN, card numbers, passwords, gov IDs, etc. Prefer NOT to store the raw
  value — store a marker (e.g. `"value": "<ask each time>"`, `sensitive: true`) unless the user
  explicitly says to persist it.
- **updated** timestamps let you flag stale data (e.g. an address older than a year) as
  `uncertain` and re-confirm.

## Suggested canonical keys (extend as needed)

Identity: `first_name`, `last_name`, `full_name`, `preferred_name`, `dob`, `gender`, `pronouns`
Contact: `email`, `email_business`, `phone`, `phone_mobile`
Address: `address_line1`, `address_line2`, `city`, `state`, `postal_code`, `country`
Org: `company_name`, `company_size`, `job_title`, `department`, `website`
Online: `linkedin`, `github`, `twitter`
Cloud/technical (this environment): `azure_subscription_id`, `azure_tenant_id`,
`azure_resource_group`, `azure_region`
Payment (sensitive — marker only unless told otherwise): `card_number`, `card_expiry`, `card_cvc`

Add new keys freely when a form introduces a genuinely new field; just register an alias for its
label so future forms resolve to the same key.
