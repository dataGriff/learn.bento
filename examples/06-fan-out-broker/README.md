# 06 — Fan-out broker

> **Goal:** deliver every message to *multiple* destinations — the
> classic "tap a stream" pattern.

---

## What's new

| Concept | Where to look |
|---|---|
| `broker` output with `pattern: fan_out` | `config.yaml` → `output` |
| Per-output `processors` (transform per branch) | `config.yaml` |
| Mixing structured (JSON file) and unstructured (text file) sinks | `config.yaml` |

---

## Run it

```bash
make ex06
```

Look at the outputs:

```bash
cat examples/06-fan-out-broker/out/raw.jsonl       # original event JSON
cat examples/06-fan-out-broker/out/audit.log       # one human-readable line per event
echo "---"
cat examples/06-fan-out-broker/out/summary.jsonl   # only id + total + tier
```

Same input, three different shapes — produced from a single pipeline.

---

## Patterns supported by `broker`

| Pattern | Effect |
|---|---|
| `fan_out`               | Send each message to **every** child output (this example) |
| `fan_out_sequential`    | Same, but wait for each child before the next — useful for ordering |
| `round_robin`           | Load-balance across children (one message per child) |
| `greedy`                | Children pull as fast as they can — highest throughput, worst ordering |

---

## At-least-once across fan-out

By default, `fan_out` waits for **all** outputs to ack before acking upstream.
That means a single slow output back-pressures the whole pipeline. If you'd
rather decouple, put a `memory` buffer in front of the slow branch using a
nested `broker` or write to Kafka and consume it separately.

---

## Things to try

1. Add a 4th branch that POSTs each event to `httpbin.org/post` with `http_client`.
2. Switch `pattern` to `round_robin` — observe each branch only sees ~1/3 of messages.
3. Add a `processors` block to the `audit.log` branch to redact PII before writing.

---

## Why this matters

Fan-out is the answer to half of all "can we *also* send this to X?" Slack
messages. Auditing, mirroring to S3, dual-writing during migrations, dev/test
sampling — all are one `broker` block away.

Next → [07 — WarpStream produce](../07-warpstream-produce/)
