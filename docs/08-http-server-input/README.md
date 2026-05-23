---
title: "HTTP Server Input"
series: bento
order: 8
description: "Turn Bento into a tiny HTTP service that ingests events and returns a synchronous response."
canonical_url: https://hungovercoders.com/training/bento/08-http-server-input
---

# 08 — HTTP Server Input

> **Goal:** turn Bento into a tiny HTTP service that ingests events and returns a synchronous response.

**Prerequisites:** Bento installed — see [02 — Installation](../02-installation/).

---

## What this lesson covers

| Concept | Where to look |
|---|---|
| `http_server` input — Bento listens on a port | `config.yaml` → `input` |
| `sync_response` output — answer the HTTP caller | `config.yaml` → `output` |
| `broker` output (`fan_out`) — log to stdout *and* respond | `config.yaml` → `output` |
| Reading and setting metadata | `config.yaml` → `pipeline` |

---

## The config

```yaml
http:
  address: 0.0.0.0:4195

input:
  http_server:
    address: ""
    path: /post
    allowed_verbs: [POST]
    timeout: 5s

pipeline:
  processors:
    - mapping: |
        meta request_id = uuid_v4()

    - mapping: |
        root.ok             = true
        root.received_user  = this.user.or("anonymous")
        root.received_event = this.event.or("unknown")
        root.request_id     = meta("request_id")

output:
  broker:
    pattern: fan_out
    outputs:
      - sync_response: {}
      - stdout: {}
```

**`http.address`** starts a shared HTTP server on port 4195. This server is also used for the built-in admin and metrics endpoints.

**`input.http_server`** registers a route on the shared server. `address: ""` means "use the global HTTP server above" rather than starting a second listener. `allowed_verbs: [POST]` rejects any non-POST request with a 405.

**`pipeline.processors`** runs two mappings in sequence. The first stamps a metadata field `request_id` — metadata lives alongside the message but isn't part of the payload. The second builds the response body, reading from both the incoming payload (`this.user`, `this.event`) and the metadata we just set (`meta("request_id")`). `.or("default")` provides a safe fallback if the field is absent.

**`output.broker`** with `pattern: fan_out` delivers the message to both child outputs simultaneously. `sync_response` sends the payload back as the HTTP response body. `stdout` logs it on the server side.

---

## Run it

```bash
make ex03
```

> Don't have the repo? `git clone https://github.com/hungovercoders/learn.bento.git`

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

The same payload is echoed in the Bento log on the server side.

---

## Things to try

1. POST malformed JSON — observe the error path:
   ```bash
   curl -i -X POST http://localhost:4195/post -d 'not-json'
   ```
2. Add input validation that throws an error for missing fields:
   ```yaml
   - mapping: |
       root = if this.user == null { throw("user is required") } else { this }
   ```
3. Switch to fire-and-forget: drop the broker and use `output: { stdout: {} }` directly. Curl receives an empty body but still 200.

---

## Why this matters

Plenty of "data pipeline" workloads are actually webhooks — Stripe, GitHub, Segment, Slack. With `http_server` + `sync_response` you can stand up a durable webhook receiver in 30 lines of YAML, with validation, enrichment and durable forwarding all built-in — no web framework, no application server.

