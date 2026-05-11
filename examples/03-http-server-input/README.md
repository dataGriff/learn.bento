# 03 — HTTP server input

> **Goal:** turn Bento into a tiny HTTP service that ingests events and
> returns a synchronous response.

---

## What's new

| Concept | Where to look |
|---|---|
| `http_server` input — Bento listens on a port | `config.yaml` → `input` |
| `sync_response` output — answer the HTTP caller | `config.yaml` → `output` |
| `broker` output (`fan_out`) — log to stdout *and* respond | `config.yaml` → `output` |
| Reading and setting metadata | `config.yaml` → `pipeline` |

---

## Run it

```bash
make ex03
# (or)  bento -c examples/03-http-server-input/config.yaml
```

In another terminal, POST a JSON event:

```bash
curl -s -X POST http://localhost:4195/post \
  -H 'content-type: application/json' \
  -d '{"user":"alice","event":"login"}' | jq
```

You'll see the response synthesised by Bento:

```json
{
  "ok": true,
  "received_event": "login",
  "received_user": "alice",
  "request_id": "..."
}
```

…and the same payload echoed in the Bento log on the server side.

---

## Things to try

1. POST malformed JSON — observe the error path:
   ```bash
   curl -i -X POST http://localhost:4195/post -d 'not-json'
   ```
2. Add validation:
   ```yaml
   - mapping: |
       root = if this.user == null { throw("user is required") } else { this }
   ```
3. Switch from `sync_response` to a fire-and-forget design: drop the broker
   wrapping and use `output: { stdout: {} }`. Curl will then receive an
   empty body but still 200.

---

## Why this matters

Plenty of "data pipeline" workloads are actually webhooks — Stripe, GitHub,
Segment, Slack. With `http_server` + `sync_response` you can stand up a
durable webhook receiver in 30 lines of YAML, with validation, enrichment
and durable forwarding all built-in.

Next → [04 — Bloblang transform](../04-bloblang-transform/)
