---
title: "WarpStream Produce"
series: bento
order: 14
description: "Generate synthetic events and produce them to a WarpStream topic using the Kafka protocol."
canonical_url: https://hungovercoders.com/training/bento/13-warpstream-produce
---

# 14 — WarpStream Produce

I wanted to get orders flowing into a WarpStream topic with a sensible partition key and proper compression — and do it without wiring up a producer SDK, configuring a client library, or writing any application code. This lesson shows how to do all of that in a single Bento config. We'll generate synthetic order events and produce them using `kafka_franz`, Bento's high-performance Kafka output.

**Prerequisites:** Bento installed — see [02 — Installation](../02-installation/). WarpStream running — see [12 — WarpStream Setup](../12-warpstream-setup/).

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

**`input.generate`** produces one synthetic order event per second. Bloblang `let` variables are local to the mapping — `$customers` holds an array and `.index(random_int(...))` picks one element at random. `uuid_v4()` gives each order a unique ID.

**The pipeline processor** writes `customer_id` to a metadata field named `kafka_key`. Metadata is separate from the JSON payload — it travels alongside the message and is used to configure output behaviour rather than appear in the data itself.

**`output.kafka_franz`** is Bento's Kafka producer, built on the `franz-go` library. A few things worth noting:

- `seed_brokers` — one or more bootstrap addresses. `${WARPSTREAM_BROKER:localhost:9092}` reads from an env var and falls back to `localhost:9092` if it's not set. WarpStream speaks the Kafka wire protocol, so the same config works unchanged against Redpanda or Apache Kafka.
- `topic` — also env-var defaulted, so you can retarget without touching the config.
- `key` — the partition key, read from metadata using the `${! ... }` interpolation syntax. Same `customer_id` → same partition → ordered delivery per customer.
- `compression: zstd` — WarpStream supports zstd and it's quick. Worth using.

---

## Prerequisites

Bring up the local WarpStream agent and create the topic:

```bash
docker compose up -d warpstream kafka-tools
docker compose exec kafka-tools rpk topic create orders --partitions 3 --brokers warpstream:9092
```

---

## Orders on the bar — run it

```bash
cd docs/13-warpstream-produce
bento -c config.yaml
```

> Don't have the repo? `git clone https://github.com/hungovercoders/learn.bento.git`

Verify the topic is filling up in a second terminal:

```bash
docker compose exec kafka-tools rpk topic consume orders --brokers warpstream:9092
# Ctrl-C to stop
```

You'll see one synthetic order per second — keyed by `customer_id`, so all events for the same customer land on the same partition. I'll be honest, watching a topic fill up in real time never gets old.

---

## Have a go

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

## Why it matters

Producing to Kafka or WarpStream from anything that can shape a JSON object becomes a one-config-file exercise with Bento. No producer SDK to wrangle, no schema registry required (though `schema_registry_encode` is a first-class processor if you need it). Once the orders are flowing, head to lesson 14 to consume and process them.
