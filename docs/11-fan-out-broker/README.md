---
title: "Fan-out Broker"
series: bento
order: 11
description: "Deliver every message to multiple destinations — the classic tap-a-stream pattern."
canonical_url: https://hungovercoders.com/training/bento/11-fan-out-broker
---

# 11 — Fan-out Broker

> **Goal:** deliver every message to *multiple* destinations — the classic "tap a stream" pattern.

**Prerequisites:** Bento installed — see [02 — Installation](../02-installation/).

---

## What this lesson covers

| Concept | Where to look |
|---|---|
| `broker` output with `pattern: fan_out` | `config.yaml` → `output` |
| Per-output `processors` (transform per branch) | `config.yaml` |
| Mixing structured (JSON file) and unstructured (text file) sinks | `config.yaml` |

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

output:
  broker:
    pattern: fan_out
    outputs:

      - file:
          path:  ./out/raw.jsonl
          codec: lines

      - processors:
          - mapping: |
              root = "%s | id=%s | tier=%s | total=%v".format(
                now().ts_format("2006-01-02T15:04:05Z"),
                this.id,
                this.tier,
                this.total,
              )
        file:
          path:  ./out/audit.log
          codec: lines

      - processors:
          - mapping: |
              root = {}
              root.id    = this.id
              root.total = this.total
              root.tier  = this.tier
        file:
          path:  ./out/summary.jsonl
          codec: lines
```

**`output.broker`** is Bento's multi-output primitive. With `pattern: fan_out`, every message is delivered to *every* child output — contrast this with `switch`, which picks exactly one.

Each child output can optionally have its own `processors` block. These run only for that branch, letting you reshape the message differently for each sink. The message that enters the broker is not mutated — each branch receives its own copy.

The three branches here produce three different shapes from the same source event:
- `raw.jsonl` — the full JSON as-is.
- `audit.log` — a human-readable text line formatted with `format()`.
- `summary.jsonl` — a stripped-down object with only `id`, `total`, and `tier`.

---

## Run it

```bash
make ex06
```

> Don't have the repo? `git clone https://github.com/hungovercoders/learn.bento.git`

Look at the outputs:

```bash
cat ./out/raw.jsonl
cat ./out/audit.log
cat ./out/summary.jsonl
```

---

## Patterns supported by `broker`

| Pattern | Effect |
|---|---|
| `fan_out` | Send each message to **every** child output (this example) |
| `fan_out_sequential` | Same, but wait for each child before the next — useful for ordering |
| `round_robin` | Load-balance across children (one message per child) |
| `greedy` | Children pull as fast as they can — highest throughput, worst ordering |

---

## At-least-once across fan-out

By default, `fan_out` waits for **all** outputs to ack before acking upstream. A single slow output back-pressures the entire pipeline. If you need to decouple a slow branch, put a `memory` buffer in front of it, or write to a Kafka topic and consume separately.

---

## Things to try

1. Add a fourth branch that POSTs each event to `httpbin.org/post` using `http_client`.
2. Switch `pattern` to `round_robin` — observe each branch only receives approximately one-third of messages.
3. Add a `processors` block to the `audit.log` branch to redact PII before writing.

---

## Why this matters

Fan-out is the answer to half of all "can we *also* send this to X?" requests. Auditing, mirroring to S3, dual-writing during migrations, dev/test sampling — all are one `broker` block away.

