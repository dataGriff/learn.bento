---
title: "WarpStream Setup"
series: bento
order: 12
description: "Run a local WarpStream cluster with Docker Compose and connect Bento to it using the kafka_franz input and output."
canonical_url: https://hungovercoders.com/training/bento/12-warpstream-setup
---

# 06 — WarpStream setup

[WarpStream](https://www.warpstream.com/) is a Kafka-protocol-compatible
streaming platform that stores data directly in object storage (S3, GCS, etc.).
For Bento, **WarpStream looks exactly like Kafka** — the same `kafka_franz`
input/output works against it.

This repo ships a **`docker-compose.yml`** that runs a single-node WarpStream
agent in **playground mode** — no AWS account, no S3 bucket, no auth required.

---

## Bring it up

```bash
make warpstream-up
# (or)  docker compose up -d warpstream
```

Then verify:

```bash
docker compose logs -f warpstream | head
# look for:  "Bento [INFO] [agent] Started serving Kafka API at 0.0.0.0:9092"
```

The agent now exposes a Kafka broker on **`localhost:9092`**.

---

## Create a topic

The compose stack also includes `kafka-tools` (a tiny image with `rpk` /
`kafka-topics.sh`). Use the helper:

```bash
make ws-topic NAME=orders PARTITIONS=3
```

…or manually:

```bash
docker compose exec kafka-tools \
  rpk topic create orders --partitions 3 --brokers warpstream:9092
```

List topics:

```bash
make ws-topics
```

---

## Point Bento at it

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

Both ship as full examples — see `docs/13-warpstream-produce` and `docs/14-warpstream-consume-process`.

---

## Connecting Bento to a *real* WarpStream cluster

Switch the env vars and add SASL:

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

Everything else stays identical — the whole point of the Kafka-protocol surface.

---

## Tear down

```bash
make warpstream-down
```

This stops the containers but preserves the volume. To also wipe data:

```bash
docker compose down -v
```

---

## Useful tools

```bash
# tail records on a topic
make ws-consume TOPIC=orders

# produce a one-off record from CLI
echo '{"hello":"world"}' | docker compose exec -T kafka-tools \
  rpk topic produce orders --brokers warpstream:9092
```

---

Continue → [07 — Troubleshooting](07-troubleshooting.md)
