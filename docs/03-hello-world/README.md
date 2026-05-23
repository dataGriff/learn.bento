---
title: "Hello World"
series: bento
order: 4
description: "The smallest possible Bento pipeline — generate a message and print it."
canonical_url: https://hungovercoders.com/training/bento/03-hello-world
---

# 04 — Hello World

The smallest possible Bento pipeline. No external system, no network, no faff. Just a fake message generator and a terminal. The goal is to prove Bento works on your machine and to clock the three-part shape that every pipeline in this series will share.

**Prerequisites:** Bento installed — see [02 — Installation](../02-installation/).

---

## Cracking open the first pipeline

Every Bento pipeline has at least two sections — an `input` and an `output`. Here's ours:

```yaml
input:
  generate:
    interval: 1s
    mapping: |
      root.brewery = "Tiny Rebel"
      root.message = "Hello fellow hungovercoder"
      root.ts      = now()

output:
  stdout: {}
```

Five things to clock before we run it:

- **`input.generate`** is Bento's built-in synthetic source — no external system needed. Perfect for tutorials and load testing.
- **`interval: 1s`** controls how often it fires. Change it to `200ms` later and watch it go.
- **`mapping`** is a Bloblang script that builds the message payload. `root.brewery = "Tiny Rebel"` sets a string field; `now()` returns the current timestamp in RFC3339 format. We'll spend a lot of time in Bloblang across this series.
- **`output.stdout`** writes each message as one JSON line to the terminal. No config needed.
- There are **no `pipeline.processors`** here — the message flows straight from input to output. That's fine. Most pipelines add processors; this one doesn't need them yet.

---

## Giving the beer a pour — running it

If you've cloned the repo (see [03 — Tutorial Setup](../03-tutorial-setup/)):

```bash
cd docs/03-hello-world
bento -c config.yaml
```

Or save the config above as `config.yaml` anywhere and run:

```bash
bento -c config.yaml
```

You should see one JSON line per second, like a polite British robot:

```json
{"brewery":"Tiny Rebel","message":"Hello fellow hungovercoder","ts":"2026-05-11T10:00:00Z"}
{"brewery":"Tiny Rebel","message":"Hello fellow hungovercoder","ts":"2026-05-11T10:00:01Z"}
```

`Ctrl-C` to stop.

I'll be honest — first time I ran this I thought it had failed because it was over so quickly. Nope, that's just how fast a static binary with no JVM warm-up time actually is.

---

## Have a go

1. Change `interval` to `200ms` — watch it scroll.
2. Add a random integer to the payload:
   ```yaml
   mapping: |
     root.brewery = "Tiny Rebel"
     root.pints   = random_int(min: 1, max: 10)
     root.ts      = now()
   ```
3. Pipe it through `jq`:
   ```bash
   bento -c config.yaml | jq -c '.brewery'
   ```
4. Lint the config without running it:
   ```bash
   bento lint config.yaml
   ```

---

## Why this shape matters

Every Bento pipeline — no matter how many processors, outputs, or WarpStream topics it involves — is structurally identical to this one: **input → (processors) → output**. From here the only questions are which input, which processors, and which output. The rest of this series is just filling in those blanks.

Well done on your first Bento pipeline, fellow hungovercoder.
