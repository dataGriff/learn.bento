# 10 — Windowing & aggregation

> **Goal:** group events into fixed time windows and emit one rolled-up
> message per window — the basic primitive for "events per minute"
> dashboards.

---

## What's new

| Concept | Where to look |
|---|---|
| `system_window` **buffer** — tumbling time windows by event time | `config.yaml` → `buffer` |
| `group_by_value` processor — re-batch by a Bloblang key | `config.yaml` |
| `archive` processor — collapse a batch into a single message | `config.yaml` |
| Computing per-key aggregates with Bloblang | `config.yaml` |

---

## Run it

```bash
make ex10
```

Bento generates synthetic order events as fast as the `interval`, **buffers
them into 5-second windows**, then for each window:

1. Re-groups by `customer_id`
2. Collapses each group into one rolled-up record
3. Writes to `out/windows.jsonl`

Tail the output for a few seconds to see one rollup per (customer × window):

```bash
tail -f examples/10-windowing-aggregation/out/windows.jsonl | jq
```

Sample line:

```json
{
  "window_end":   "2026-05-11T10:00:05Z",
  "customer_id":  "alice",
  "order_count":  4,
  "total_amount": 312
}
```

---

## How `system_window` works

```
event time:    | 0s -------- 5s | 5s -------- 10s | 10s -------- 15s |
records:       a  b  c  d        e  f  g           h  i
emit:                    [a,b,c,d]      [e,f,g]              [h,i]
```

Records are bucketed by their **event timestamp** (`timestamp_mapping`),
held until the window closes (with a `slack` grace period for late data),
then released as a single batch downstream — where `group_by_value` and
`archive` collapse it into per-key aggregates.

---

## Things to try

1. Change `size` from `5s` to `1m` — observe much fewer, much larger rollups.
2. Add `slack: 2s` — admit late data up to 2 seconds after a window closes.
3. Replace `archive` with a direct mapping: walk the batch with
   `batch_index()` / `batch_size()` to compute richer aggregates (p95 etc).
4. Switch `system_window` for a sliding window by setting `slide: 2s`.

---

## Why this matters

Tumbling windows are the entry point to streaming analytics —
"events per X" is the most-asked dashboard question, and Bento answers it
without needing Flink, Spark, or kSQL.

Note: heavy stateful aggregations belong in dedicated stream-processing
engines. Bento windows are *in-memory* — restart drops in-flight windows.
For larger-than-memory or durable aggregations, push to a system designed
for it (Flink, Materialize, ClickHouse).

Next → [11 — Enrichment](../11-enrichment-http-cache/)
