# 08 — WarpStream consume + process

> **Goal:** consume from one WarpStream topic, transform, write back to
> another topic — the canonical "stream processor" shape.

---

## What's new

| Concept | Where to look |
|---|---|
| `kafka_franz` **input** with consumer groups | `config.yaml` → `input` |
| `start_from_oldest: true` for replayability | `config.yaml` |
| Reading Kafka metadata (`kafka_topic`, `kafka_partition`, `kafka_offset`, `kafka_key`) | `config.yaml` |
| Producing to a different output topic | `config.yaml` → `output` |

---

## Prerequisites

```bash
make warpstream-up
make ws-topic NAME=orders          PARTITIONS=3
make ws-topic NAME=orders.enriched PARTITIONS=3
```

…and have something producing to `orders` (e.g. `make ex07` in another terminal).

---

## Run it

```bash
make ex08
```

Watch the enriched output topic in another terminal:

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

`kafka_franz` only commits an offset back to WarpStream **after the output
acks the message**. If your downstream output fails, the message will be
re-delivered. Plan transformations to be idempotent (or use `dedupe` — see
the troubleshooting doc).

---

## Things to try

1. Stop the consumer, produce 100 messages to `orders`, then restart with the
   same `consumer_group` — you'll resume from where you left off (because the
   group offset is committed).
2. Change `consumer_group` to a brand-new value — observe Bento replays from
   the *latest* offset by default. Set `start_from_oldest: true` to replay
   from the very beginning.
3. Add a `dedupe` processor on `order_id` — see example 09 for the cache pattern.

---

## Why this matters

This is the workhorse pattern of stream processing: consume → transform →
re-publish. Once you've got this working you have the skeleton for any
event-driven service.

Next → [09 — Error handling & DLQ](../09-error-handling-dlq/)
