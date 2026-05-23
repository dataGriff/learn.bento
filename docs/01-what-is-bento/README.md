---
title: "What Is Bento?"
series: bento
order: 1
description: "A single static binary that reads YAML and runs a streaming data pipeline — no code, no JVM, no cluster manager."
canonical_url: https://hungovercoders.com/training/bento/01-what-is-bento
---

# 01 — What is Bento?

I wanted a stream processor that didn't need a cluster, a JVM, and three cups of coffee just to prove it was alive. Bento is that thing. A single static binary, YAML config, no programming language required to use it. You describe what data flows in, what happens to it in the middle, and where it goes out — and Bento runs it.

---

## The mental model

A Bento pipeline has three stages:

```
┌──────────┐    ┌─────────────────────────────┐    ┌──────────┐
│  INPUT   │ →  │  PIPELINE (processors[])    │ →  │  OUTPUT  │
└──────────┘    └─────────────────────────────┘    └──────────┘
   pulls            transforms / filters /              pushes
   bytes            enriches / routes                   bytes
```

Everything else — buffers, caches, rate limits, metrics, tracing — exists to support that core flow. The smallest pipeline you can write is ten lines of YAML:

```yaml
input:
  generate:
    mapping: 'root = "hello world"'
    interval: 1s

output:
  stdout: {}
```

Run it: `bento -c config.yaml`. One message per second, straight to your terminal. That's a working stream processor right there.

---

## Where it fits in the world

Bento sits in the "glue pipeline" lane — stateless or lightly-stateful, low ops overhead, deployable by one person with one terminal command. If you need exactly-once guarantees on terabytes of state with complex event-time windowing, you want Flink. For the other 90% of jobs — moving data between systems, transforming it on the way, routing it based on content — Bento is enough, and a lot less hassle.

The neighbours worth knowing so you can make an informed decision:

| Tool | When to reach for it instead |
|---|---|
| **Kafka Connect** | You're deep in Confluent and need exactly-once Kafka↔DB |
| **Vector** | Your pipeline is observability-only — logs and metrics |
| **Flink / Spark Streaming** | Stateful, complex event time, huge state |
| **Apache NiFi** | You need a visual canvas and data provenance tracking |

---

## A brief history of confusing names

The project's had a few lives. Worth knowing so you don't end up in the wrong docs rabbit hole:

- **2017–2024** — Ashley Jeffs built **Benthos**, a well-loved OSS stream processor.
- **2024** — Redpanda acquired it and rebranded as **Redpanda Connect**. License terms shifted in a way some users weren't keen on.
- **2024** — **WarpStream Labs** forked the last Apache-2.0 Benthos and called it **Bento**.
- **2024** — Confluent acquired WarpStream. Bento's open governance carries on.

This series covers the **WarpStream Bento** fork. Configs are largely compatible with Redpanda Connect, but component names occasionally diverge — when in doubt, the source of truth is [warpstreamlabs.github.io/bento](https://warpstreamlabs.github.io/bento/).

---

## Why it fits the hungovercoders worldview

Bento is **small, cheap, source-controlled, and deployable by one slightly hungover person on a Tuesday**. No cluster to manage, no runtime to install alongside it, no Helm chart inheritance hell. The whole pipeline is a YAML file in git. That's why I keep reaching for it when someone says "I just need to move data from A to B with a bit of transformation in the middle."

It also has a few genuinely nice properties baked in:

- **Backpressure by default** — slow outputs naturally slow inputs. No silent data loss from a backed-up sink.
- **At-least-once delivery** — the ack contract is honoured end to end.
- **Testable configs** — `bento test` runs YAML-defined unit tests against your pipeline logic. Proper tests.
- **Lintable configs** — `bento lint` catches shape errors and typos before they bite you in production.

Read on fellow hungovercoder — by the end of this series you'll have a full end-to-end pipeline running, and a clear view on when Bento is the right tool and when it isn't.
