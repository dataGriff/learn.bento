# 01 — Hello world

> **Goal:** prove Bento works on your machine. The smallest possible pipeline.

---

## What's new

| Concept | Where to look |
|---|---|
| `generate` input — synthesise messages on a timer | `config.yaml` → `input` |
| `mapping` — Bloblang to set the payload | `config.yaml` → `input.generate.mapping` |
| `stdout` output | `config.yaml` → `output` |

---

## Run it

```bash
make ex01
# (or)  bento -c examples/01-hello-world/config.yaml
```

You should see one JSON line per second:

```json
{"greeting":"hello world","ts":"2026-05-11T10:00:00Z"}
{"greeting":"hello world","ts":"2026-05-11T10:00:01Z"}
...
```

`Ctrl-C` to stop.

---

## Things to try

1. Change the `interval` to `200ms` — observe the rate change.
2. Change the `mapping` to emit a counter:
   ```yaml
   mapping: |
     root.greeting = "hello"
     root.n = random_int(min: 1, max: 100)
   ```
3. Pipe through `jq`:
   ```bash
   bento -c examples/01-hello-world/config.yaml | jq -c '.n'
   ```
4. Lint the config:
   ```bash
   bento lint examples/01-hello-world/config.yaml
   ```

---

## Why this matters

Every Bento pipeline — no matter how complex — is structurally identical to
this one. **input → (processors) → output**. From here the only questions
are: *which input? which processors? which output?*

Next → [02 — File to file](../02-file-to-file/)
