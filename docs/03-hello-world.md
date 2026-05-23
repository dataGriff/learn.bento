---
title: "Hello World"
series: bento
order: 3
description: "The smallest possible Bento pipeline — generate a message and print it."
canonical_url: https://hungovercoders.com/training/bento/03-hello-world
---

# 03 — Hello World

> **Goal:** prove Bento works on your machine. The smallest possible pipeline.

**Prerequisites:** Bento installed — see [02 — Installation](02-installation.md).

> If you have the repo cloned: `make ex01`.

---

## What this lesson covers

| Concept | Where to look |
|---|---|
| `generate` input — synthesise messages on a timer | `config.yaml` → `input` |
| `mapping` — Bloblang to set the payload | `config.yaml` → `input.generate.mapping` |
| `stdout` output | `config.yaml` → `output` |

---

## The config

```yaml
input:
  generate:
    interval: 1s
    mapping: |
      root.greeting = "hello world"
      root.ts       = now()

output:
  stdout: {}
```

**`input.generate`** is a synthetic source — no external system needed. The `interval` controls how often it fires. The `mapping` is a Bloblang script that builds the message payload: `root.greeting` sets a string field, `now()` returns the current timestamp in RFC3339 format.

**`output.stdout`** writes each message as a line to standard output. The default codec is `lines`, so each message becomes one JSON line.

There are no `pipeline.processors` here — the message flows directly from input to output unchanged, except for what the generate mapping already set.

---

## Run it

Save the config above as `config.yaml`, then:

```bash
bento -c config.yaml
```

Or if you have the repo cloned, `make ex01` does this for you.

You should see one JSON line per second:

```json
{"greeting":"hello world","ts":"2026-05-11T10:00:00Z"}
{"greeting":"hello world","ts":"2026-05-11T10:00:01Z"}
```

`Ctrl-C` to stop.

---

## Things to try

1. Change the `interval` to `200ms` — observe the rate change.
2. Change the `mapping` to emit a random integer:
   ```yaml
   mapping: |
     root.greeting = "hello"
     root.n = random_int(min: 1, max: 100)
   ```
3. Pipe the output through `jq`:
   ```bash
   bento -c config.yaml | jq -c '.ts'
   ```
4. Lint the config without running it:
   ```bash
   bento lint config.yaml
   ```

---

## Why this matters

Every Bento pipeline — no matter how complex — is structurally identical to this one: **input → (processors) → output**. From here the only questions are: *which input? which processors? which output?*

Continue → [04 — Core Concepts](04-core-concepts.md)
