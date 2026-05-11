# 07 — WarpStream produce

> **Goal:** generate synthetic events and produce them to a WarpStream topic
> using the Kafka protocol.

---

## What's new

| Concept | Where to look |
|---|---|
| `kafka_franz` output (the modern Kafka producer) | `config.yaml` → `output` |
| Setting Kafka `key` from message content for partitioning | `config.yaml` |
| Env-var defaulting (`${TOPIC:orders}`) | `config.yaml` |

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
# (or)  bento -c examples/07-warpstream-produce/config.yaml
```

Verify the topic is filling up:

```bash
make ws-consume TOPIC=orders
# (Ctrl-C to stop)
```

You'll see one synthetic order per second — keyed by `customer_id`, so all
events for the same customer land on the same partition (preserving order
per-key — a guarantee Kafka and WarpStream provide).

---

## Things to try

1. Bump throughput by removing `interval` (or setting it to `""`) — the
   `generate` input will fire as fast as it can. Watch the consumer scroll.
2. Add metadata you want as Kafka headers:
   ```yaml
   - mapping: |
       meta source     = "synthetic"
       meta event_type = "order.created"
   ```
   Then in the `kafka_franz` output:
   ```yaml
   metadata:
     include_patterns: [ ".*" ]
   ```
3. Add `compression: zstd` to the output — WarpStream supports zstd.

---

## Why this matters

Producing to Kafka/WarpStream from anything that can shape a JSON object
becomes a one-config-file exercise. No producer SDK to wrangle, no schema
registry to bolt on (unless you want to — `schema_registry_decode` /
`_encode` are first-class processors).

Next → [08 — WarpStream consume + process](../08-warpstream-consume-process/)
