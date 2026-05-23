---
title: "Core Concepts"
series: bento
order: 4
description: "The eight words you need to read any Bento config: message, batch, input, processor, output, buffer, cache, and rate limit."
canonical_url: https://hungovercoders.com/training/bento/04-core-concepts
---

# 04 — Core Concepts

Bento has a small, deliberate vocabulary. Once you internalise these eight
words, every example in this repo (and almost every config you'll ever see)
becomes trivial to read.

---

## 1. Message

The unit of work. A message has:

- a **payload** (`bytes` — but processors usually treat it as JSON)
- **metadata** (key/value strings — set by inputs, mutated by processors)
- a **delivery context** (the input owes an ack/nack)

> Mental model: a Kafka record. Bytes + headers + an offset to ack.

---

## 2. Batch

A list of messages handled together. Inputs may emit batches natively (a Kafka
poll, a CSV file, a `read_until`), or processors can batch via the `batching`
field at the input or output level. **Most processors operate per-message but
some operate per-batch** — the docs say which.

---

## 3. Input

Where messages come from. Examples: `generate`, `stdin`, `file`, `http_server`,
`kafka_franz`, `csv`, `gcp_pubsub`, `aws_sqs`, `mqtt`, `redis_streams`, `socket`.

```yaml
input:
  kafka_franz:
    seed_brokers: [localhost:9092]
    topics: [orders]
    consumer_group: bento-orders-consumer
```

Inputs are responsible for **acking back to the source** when the rest of the
pipeline confirms success. That's where Bento's at-least-once guarantee comes from.

---

## 4. Processor

A function over messages. Chain them in `pipeline.processors[]`. The most common ones:

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

## 5. Output

Where messages go. Same shape as inputs: `stdout`, `file`, `kafka_franz`,
`http_client`, `aws_s3`, `redis_pubsub`, `elasticsearch`, `sql_insert`,
`broker`, `switch`, `drop`, `reject`.

Two of the outputs are *meta-outputs*:

- **`broker`** — fan-out (`pattern: fan_out`) or load-balance (`pattern: round_robin`) to many child outputs.
- **`switch`** — content-based routing to one of N child outputs.

---

## 6. Buffer

By default Bento has **no buffer** — messages flow synchronously and
backpressure propagates naturally. You opt into one when you need:

- **`memory`** — async hand-off, smoothing bursts.
- **`system_window`** — *time-windowed* batches (tumbling/sliding windows by event time).

Buffers can break the at-least-once chain — read the docs before adding one.

---

## 7. Cache & Rate Limit

Resources that other components reference by name.

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

Used like this from a processor:

```yaml
- cache:
    resource: enrichment_cache
    operator: get
    key: ${! json("user_id") }
```

---

## 8. Resource

Any of `input`, `output`, `processor`, `cache`, `rate_limit`, `buffer` can be
defined once at the top level under `*_resources` and referenced by `label`
elsewhere — DRY for repeated chunks.

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

## Putting it together — full anatomy

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

That's it. Every config you'll ever see is a permutation of these top-level keys.

