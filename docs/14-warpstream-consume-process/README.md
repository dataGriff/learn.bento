---
title: "WarpStream Consume and Process"
series: bento
order: 15
description: "Consume from one WarpStream topic, transform, and write back to another — the canonical stream processor shape."
canonical_url: https://hungovercoders.com/training/bento/14-warpstream-consume-process
---

# 15 — WarpStream Consume and Process

This is the one I wanted to get to. Consuming from one topic, enriching each event, and producing to another is the canonical shape of stream processing — and once you've got it working, you've got the skeleton for any event-driven service you'll ever need to build. We'll read the orders flowing in from lesson 13, compute a total and a tier, stamp on the source metadata, and write the enriched events to `orders.enriched`.

**Prerequisites:** Bento installed — see [02 — Installation](../02-installation/). WarpStream running — see [12 — WarpStream Setup](../12-warpstream-setup/).

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

**`input.kafka_franz`** is Bento's Kafka consumer, also built on `franz-go`. Three settings worth understanding before you run this:

- `consumer_group` — WarpStream tracks committed offsets per group, just like Kafka. Restart with the same group name and consumption resumes from where it left off.
- `start_from_oldest: true` — when the group is brand new (no committed offset yet), start from the earliest available message rather than the latest. Critical for replayability during development.
- `auto_replay_nacks: true` — if the output fails to ack, Bento re-delivers the message automatically rather than silently dropping it.

**The mapping** reads Kafka metadata fields that Bento exposes automatically: `kafka_topic`, `kafka_partition`, `kafka_offset`, and `kafka_key`. These live in message metadata rather than the payload, so you access them via `meta("field_name")`. The `.number()` call converts the string representation of partition and offset to numeric types before writing them into the payload.

The `meta kafka_key = meta("kafka_key")` line at the end propagates the original partition key to the output, so the same `customer_id` keeps its partition assignment in the enriched topic.

I'll be honest — I expected reading Kafka metadata to be more complicated than this. It's just `meta("kafka_offset")`. That's it.

---

## Prerequisites

```bash
docker compose up -d warpstream kafka-tools
docker compose exec kafka-tools rpk topic create orders --partitions 3 --brokers warpstream:9092
docker compose exec kafka-tools rpk topic create orders.enriched --partitions 3 --brokers warpstream:9092
```

Then start the producer from lesson 13 in another terminal:

```bash
cd docs/13-warpstream-produce
bento -c config.yaml
```

---

## Run it

```bash
cd docs/14-warpstream-consume-process
bento -c config.yaml
```

> Don't have the repo? `git clone https://github.com/hungovercoders/learn.bento.git`

Watch the enriched output topic fill up:

```bash
docker compose exec kafka-tools rpk topic consume orders.enriched --brokers warpstream:9092
```

You should see events like this, fellow hungovercoder:

```json
{
  "order_id": "...",
  "customer_id": "griff",
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

`kafka_franz` only commits an offset back to WarpStream **after the output acks the message**. If your downstream output fails, the message will be re-delivered. Plan transformations to be idempotent, or use `dedupe` — see [15 — Error Handling and DLQ](../15-error-handling-dlq/).

---

## Have a go

1. Stop the consumer, produce 100 messages, then restart with the same `consumer_group` — you'll resume from where you left off.
2. Change `consumer_group` to a brand-new value and set `start_from_oldest: false` — observe Bento starts from the *latest* offset, skipping all the historical messages.
3. Add a `dedupe` processor on `order_id` to make replays safe against duplicate processing.

---

## The workhorse pattern

Consume → transform → re-publish. This is the shape that underpins enrichment pipelines, validation services, format converters, fan-out processors, and CDC consumers. You've now got all three pieces in one working example. Lesson 15 takes this same setup and adds the error handling layer that makes it production-worthy.
