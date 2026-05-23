---
title: "WarpStream Consume and Process"
series: bento
order: 14
description: "Consume from one WarpStream topic, transform, and write back to another — the canonical stream processor shape."
canonical_url: https://hungovercoders.com/training/bento/14-warpstream-consume-process
---

# 14 — WarpStream Consume and Process

> **Goal:** consume from one WarpStream topic, transform, write back to another topic — the canonical "stream processor" shape.

**Prerequisites:** Bento installed — see [02 — Installation](../02-installation/). WarpStream running — see [12 — WarpStream Setup](../12-warpstream-setup/).

---

## What this lesson covers

| Concept | Where to look |
|---|---|
| `kafka_franz` **input** with consumer groups | `config.yaml` → `input` |
| `start_from_oldest: true` for replayability | `config.yaml` |
| Reading Kafka metadata (`kafka_topic`, `kafka_partition`, `kafka_offset`, `kafka_key`) | `config.yaml` |
| Producing to a different output topic | `config.yaml` → `output` |

---

## The config

```yaml
input:
  kafka_franz:
    seed_brokers:      [ "${WARPSTREAM_BROKER:localhost:9092}" ]
    topics:            [ "${IN_TOPIC:orders}" ]
    consumer_group:    "${GROUP:bento-orders-enricher}"
    start_from_oldest: true
    auto_replay_nacks: true

pipeline:
  processors:
    - mapping: |
        let total = this.qty * this.price
        root           = this
        root.total     = $total
        root.tier      = match {
          $total >= 200 => "gold",
          $total >= 50  => "silver",
          _             => "bronze",
        }

        root.source = {
          "topic":     meta("kafka_topic"),
          "partition": meta("kafka_partition").number(),
          "offset":    meta("kafka_offset").number(),
        }
        root.processed_at = now()

        meta kafka_key = meta("kafka_key")

output:
  kafka_franz:
    seed_brokers: [ "${WARPSTREAM_BROKER:localhost:9092}" ]
    topic:        "${OUT_TOPIC:orders.enriched}"
    key:          ${! meta("kafka_key") }
    compression:  zstd
```

**`input.kafka_franz`** is Bento's Kafka consumer, also based on `franz-go`. Key settings:

- `consumer_group` — WarpStream (like Kafka) tracks committed offsets per group. If you restart with the same group name, consumption resumes from where it left off.
- `start_from_oldest: true` — when the group is brand new (no committed offset), start from the earliest available message rather than the latest. Critical for replayability during development.
- `auto_replay_nacks: true` — if the output fails to ack, Bento re-delivers the message automatically rather than silently dropping it.

**The mapping** reads Kafka metadata fields that Bento exposes automatically: `kafka_topic`, `kafka_partition`, `kafka_offset`, and `kafka_key`. These are stored as message metadata (not in the payload) so you access them with `meta("field_name")`. The `.number()` call converts the string representation of partition/offset to a numeric type before writing it into the payload.

The `meta kafka_key = meta("kafka_key")` line propagates the original partition key to the output, so the same `customer_id` keeps its partition assignment in the enriched topic.

---

## Prerequisites

```bash
make warpstream-up
make ws-topic NAME=orders          PARTITIONS=3
make ws-topic NAME=orders.enriched PARTITIONS=3
```

Then start the producer from lesson 13 in another terminal:

```bash
make ex07
```

---

## Run it

```bash
make ex08
```

> Don't have the repo? `git clone https://github.com/hungovercoders/learn.bento.git`

Watch the enriched output topic:

```bash
make ws-consume TOPIC=orders.enriched
```

You should see events like:

```json
{
  "order_id": "...",
  "customer_id": "alice",
  "total": 42,
  "tier": "bronze",
  "source": {
    "topic": "orders",
    "partition": 0,
    "offset": 17
  },
  "processed_at": "2026-05-11T10:00:00Z"
}
```

---

## At-least-once semantics

`kafka_franz` only commits an offset back to WarpStream **after the output acks the message**. If your downstream output fails, the message will be re-delivered. Plan transformations to be idempotent, or use `dedupe` — see lesson 15.

---

## Things to try

1. Stop the consumer, produce 100 messages, then restart with the same `consumer_group` — you'll resume from where you left off.
2. Change `consumer_group` to a brand-new value and set `start_from_oldest: false` — observe Bento starts from the *latest* offset, skipping historical messages.
3. Add a `dedupe` processor on `order_id` to make replays safe against duplicate processing.

---

## Why this matters

This is the workhorse pattern of stream processing: consume → transform → re-publish. Once you have this working you have the skeleton for any event-driven service — enrichment, validation, format conversion, fan-out, CDC processing.

