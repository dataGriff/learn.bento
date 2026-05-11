# 11 — Enrichment with HTTP + cache

> **Goal:** look up extra fields from an external service for each
> event, but **cache the result** so we don't hammer the API.

---

## What's new

| Concept | Where to look |
|---|---|
| `branch` processor — compute side data without losing the original | `config.yaml` |
| `cache` processor (operator: `get` / `set`) | `config.yaml` |
| `http` processor inside a branch | `config.yaml` |
| `cache_resources` with TTL | `config.yaml` |
| `rate_limit_resources` to protect the upstream API | `config.yaml` |

---

## The pattern: cache-aside enrichment

```
                  ┌──────────────────────────────┐
                  │ branch                       │
event ───────────▶│  request_map: pick lookup key│─────────────▶ event
                  │  processors:                 │             (with .country
                  │    cache GET key             │              merged in)
                  │    if MISS:                  │
                  │      http GET upstream       │
                  │      cache SET key result    │
                  │  result_map: merge into root │
                  └──────────────────────────────┘
```

The first time we see a key we hit the API; subsequent events for the same
key hit the cache.

---

## Run it

The example uses [`https://api.zippopotam.us`](https://api.zippopotam.us)
(public, no auth) to look up city/state/country from a US zip code.

```bash
make ex11
```

Look at the output:

```bash
cat examples/11-enrichment-http-cache/out/enriched.jsonl | jq
```

You'll see each event annotated with `location.{city,state,country}`.
On the *second* run within an hour, no HTTP calls happen — observe the logs.

---

## Things to try

1. Tear the network out: turn off Wi-Fi after the cache is warm — pipeline
   keeps working.
2. Set the cache `default_ttl` very low (say `5s`) and watch HTTP calls
   resume after expiry.
3. Add a fallback when the lookup errors:
   ```yaml
   - branch:
       request_map: 'root = this.zip'
       processors:
         - try:
             - http: { url: ... }
       result_map: |
         root.location = if errored() {
           { "city": "unknown" }
         } else {
           this.places.index(0)
         }
   ```
4. Swap the `memory` cache for `file` cache — survives restarts.

---

## Why this matters

Cache-aside enrichment is one of the most common real-world Bento patterns.
The `branch` + `cache` + `http` triad gives you Stripe-style customer lookup,
GeoIP enrichment, currency conversion, feature-flag joins — all without an
ORM, an HTTP framework, or a custom service.

Note: the `rate_limit` resource shown here is an extra safety belt — even
on a cache miss we won't exceed N requests per second to the upstream.

Next → [12 — End-to-end pipeline](../12-end-to-end-pipeline/)
