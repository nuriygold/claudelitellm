# Device profiles

Per-device personalization for `bin/claudelitellm`. This app is meant to be
**over-personalized**: every machine that runs the launcher gets its own profile,
and you add a new one each time you add a device.

## Shipped profiles

| Device    | Machine       | Profile file           |
| --------- | ------------- | ---------------------- |
| `claw`    | Mac mini      | `devices/claw.env`     |
| `rudolph` | MacBook Air   | `devices/rudolph.env`  |
| `debby`   | oldmac (Debian) | `devices/debby.env`  |

## How the launcher picks a device

Resolution order (first match wins):

1. `CLAUDELITELLM_DEVICE` environment variable (explicit override).
2. Persisted choice file at `$CLAUDELITELLM_DEVICE_STATE`
   (default `~/.claude/claudelitellm-device`).
3. Hostname auto-detect (`scutil --get ComputerName`, falling back to `hostname`)
   matched against known device names and aliases.
4. Interactive prompt, if the terminal is attached. Your answer is saved to the
   persisted choice file so later runs auto-select it.
5. Built-in defaults, if nothing else resolves (non-interactive and no match).

Force a device for one run:

```bash
CLAUDELITELLM_DEVICE=rudolph bin/claudelitellm
```

Re-prompt / change the saved device:

```bash
rm ~/.claude/claudelitellm-device   # then run the launcher again
# or:
CLAUDELITELLM_DEVICE=claw bin/claudelitellm   # overwrites the saved choice
```

## What a profile can set

Profiles are sourced shell fragments. They set **defaults only** — anything you
export explicitly in your shell still wins. Supported variables:

| Variable                          | Purpose                                            |
| --------------------------------- | -------------------------------------------------- |
| `CLAUDELITELLM_DEVICE_LABEL`      | Friendly label shown at launch.                    |
| `CLAUDELITELLM_MODEL`             | Default model (e.g. `gpt-5.5`).                    |
| `CLAUDELITELLM_SMALL_FAST_MODEL`  | Default small/fast model (defaults to the model).  |
| `CLAUDELITELLM_REASONING_EFFORT`  | Default reasoning effort (`low`/`medium`/`high`).  |
| `CLAUDELITELLM_AUTOCOMPACT`       | `true`/`false` for `autoCompactEnabled`.           |
| `CLAUDELITELLM_REAL_LITELLM_URL`  | Per-device LiteLLM endpoint default.               |

## Adding a new device

1. Copy an existing profile:

   ```bash
   cp devices/rudolph.env devices/<name>.env
   ```

2. Edit the label and any defaults you want to differ.

3. (Optional) Add a hostname alias so it auto-detects. Edit the
   `device_from_hostname` case in `bin/claudelitellm`, mapping your computer name
   to `<name>`.

4. Select it once (`CLAUDELITELLM_DEVICE=<name> bin/claudelitellm`) to save the
   choice, or let the interactive prompt list it automatically.
