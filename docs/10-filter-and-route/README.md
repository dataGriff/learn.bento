---
title: "Filter and Route"
series: bento
order: 10
description: "Content-based routing — same input, different destinations depending on the message."
canonical_url: https://hungovercoders.com/training/bento/10-filter-and-route
---

# 10 — Filter and Route

> **Goal:** content-based routing — same input, different destinations depending on the message.

**Prerequisites:** Bento installed — see [02 — Installation](02-installation.md).

---

## What this lesson covers

| Concept | Where to look |
|---|---|
| `switch` **processor** — conditional sub-pipelines | `config.yaml` → `pipeline` |
| `switch` **output** — route to different sinks | `config.yaml` → `output` |
| `check:` Bloblang predicates | `config.yaml` |
| `drop` output for explicit discard | `config.yaml` |

---

## The config

```yaml
input:
  file:
    paths:
      - ./data/events.jsonl
    codec: lines

pipeline:
  processors:
    - mapping: |
        root = if this.items.length() == 0 { deleted() } else { this }
        root.total = this.items.map_each(i -> i.qty * i.price).sum()
        root.tier  = match {
          root.total >= 200 => "gold",
          root.total >= 50  => "silver",
          _                 => "bronze",
        }

    - switch:
        - check: this.tier == "gold"
          processors:
            - mapping: 'meta priority = "high"'
        - check: this.tier == "silver"
          processors:
            - mapping: 'meta priority = "normal"'
        - processors:
            - mapping: 'meta priority = "low"'

output:
  switch:
    cases:
      - check: this.tier == "gold"
        output:
          file:
            path:  ./out/gold.jsonl
            codec: lines
      - check: this.tier == "silver"
        output:
          file:
            path:  ./out/silver.jsonl
            codec: lines
      - output:
          file:
            path:  ./out/bronze.jsonl
            codec: lines
```

**Two separate `switch` primitives** do different jobs:

The **`switch` processor** (in `pipeline.processors[]`) runs different sub-pipelines on the *same* message based on a condition. Here it sets a `priority` metadata field per tier. The third case has no `check:` — it's the default branch, matching everything that fell through.

The **`switch` output** routes the message to a *different sink* based on a condition. Cases are evaluated top-to-bottom; the first matching case wins. A case with no `check:` is the default. Unlike a `broker` fan-out, `switch` sends the message to exactly *one* output.

The `check:` value in each case is a Bloblang expression returning a boolean. You can use the full Bloblang expression language here, including `meta()` to inspect metadata.

---

## Run it

```bash
make ex05
```

> Don't have the repo? `git clone https://github.com/hungovercoders/learn.bento.git`

Three output files appear:

```bash
ls ./out/
# gold.jsonl  silver.jsonl  bronze.jsonl
```

---

## The two switches, side by side

| | `switch` processor | `switch` output |
|---|---|---|
| Lives in | `pipeline.processors[]` | `output:` |
| Effect | Run different processors on the same message | Send the message to a different output |
| Use when | "Do *X* if the message looks like *Y*" | "Write to *X* if the message looks like *Y*" |

You'll often use both together: a switch processor to mark or normalise per class, then a switch output to fan out to per-class sinks.

---

## Things to try

1. Add a `default` case to the output switch that writes to `unknown.jsonl` — useful for catching unclassified messages.
2. Move the `processed_at` stamp to a common mapping placed *before* the switch processor — observe how processors share state via metadata.
3. Add `fallthrough: true` to a case so a message can be matched by *more than one* output — useful for audit fan-out.
4. Replace the bronze case's output with `drop: {}` — Bento silently discards bronze events.

---

## Why this matters

Real pipelines almost always need different code paths for different message shapes — orders vs refunds, success vs failure, customer vs admin. The switch primitives combined with Bloblang predicates handle 99% of routing requirements without needing a programming language.

