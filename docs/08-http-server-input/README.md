---
title: "HTTP Server Input"
series: bento
order: 9
description: "Turn Bento into a tiny HTTP service that ingests events and returns a synchronous response."
canonical_url: https://hungovercoders.com/training/bento/08-http-server-input
---

# 09 — HTTP Server Input

I wanted to know how far I could push Bento before I needed an actual web framework. Turns out the answer is: pretty far. This lesson turns Bento into a tiny HTTP service — it listens on a port, accepts a POST, does some light processing, and fires a real JSON response back at the caller. No Express, no Flask, no application server. Thirty lines of YAML.

**Prerequisites:** Bento installed — see [02 — Installation](../02-installation/).

---

## What's going on under the hood

Four moving parts worth understanding before we look at the config:

| Concept | Where to look |
|---|---|
| `http_server` input — Bento listens on a port | `config.yaml` → `input` |
| `sync_response` output — answer the HTTP caller | `config.yaml` → `output` |
| `broker` output (`fan_out`) — log to stdout *and* respond | `config.yaml` → `output` |
| Reading and setting metadata | `config.yaml` → `pipeline` |

---

## Pulling a pint of config

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

## Two terminals, one pipeline

You'll need two terminal windows for this one. In the first, fire up the pipeline:

```bash
cd docs/08-http-server-input
bento -c config.yaml
```

> Don't have the repo? `git clone https://github.com/hungovercoders/learn.bento.git`

You'll see Bento start up and report that it's listening. In a second terminal, POST a JSON event:

```bash
curl -s -X POST http://localhost:4195/post \
  -H 'content-type: application/json' \
  -d '{"user":"griff","event":"login"}' | jq
```

You'll see the response synthesised by Bento:

```json
{
  "ok": true,
  "received_event": "login",
  "received_user": "griff",
  "request_id": "..."
}
```

The same payload is echoed in the Bento log on the server side.

I'll be honest — the first time I saw `sync_response` I assumed it was some kind of hack or niche edge-case feature. It isn't. It's exactly how you'd build a webhook receiver or a validation endpoint, and the fact that you're simultaneously writing to stdout and replying to the caller without any extra wiring still makes me happy every time.

---

## Have a go

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

Plenty of "data pipeline" workloads are actually webhooks — Stripe, GitHub, Segment, Slack. With `http_server` + `sync_response` you can stand up a durable webhook receiver in 30 lines of YAML, with validation, enrichment and durable forwarding all built-in — no web framework, no application server. Well done fellow hungovercoder, you've just built your first Bento API.
