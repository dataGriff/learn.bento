---
title: "Enrichment with HTTP and Cache"
series: bento
order: 18
description: "Look up extra fields from an external service per event, caching the result to avoid hammering the API."
canonical_url: https://hungovercoders.com/training/bento/17-enrichment-http-cache
---

# 18 — Enrichment with HTTP and Cache

> **Goal:** look up extra fields from an external service for each event, but **cache the result** so we don't hammer the API.

**Prerequisites:** Bento installed — see [02 — Installation](../02-installation/). WarpStream running — see [12 — WarpStream Setup](../12-warpstream-setup/).

---

## What this lesson covers

| Concept | Where to look |
|---|---|
| `branch` processor — compute side data without losing the original | `config.yaml` |
| `cache` processor (operator: `get` / `set`) | `config.yaml` |
| `http` processor inside a branch | `config.yaml` |
| `cache_resources` with TTL | `config.yaml` |
| `rate_limit_resources` to protect the upstream API | `config.yaml` |

---

## The config

```yaml
input:
  generate:
    interval: 1s
    mapping: |
      let zips = ["90210","10001","73301","94016","60601"]
      root.user_id = uuid_v4()
      root.zip     = $zips.index(random_int(min:0, max:4))

cache_resources:
  - label: zip_cache
    memory:
      default_ttl: 1h

rate_limit_resources:
  - label: zip_api
    local:
      count:    5
      interval: 1s

pipeline:
  processors:

    - branch:
        request_map: 'root = this.zip'

        processors:

          - cache:
              resource: zip_cache
              operator: get
              key:      ${! content() }

          - catch:
              - http:
                  url: https://api.zippopotam.us/us/${! content() }
                  verb: GET
                  rate_limit: zip_api
              - cache:
                  resource: zip_cache
                  operator: set
                  key:      ${! meta("kafka_key").or(content().string()) }
                  value:    ${! content() }

          - mapping: |
              let body = content().parse_json()
              root.city    = $body.places.index(0).get("place name")
              root.state   = $body.places.index(0).get("state")
              root.country = $body.country

        result_map: 'root.location = this'

output:
  file:
    path:  ./out/enriched.jsonl
    codec: lines
```

**Cache-aside pattern:**

```
                  ┌──────────────────────────────┐
                  │ branch                       │
event ───────────▶│  request_map: pick zip key   │─────────────▶ event
                  │  processors:                 │             (with .location
                  │    cache GET key             │              merged in)
                  │    if MISS:                  │
                  │      http GET upstream       │
                  │      cache SET key result    │
                  │  result_map: merge into root │
                  └──────────────────────────────┘
```

**`branch`** forks the pipeline without losing the original message. `request_map` extracts the lookup key from the event (here, the zip code). The branch processors operate only on that extracted value. `result_map` merges the branch's output back into the original event.

Inside the branch: the `cache` processor with `operator: get` attempts a cache lookup. On a cache hit it returns the cached value. On a cache **miss** it sets an error flag on the message — which is exactly what `catch` handles. The `catch` block runs the HTTP lookup and immediately caches the result with `operator: set`.

**`cache_resources`** defines a named `memory` cache with a one-hour TTL. The label `zip_cache` is what the `cache` processor references.

**`rate_limit_resources`** adds a safety belt: even on a cache miss, Bento won't exceed 5 requests per second to the upstream API. The `http` processor references it via `rate_limit: zip_api`.

---

## Run it

```bash
cd docs/17-enrichment-http-cache
bento -c config.yaml
```

> Don't have the repo? `git clone https://github.com/hungovercoders/learn.bento.git`

Look at the output:

```bash
cat ./out/enriched.jsonl | jq
```

Each event will have a `location` object with `city`, `state`, and `country`. On the second run (within an hour), no HTTP calls happen — the cache is warm.

---

## Things to try

1. Turn off Wi-Fi after the cache is warm — the pipeline keeps working from cache.
2. Set `default_ttl: 5s` and watch HTTP calls resume after expiry.
3. Add a fallback for when the lookup errors:
   ```yaml
   result_map: |
     root.location = if errored() {
       { "city": "unknown", "state": "unknown", "country": "unknown" }
     } else {
       this
     }
   ```
4. Swap `memory` for `file` cache — it survives restarts.

---

## Why this matters

Cache-aside enrichment is one of the most common real-world Bento patterns. The `branch` + `cache` + `http` triad gives you Stripe-style customer lookup, GeoIP enrichment, currency conversion, feature-flag joins — all without an ORM, an HTTP framework, or a custom service.

