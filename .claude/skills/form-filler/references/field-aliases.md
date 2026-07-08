# Field label → canonical key aliases

Resolve any form label (case-insensitive, ignore punctuation/whitespace) to the canonical key.
This is what prevents the same real field from splintering into multiple profile keys. Extend
this list whenever a form uses a label not yet covered.

| Canonical key         | Aliases seen on forms |
|-----------------------|-----------------------|
| `first_name`          | first name, given name, forename, fname |
| `last_name`           | last name, surname, family name, lname |
| `full_name`           | name, full name, your name, legal name |
| `preferred_name`      | preferred name, nickname, goes by |
| `dob`                 | dob, date of birth, birthdate, birth date, d.o.b. |
| `gender`              | gender, sex |
| `pronouns`            | pronouns |
| `email`               | email, e-mail, email address, personal email |
| `email_business`      | business email, work email, company email, corporate email |
| `phone`               | phone, telephone, phone number |
| `phone_mobile`        | mobile, cell, mobile number, cell phone |
| `address_line1`       | address, street address, address line 1, address 1 |
| `address_line2`       | address line 2, apt, suite, unit |
| `city`                | city, town |
| `state`               | state, province, region, state/province |
| `postal_code`         | zip, zip code, postal code, postcode |
| `country`             | country |
| `company_name`        | company, company name, organization, organisation, employer, business name |
| `company_size`        | company size, number of employees, employee count, headcount |
| `job_title`           | title, job title, role, position |
| `department`          | department, team |
| `website`             | website, url, company website, homepage |
| `linkedin`            | linkedin, linkedin profile, linkedin url |
| `github`              | github, github profile, github url |
| `twitter`             | twitter, x, x/twitter, handle |
| `azure_subscription_id` | subscription id, azure subscription id, subscription |
| `azure_tenant_id`     | tenant id, azure tenant id, directory id |
| `azure_resource_group`| resource group, rg |
| `azure_region`        | region, location, azure region |
| `card_number`         | card number, credit card, card no |
| `card_expiry`         | expiry, expiration, exp date, mm/yy |
| `card_cvc`            | cvc, cvv, security code, card security code |

## Resolution algorithm

1. Lowercase the label, strip `*`, `:`, extra spaces.
2. Exact-match against the alias lists above.
3. If no exact match, match on the most specific contained phrase ("work email" → `email_business`
   before `email`).
4. If still ambiguous, DO NOT guess into an existing key — treat it as a new field, ask the user
   what it is, add a new canonical key + alias row here.
