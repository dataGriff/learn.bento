---
title: "WarpStream Setup"
series: bento
order: 13
description: "Run a local WarpStream cluster with Docker Compose and connect Bento to it using the kafka_franz input and output."
canonical_url: https://hungovercoders.com/training/bento/12-warpstream-setup
---

# 13 — WarpStream Setup

I wanted a Kafka-protocol message broker I could run locally without managing a ZooKeeper cluster, configuring brokers, or wrestling with AWS permissions — and WarpStream delivered. It's a Kafka-compatible streaming platform that stores data in object storage instead of local disk, meaning for local dev it runs as a single container with no S3 bucket required. For Bento, **WarpStream looks exactly like Kafka** — the same `kafka_franz` input and output work against it without any changes.

This repo ships a `docker-compose.yml` that runs a single-node WarpStream agent in **playground mode**. No AWS account, no S3 bucket, no auth. Just a Kafka-protocol broker on `localhost:9092` and a small utilities container with `rpk` for topic management.

---

## Getting it off the ground

```bash
docker compose up -d warpstream kafka-tools
```

Then verify it's ready:

```bash
docker compose logs -f warpstream | head
# look for:  "Bento [INFO] [agent] Started serving Kafka API at 0.0.0.0:9092"
```

The agent now exposes a Kafka broker on **`localhost:9092`**.

---

## Creating a topic

The compose stack includes `kafka-tools` — a small image with `rpk`, the Redpanda CLI that speaks the Kafka protocol fluently:

```bash
docker compose exec kafka-tools rpk topic create orders --partitions 3 --brokers warpstream:9092
```

List topics to confirm:

```bash
docker compose exec kafka-tools rpk topic list --brokers warpstream:9092
```

---

## Pointing Bento at it

A minimal producer config:

```yaml
input:
  generate:
    interval: 1s
    mapping: 'root = { "id": uuid_v4(), "ts": now() }'

output:
  kafka_franz:
    seed_brokers: [ "${WARPSTREAM_BROKER:localhost:9092}" ]
    topic:        "${TOPIC:orders}"
```

A minimal consumer config:

```yaml
input:
  kafka_franz:
    seed_brokers:    [ "${WARPSTREAM_BROKER:localhost:9092}" ]
    topics:          [ "${TOPIC:orders}" ]
    consumer_group:  "${GROUP:bento-orders-consumer}"
    start_from_oldest: true

output:
  stdout: {}
```

Both ship as full working examples — see [13 — WarpStream Produce](../13-warpstream-produce/) and [14 — WarpStream Consume and Process](../14-warpstream-consume-process/).

---

## Connecting Bento to a real WarpStream cluster

When you're ready to move beyond playground mode, switch the env vars and add SASL. The config structure is identical — just a few extra fields:

```yaml
output:
  kafka_franz:
    seed_brokers: [ "${WARPSTREAM_BROKER}" ]
    topic:        "${TOPIC}"
    tls:
      enabled: true
    sasl:
      - mechanism: PLAIN
        username: "${WARPSTREAM_USER}"     # service account ID
        password: "${WARPSTREAM_PASS}"     # service account secret
```

Everything else stays identical — that's the whole point of the Kafka-protocol surface. I'll be honest, the first time I swapped local playground for a real cluster I expected something to break. Nothing did. It just worked.

---

## Tearing it down

```bash
docker compose down
```

This stops the containers but preserves the volume. To also wipe data:

```bash
docker compose down -v
```

---

## Useful bits while it's running

```bash
# tail records on a topic
docker compose exec kafka-tools rpk topic consume orders --brokers warpstream:9092

# produce a one-off record from CLI
echo '{"hello":"world"}' | docker compose exec -T kafka-tools \
  rpk topic produce orders --brokers warpstream:9092
```

Once you've confirmed your local cluster is healthy and topics are in place, head over to lesson 13 to start producing real data, fellow hungovercoder.
