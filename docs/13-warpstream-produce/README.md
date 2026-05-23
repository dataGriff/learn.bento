---
title: "WarpStream Produce"
series: bento
order: 13
description: "Generate synthetic events and produce them to a WarpStream topic using the Kafka protocol."
canonical_url: https://hungovercoders.com/training/bento/13-warpstream-produce
---

# 13 — WarpStream Produce

> **Goal:** generate synthetic events and produce them to a WarpStream topic using the Kafka protocol.

**Prerequisites:** Bento installed — see [02 — Installation](02-installation.md). WarpStream running — see [12 — WarpStream Setup](12-warpstream-setup.md).

---

## What this lesson covers

| Concept | Where to look |
|---|---|
| `kafka_franz` output (the modern Kafka producer) | `config.yaml` → `output` |
| Setting Kafka `key` from message content for partitioning | `config.yaml` |
| Env-var defaulting (`${TOPIC:orders}`) | `config.yaml` |

---

## The config

```yaml
input:
  generate:
    interval: 1s
    mapping: |
      let customers = ["alice","bob","carol","dave","erin"]
      let skus      = ["A","B","C","D"]
      root.order_id    = uuid_v4()
      root.customer_id = $customers.index(random_int(min:0, max:4))
      root.sku         = $skus.index(random_int(min:0, max:3))
      root.qty         = random_int(min:1, max:5)
      root.price       = random_int(min:5, max:200)
      root.created_at  = now()

pipeline:
  processors:
    - mapping: |
        meta kafka_key = this.customer_id

output:
  kafka_franz:
    seed_brokers: [ "${WARPSTREAM_BROKER:localhost:9092}" ]
    topic:        "${TOPIC:orders}"
    key:          ${! meta("kafka_key") }
    compression:  zstd
    timeout:      5s
```

**`input.generate`** produces synthetic order events. Bloblang `let` variables are local to the mapping — `$customers` holds an array, and `.index(random_int(...))` picks one element at random. `uuid_v4()` generates a unique order ID for each message.

**The pipeline processor** writes the `customer_id` to a metadata field named `kafka_key`. Metadata is not part of the JSON payload; it lives alongside the message and is used to configure output behaviour.

**`output.kafka_franz`** is Bento's high-performance Kafka producer, based on the `franz-go` library. Key fields:

- `seed_brokers` — one or more bootstrap addresses. `${WARPSTREAM_BROKER:localhost:9092}` reads from an env var, falling back to `localhost:9092` if unset. WarpStream speaks the Kafka wire protocol, so the same output works unchanged against Redpanda or Apache Kafka.
- `topic` — also env-var defaulted, so you can point at different topics without editing the config.
- `key` — the Kafka partition key, read from metadata using the `${! ... }` interpolation syntax. Same `customer_id` value → same partition → ordered delivery per customer.
- `compression: zstd` — WarpStream supports zstd; use it, it's fast.

---

## Prerequisites

Bring up the local WarpStream agent and create the topic:

```bash
make warpstream-up
make ws-topic NAME=orders PARTITIONS=3
```

---

## Run it

```bash
make ex07
```

> Don't have the repo? `git clone https://github.com/hungovercoders/learn.bento.git`

Verify the topic is filling up:

```bash
make ws-consume TOPIC=orders
# Ctrl-C to stop
```

You'll see one synthetic order per second — keyed by `customer_id`, so all events for the same customer land on the same partition.

---

## Things to try

1. Remove `interval` (or set it to `""`) — `generate` fires as fast as it can. Watch the consumer scroll.
2. Add Kafka headers by writing to metadata and enabling `metadata.include_patterns`:
   ```yaml
   # in pipeline:
   - mapping: |
       meta source     = "synthetic"
       meta event_type = "order.created"
   # in output.kafka_franz:
   metadata:
     include_patterns: [ ".*" ]
   ```
3. Change `compression` to `snappy` or remove it entirely — observe no functional difference from the consumer's perspective.

---

## Why this matters

Producing to Kafka/WarpStream from anything that can shape a JSON object becomes a one-config-file exercise. No producer SDK to wrangle, no schema registry required (though `schema_registry_encode` is a first-class processor if you need it).

Continue → [14 — WarpStream Consume and Process](14-warpstream-consume-process.md)
