---
title: "Core Concepts"
series: bento
order: 5
description: "The eight words you need to read any Bento config: message, batch, input, processor, output, buffer, cache, and rate limit."
canonical_url: https://hungovercoders.com/training/bento/04-core-concepts
---

# 05 — Core Concepts

Bento has a small, deliberate vocabulary. I wanted to get this down in one place because once you've internalised these eight words, every example in this repo — and honestly almost every config you'll ever encounter — becomes trivial to read. We'll use all of them across the series, so it's worth a few minutes here before things get hands-on.

---

## 1. Message — the unit of work

A message is what flows through the pipeline. It has three parts:

- a **payload** (`bytes` — but processors usually treat it as JSON)
- **metadata** (key/value strings — set by inputs, mutated by processors)
- a **delivery context** (the input owes an ack/nack back to the source)

Think of it like a Kafka record: bytes plus headers plus an offset to acknowledge.

---

## 2. Batch — messages travelling together

A batch is a list of messages handled as a group. Inputs may emit batches natively — a Kafka poll, a CSV file read, a `read_until` — or you can batch explicitly via the `batching` field at the input or output level. Most processors operate per-message, but some operate per-batch; the docs say which is which.

---

## 3. Input — where messages come from

```yaml
input:
  kafka_franz:
    seed_brokers: [localhost:9092]
    topics: [orders]
    consumer_group: bento-orders-consumer
```

The full list includes `generate`, `stdin`, `file`, `http_server`, `kafka_franz`, `csv`, `gcp_pubsub`, `aws_sqs`, `mqtt`, `redis_streams`, `socket`, and more. Inputs are responsible for **acking back to the source** once the rest of the pipeline confirms success. That's where Bento's at-least-once guarantee lives.

---

## 4. Processor — a function over messages

Processors live in `pipeline.processors[]` and run in order. The ones you'll reach for most often:

| Processor | Purpose |
|---|---|
| `mapping` | Run a Bloblang script — your primary transformation tool |
| `branch` | Compute side data, optionally enrich the message |
| `switch` | Conditional sub-pipelines (if/elif/else) |
| `group_by` | Re-batch by a Bloblang key |
| `archive` / `unarchive` | Wrap/unwrap in tar, zip, csv, json_array, etc. |
| `dedupe` | Drop messages with a duplicate key (uses a cache) |
| `http` | Call an external HTTP endpoint, replace payload with response |
| `try` / `catch` | Error-isolation blocks |
| `retry` | Retry a sub-pipeline on error |
| `log` | Emit a log line — invaluable for debugging |
| `sleep` | Throttle / pace |
| `workflow` | DAG of branches with shared metadata — for complex enrichment |

---

## 5. Output — where messages go

Same shape as inputs: `stdout`, `file`, `kafka_franz`, `http_client`, `aws_s3`, `redis_pubsub`, `elasticsearch`, `sql_insert`, `broker`, `switch`, `drop`, `reject`.

Two outputs are *meta-outputs* worth knowing early:

- **`broker`** — fan-out (`pattern: fan_out`) or load-balance (`pattern: round_robin`) to many child outputs.
- **`switch`** — content-based routing to one of N child outputs.

---

## 6. Buffer — when you need async hand-off

By default Bento has **no buffer** — messages flow synchronously and backpressure propagates naturally back to the input. You opt into a buffer when you need one of two things:

- **`memory`** — async hand-off that smooths bursts.
- **`system_window`** — time-windowed batches (tumbling or sliding windows by event time).

I'll be honest: I've reached for a buffer exactly once in real pipelines, and that was for windowing. For most things the synchronous default is the right call. Also worth knowing — buffers can break the at-least-once chain, so read the docs carefully before adding one.

---

## 7. Cache & Rate Limit — named resources

These are shared resources that other components reference by label. Define them once, use them anywhere.

```yaml
cache_resources:
  - label: enrichment_cache
    memory:
      default_ttl: 5m

rate_limit_resources:
  - label: external_api
    local:
      count: 100
      interval: 1s
```

Used from a processor like this:

```yaml
- cache:
    resource: enrichment_cache
    operator: get
    key: ${! json("user_id") }
```

---

## 8. Resource — DRY for repeated chunks

Any of `input`, `output`, `processor`, `cache`, `rate_limit`, or `buffer` can be defined once at the top level under `*_resources` and referenced by `label` elsewhere. Hugely useful when the same processor logic appears across multiple pipelines.

```yaml
processor_resources:
  - label: redact_pii
    mapping: |
      root = this
      root.email = this.email.hash("sha256").encode("hex")

pipeline:
  processors:
    - resource: redact_pii
```

---

## Cracking open the full anatomy

```yaml
http: { address: 0.0.0.0:4195 }            # admin/metrics endpoint

input: { ... }

buffer: { ... }                            # optional

pipeline:
  threads: -1                              # -1 = NumCPU
  processors:
    - { ... }
    - { ... }

output: { ... }

cache_resources:      [ ... ]              # optional
rate_limit_resources: [ ... ]              # optional
processor_resources:  [ ... ]              # optional
input_resources:      [ ... ]              # optional
output_resources:     [ ... ]              # optional

metrics: { prometheus: {} }                # optional
tracer:  { open_telemetry_collector: {} }  # optional
logger:  { level: INFO, format: json }     # optional
```

That's it. Every config you'll ever see is a permutation of these top-level keys. Read on, fellow hungovercoder — next up we pull apart the config file itself.
