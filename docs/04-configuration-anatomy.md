# 04 — Configuration anatomy

A Bento config is YAML. There are a few quality-of-life features beyond plain
YAML that you should know about before reading the examples.

---

## Environment variable interpolation

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

Syntax: `${VAR}` or `${VAR:default}`. Bento will refuse to start if a non-defaulted
variable is missing — handy for catching misconfiguration early.

---

## Bloblang interpolation in strings

Many string fields accept a Bloblang interpolation with the `${! ... }` syntax:

```yaml
output:
  file:
    path: "./out/${! meta(\"kafka_topic\") }/${! timestamp_unix() }.json"
    codec: lines
```

Compare:

| Syntax | Evaluated when | Use for |
|---|---|---|
| `${VAR}`     | start-up   | secrets, broker URLs, file paths |
| `${! ... }` | per message | dynamic file names, dynamic HTTP URLs, dynamic topics |

---

## Splitting configs across files

For larger projects, factor pieces out and reference them:

```yaml
# main.yaml
input:
  resource: kafka_orders_input

resources:
  - !include ./resources/inputs.yaml
  - !include ./resources/processors.yaml
```

The `Makefile` in this repo prefers single-file configs to keep examples
copy-pasteable, but in production you'll want resource files.

---

## Linting

Always lint before running:

```bash
bento lint examples/04-bloblang-transform/config.yaml
```

`bento lint` will tell you about:
- typos in field names
- unknown components
- Bloblang errors
- deprecated fields

CI tip: `bento lint examples/**/config.yaml` catches regressions across all your pipelines.

---

## Streams mode

Run multiple pipelines in one process:

```bash
bento -s --streams-dir ./streams
# ./streams/orders.yaml, ./streams/payments.yaml, ./streams/audit.yaml
```

Each file becomes a named stream with its own HTTP API endpoint at
`/streams/<name>`. Useful when you have lots of small pipelines and want
shared metrics / one process.

---

## The admin HTTP server

Almost every config exposes:

| Endpoint | Returns |
|---|---|
| `GET /ready`       | 200 once all components are ready |
| `GET /metrics`     | Prometheus metrics (when `metrics.prometheus` enabled) |
| `GET /stats`       | Snapshot of internal counters |
| `POST /streams/X`  | Register/replace stream X (in streams mode) |

Default address is `0.0.0.0:4195`. Override with `http.address`.

---

Continue → [05 — Bloblang cheat-sheet](05-bloblang-cheatsheet.md)
