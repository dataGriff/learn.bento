---
title: "Configuration Anatomy"
series: bento
order: 6
description: "Environment variable interpolation, Bloblang expressions, config file splitting, linting, and streams mode."
canonical_url: https://hungovercoders.com/training/bento/05-configuration-anatomy
---

# 06 — Configuration Anatomy

A Bento config is YAML, but there are a handful of quality-of-life features layered on top that you'll want to know before you start reading the examples. I wanted to cover these early because hitting an unfamiliar `${! ... }` mid-config without context is a bit disorienting the first time.

---

## Pouring in the env vars — interpolation at start-up

```yaml
input:
  kafka_franz:
    seed_brokers: [ "${WARPSTREAM_BROKER:localhost:9092}" ]
    topics:       [ "${TOPIC}" ]
    sasl:
      - mechanism: PLAIN
        username:  "${WARPSTREAM_USER}"
        password:  "${WARPSTREAM_PASS}"
```

Syntax is `${VAR}` or `${VAR:default}`. Bento will refuse to start if a non-defaulted variable is missing — which is exactly the right behaviour. I've had it save me from deploying a misconfigured pipeline to production more than once.

---

## Bloblang interpolation in strings — per-message expressions

Many string fields accept a Bloblang interpolation using the `${! ... }` syntax, evaluated once per message rather than at start-up:

```yaml
output:
  file:
    path: "./out/${! meta(\"kafka_topic\") }/${! timestamp_unix() }.json"
    codec: lines
```

The distinction is worth nailing down:

| Syntax | Evaluated when | Use for |
|---|---|---|
| `${VAR}`     | start-up   | secrets, broker URLs, file paths |
| `${! ... }` | per message | dynamic file names, dynamic HTTP URLs, dynamic topics |

---

## Splitting configs across files

For larger projects you can factor pieces out and reference them:

```yaml
# main.yaml
input:
  resource: kafka_orders_input

resources:
  - !include ./resources/inputs.yaml
  - !include ./resources/processors.yaml
```

The examples in this repo use single-file configs to keep things copy-pasteable, but in production you'll almost certainly want to split resource definitions out.

---

## Lint before you run

Always lint before running:

```bash
bento lint config.yaml
```

`bento lint` will catch:
- typos in field names
- unknown components
- Bloblang errors
- deprecated fields

CI tip: `bento lint docs/**/config.yaml` catches regressions across all your pipelines in one pass.

---

## Streams mode — many pipelines, one process

Run multiple pipelines in a single process:

```bash
bento -s --streams-dir ./streams
# ./streams/orders.yaml, ./streams/payments.yaml, ./streams/audit.yaml
```

Each file becomes a named stream with its own HTTP API endpoint at `/streams/<name>`. Useful when you have lots of small pipelines and want shared metrics or just one process to keep an eye on.

---

## The admin HTTP server

Almost every config exposes a small HTTP admin interface — default address `0.0.0.0:4195`, overrideable with `http.address`.

| Endpoint | Returns |
|---|---|
| `GET /ready`       | 200 once all components are ready |
| `GET /metrics`     | Prometheus metrics (when `metrics.prometheus` enabled) |
| `GET /stats`       | Snapshot of internal counters |
| `POST /streams/X`  | Register/replace stream X (in streams mode) |

Cheers, fellow hungovercoder — next up is Bloblang itself, and you'll be using it constantly from here on.
