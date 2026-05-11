# 09 — Error handling & DLQ

> **Goal:** isolate failure, retry transient errors, route permanently-broken
> messages to a dead-letter queue (DLQ).

---

## What's new

| Concept | Where to look |
|---|---|
| `try` block — short-circuit a sub-pipeline on error | `config.yaml` → `pipeline` |
| `catch` block — recover / annotate errors | `config.yaml` |
| `retry` block — re-run with backoff | `config.yaml` |
| `errored()` predicate in a `switch` output | `config.yaml` → `output` |
| `dedupe` + `cache_resources` (idempotency) | `config.yaml` |
| `throw()` for explicit errors in Bloblang | `config.yaml` |

---

## The scenario

Some messages are valid orders. Some are missing fields. Some have a `qty`
of `0`, which we treat as illegal. Without DLQ handling, a single bad
message blocks the whole consumer.

---

## Run it

```bash
make ex09
```

Look at the two output files:

```bash
cat examples/09-error-handling-dlq/out/processed.jsonl
cat examples/09-error-handling-dlq/out/dlq.jsonl
```

Bad messages are routed to the DLQ with their original payload, the error
message and the time of failure attached as metadata.

---

## The error model in one paragraph

Bento doesn't throw exceptions. **Errors flag a message** but don't stop the
pipeline. By default a flagged message *still flows downstream* — which is
usually wrong, because a corrupt message will be written to your output as if
it succeeded. The fix is to wrap risky steps in `try` (so subsequent
processors are skipped on error) and route on `errored()` at the output
boundary.

```yaml
pipeline:
  processors:
    - try:                             # bail out of the rest of try-block on error
        - mapping: 'root = this.parse_json()'
        - http: { url: ... }
    - catch:                           # only runs if try block errored
        - mapping: |
            root = this
            meta dlq_reason = error()
```

---

## Things to try

1. Add a `retry` around the `http` step:
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
2. Add an idempotency dedupe on `order_id` to prevent reprocessing on replay:
   ```yaml
   - dedupe:
       cache: dedupe_cache
       key: ${! this.order_id }
   ```
   …with the cache configured in `cache_resources`.
3. Replace the file outputs with `kafka_franz` to `orders.dlq` for a real DLQ topology.

---

## Why this matters

Failing safely is the difference between a pipeline that's "running" and one
that's actually trustworthy. DLQ + retry + idempotency are the three
patterns you need; this example shows all three.

Next → [10 — Windowing & aggregation](../10-windowing-aggregation/)
