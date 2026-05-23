---
title: "Error Handling and DLQ"
series: bento
order: 15
description: "Isolate failure, retry transient errors, and route permanently broken messages to a dead-letter queue."
canonical_url: https://hungovercoders.com/training/bento/15-error-handling-dlq
---

# 15 — Error Handling and DLQ

> **Goal:** isolate failure, retry transient errors, route permanently-broken messages to a dead-letter queue (DLQ).

**Prerequisites:** Bento installed — see [02 — Installation](02-installation.md). WarpStream running — see [12 — WarpStream Setup](12-warpstream-setup.md).

> If you have the repo cloned, you can run this example with `make ex09` or `bento -c examples/09-error-handling-dlq/config.yaml`.
> Clone: `git clone https://github.com/hungovercoders/learn.bento.git`

---

## What this lesson covers

| Concept | Where to look |
|---|---|
| `try` block — short-circuit a sub-pipeline on error | `config.yaml` → `pipeline` |
| `catch` block — recover / annotate errors | `config.yaml` |
| `errored()` predicate in a `switch` output | `config.yaml` → `output` |
| `dedupe` + `cache_resources` (idempotency) | `config.yaml` |
| `throw()` for explicit errors in Bloblang | `config.yaml` |

---

## The config

```yaml
input:
  file:
    paths: [ ./examples/09-error-handling-dlq/data/orders.jsonl ]
    codec: lines

cache_resources:
  - label: dedupe_cache
    memory:
      default_ttl: 1h

pipeline:
  processors:

    - dedupe:
        cache: dedupe_cache
        key: ${! json("order_id").or("") }

    - try:
        - mapping: |
            root = content().parse_json()

        - mapping: |
            if this.order_id == null { throw("missing order_id") }
            if this.sku      == null { throw("missing sku") }
            if this.qty      == null || this.qty <= 0 {
              throw("qty must be > 0, got %v".format(this.qty))
            }
            if this.price    == null || this.price < 0 {
              throw("price must be >= 0, got %v".format(this.price))
            }
            root = this
            root.total = this.qty * this.price

    - catch:
        - mapping: |
            root.original    = content().string()
            root.error       = error()
            root.failed_at   = now()
            meta dlq         = "true"

output:
  switch:
    cases:
      - check: errored() || meta("dlq") == "true"
        output:
          file:
            path:  ./examples/09-error-handling-dlq/out/dlq.jsonl
            codec: lines
      - output:
          file:
            path:  ./examples/09-error-handling-dlq/out/processed.jsonl
            codec: lines
```

**Bento's error model:** processors don't throw exceptions. When a processor fails, it *flags* the message with an error, but the message keeps flowing downstream. Without explicit DLQ handling, a corrupt message arrives at your output looking like a success. The fix is to wrap risky steps in `try` and route on `errored()` at the output boundary.

**`dedupe`** runs first, before the risky steps. It checks the `order_id` against a `memory` cache (configured in `cache_resources`). If the key has been seen before, the message is dropped silently — preventing duplicate processing on replay. The `.or("")` fallback means malformed messages with no `order_id` pass through to the validation step rather than matching a false cache entry.

**`try`** wraps a sub-pipeline. The first error in any step causes the remaining steps to be *skipped* — the message goes directly to `catch`. This prevents partial transforms: either all steps run, or none do.

**`catch`** only runs on messages that errored in the preceding `try`. Here it reshapes the payload to include the original bytes (`content().string()`), the error message (`error()`), and a timestamp. It also writes a `dlq` metadata flag.

**`output.switch`** routes on `errored()` — a built-in Bloblang predicate that returns true if the message carries an error flag. The `|| meta("dlq") == "true"` handles the case where `catch` set the flag explicitly.

---

## Run it

```bash
make ex09
# or, if running directly:
bento -c examples/09-error-handling-dlq/config.yaml
```

Look at both output files:

```bash
cat examples/09-error-handling-dlq/out/processed.jsonl
cat examples/09-error-handling-dlq/out/dlq.jsonl
```

Bad messages land in the DLQ with their original payload, error message, and failure timestamp. Valid messages land in `processed.jsonl` with a computed `total`.

---

## Things to try

1. Add a `retry` around a flaky step:
   ```yaml
   - retry:
       max_retries: 3
       backoff:
         initial_interval: 200ms
         max_interval:     5s
       processors:
         - http:
             url: https://example.com
   ```
2. Replace the file outputs with `kafka_franz` topics (`orders.processed` and `orders.dlq`) for a real streaming DLQ topology.
3. Add a second `dedupe` processor keyed on `error()` to prevent the same error from being re-processed repeatedly.

---

## Why this matters

Failing safely is the difference between a pipeline that is "running" and one that is actually trustworthy. DLQ routing + idempotency are the two patterns you need for production readiness; this example shows both without any application code.

Continue → [16 — Windowing and Aggregation](16-windowing-aggregation.md)
