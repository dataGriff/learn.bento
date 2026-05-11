# 05 — Filter & route

> **Goal:** content-based routing — same input, different destinations
> depending on the message.

---

## What's new

| Concept | Where to look |
|---|---|
| `switch` **processor** — conditional sub-pipelines | `config.yaml` → `pipeline` |
| `switch` **output** — route to different sinks | `config.yaml` → `output` |
| `check:` Bloblang predicates | `config.yaml` |
| `drop` output for explicit discard | `config.yaml` |

---

## Run it

```bash
make ex05
```

Three output files appear:

```bash
ls examples/05-filter-and-route/out/
# gold.jsonl  silver.jsonl  bronze.jsonl
```

Same source data, three streams — partitioned by the `tier` field.

---

## The two switches, side by side

| | `switch` processor | `switch` output |
|---|---|---|
| Lives in | `pipeline.processors[]` | `output:` |
| Effect | Run different processors on the same message | Send the message to a different output |
| Use when | "Do *X* if the message looks like *Y*" | "Write to *X* if the message looks like *Y*" |

You'll often use them together: a switch *processor* to mark/normalise per
class, then a switch *output* to fan out to per-class sinks.

---

## Things to try

1. Add a `default` case to the output switch that writes to a `unknown.jsonl` file.
2. Move the `processed_at` stamp to a *common* mapping placed *before* the switch processor — see how processors share state via metadata.
3. Add `fallthrough: true` to a case to let a message be matched by *more than one* output — useful for audit fan-out.
4. Replace the bronze case's output with `drop: {}` — observe Bento silently discarding bronze events.

---

## Why this matters

Real pipelines almost always need different code paths for different message
shapes (orders vs refunds, success vs failure, customer vs admin). The
switch primitives + Bloblang predicates handle 99% of routing without
needing a programming language.

Next → [06 — Fan-out broker](../06-fan-out-broker/)
