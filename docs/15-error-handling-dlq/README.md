---
title: "Error Handling and DLQ"
series: bento
order: 16
description: "Isolate failure, retry transient errors, and route permanently broken messages to a dead-letter queue."
canonical_url: https://hungovercoders.com/training/bento/15-error-handling-dlq
---

# 16 — Error Handling and DLQ

This is the grown-up stuff. Any pipeline can handle a clean, well-formed message flowing through on a good day — but what happens when the data is malformed, a field is missing, or a downstream service is temporarily unhappy? This lesson is about failing safely: isolating failures, de-duplicating replays, and routing broken messages to a dead-letter queue (DLQ) rather than silently dropping them or crashing the pipeline.

**Prerequisites:** Bento installed — see [02 — Installation](../02-installation/). WarpStream running — see [12 — WarpStream Setup](../12-warpstream-setup/).

---

## The config

```yaml
input:
  file:
    paths: [ ./data/orders.jsonl ]
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
            path:  ./out/dlq.jsonl
            codec: lines
      - output:
          file:
            path:  ./out/processed.jsonl
            codec: lines
```

**Bento's error model** is worth understanding before you read the rest. Processors don't throw exceptions. When a processor fails, it *flags* the message with an error, but the message keeps flowing downstream. Without explicit DLQ handling, a corrupt message arrives at your output looking like a success. That's the failure mode you're guarding against here.

**`dedupe`** runs first, before the risky steps. It checks `order_id` against a `memory` cache (declared in `cache_resources`). If the key has already been seen, the message is dropped silently — preventing duplicate processing on replay. The `.or("")` fallback ensures malformed messages with no `order_id` pass through to the validation step rather than matching a false cache entry.

**`try`** wraps a sub-pipeline. The first error in any step causes the remaining steps to be skipped — the message goes straight to `catch`. This prevents partial transforms: either all steps succeed, or none run.

**`catch`** only fires on messages that errored in the preceding `try`. It reshapes the payload to include the original raw bytes (`content().string()`), the error message (`error()`), and a failure timestamp. It also writes a `dlq` metadata flag that the output switch will use to route the message.

**`output.switch`** routes on `errored()` — a built-in predicate that returns true if the message carries an error flag. The `|| meta("dlq") == "true"` handles the case where `catch` set the flag explicitly. Messages that pass validation land in `processed.jsonl`; everything else goes to `dlq.jsonl`.

I'll be honest — the first time I saw `try`/`catch` in a Bento config I thought it was a bit odd for a YAML pipeline. But once you see a corrupt message arrive in the DLQ with its original payload, error message, and timestamp all neatly captured, you start reaching for it in every pipeline.

---

## Run it

```bash
cd docs/15-error-handling-dlq
bento -c config.yaml
```

> Don't have the repo? `git clone https://github.com/hungovercoders/learn.bento.git`

Look at both output files:

```bash
cat ./out/processed.jsonl
cat ./out/dlq.jsonl
```

Bad messages land in the DLQ with their original payload, error message, and failure timestamp. Valid messages land in `processed.jsonl` with a computed `total`.

---

## Have a go

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

## The difference between running and trustworthy

A pipeline without error handling is "running". A pipeline with `try`/`catch`, a DLQ, and idempotency is *trustworthy*. Those are two very different things. Once you've shipped both patterns — and this example shows both together, without any application code — you've got everything you need to run a Bento pipeline in production with confidence.

Well done for making it this far, fellow hungovercoder.
