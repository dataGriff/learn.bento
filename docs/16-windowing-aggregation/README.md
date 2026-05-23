---
title: "Windowing and Aggregation"
series: bento
order: 17
description: "Group events into fixed time windows and emit one rolled-up message per window."
canonical_url: https://hungovercoders.com/training/bento/16-windowing-aggregation
---

# 17 — Windowing and Aggregation

I wanted to get to this lesson from the start. This is where Bento gets properly interesting. Up until now, every message has moved through the pipeline one at a time — in, processed, out. Windowing changes that. We hold events, wait for a time boundary, then emit one rolled-up summary per window. "Events per minute" dashboards, rolling totals, per-customer order counts — this is how you build all of that in pure YAML.

**Prerequisites:** Bento installed — see [02 — Installation](../02-installation/). WarpStream running — see [12 — WarpStream Setup](../12-warpstream-setup/).

---

Here's what this lesson pulls together:

| Concept | Where to look |
|---|---|
| `system_window` **buffer** — tumbling time windows by event time | `config.yaml` → `buffer` |
| `group_by_value` processor — re-batch by a Bloblang key | `config.yaml` |
| `archive` processor — collapse a batch into a single message | `config.yaml` |
| Computing per-key aggregates with Bloblang | `config.yaml` |

---

## The config

```yaml
input:
  generate:
    interval: 200ms
    mapping: |
      let customers = ["alice","bob","carol"]
      root.order_id    = uuid_v4()
      root.customer_id = $customers.index(random_int(min:0, max:2))
      root.amount      = random_int(min:1, max:100)
      root.event_time  = now()

buffer:
  system_window:
    timestamp_mapping: 'root = this.event_time'
    size:  5s
    slack: 1s

pipeline:
  processors:
    - group_by_value:
        value: ${! this.customer_id }

    - archive:
        format: json_array

    - mapping: |
        root.window_end   = now()
        root.customer_id  = this.index(0).customer_id
        root.order_count  = this.length()
        root.total_amount = this.map_each(o -> o.amount).sum()

output:
  file:
    path:  ./out/windows.jsonl
    codec: lines
```

**`buffer.system_window`** is Bento's windowing primitive. Instead of messages flowing through immediately, they accumulate in the buffer until the window closes.

- `timestamp_mapping` tells Bento which field to use as event time. `root = this.event_time` extracts the timestamp from the payload. For Kafka inputs, you could use `meta("kafka_timestamp")`.
- `size: 5s` means each window is exactly 5 seconds of event time.
- `slack: 1s` admits late-arriving messages up to 1 second after the window closes — a grace period for out-of-order events.

When a window closes, the buffer releases the entire batch of accumulated messages downstream at once.

**`group_by_value`** operates on that batch. It re-partitions the batch by a Bloblang expression — here `customer_id`. Each unique key becomes its own sub-batch. Processors after `group_by_value` run once per sub-batch.

**`archive`** with `format: json_array` collapses a sub-batch of N messages into a single message whose payload is a JSON array. This gives the next processor a single message to work with rather than N individual messages.

**The final mapping** operates on that JSON array. `this.index(0).customer_id` reads the first element's `customer_id` (all elements share the same key from `group_by_value`). `this.length()` is the count. `this.map_each(o -> o.amount).sum()` sums the `amount` field across all orders in the window.

---

## How tumbling windows actually behave

```
event time:    | 0s -------- 5s | 5s -------- 10s | 10s -------- 15s |
records:       a  b  c  d        e  f  g           h  i
emit:                    [a,b,c,d]      [e,f,g]              [h,i]
```

I'll be honest — when I first saw the window buffer docs I expected something heavier, more like a Flink job. It's not. It's a buffer section in a YAML file and it does exactly what it says on the tin.

---

## Run it

```bash
cd docs/16-windowing-aggregation
bento -c config.yaml
```

> Don't have the repo? `git clone https://github.com/hungovercoders/learn.bento.git`

Tail the output for a few seconds:

```bash
tail -f ./out/windows.jsonl | jq
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

## Have a go

1. Change `size` from `5s` to `1m` — observe much fewer, much larger rollups.
2. Add `slack: 2s` — admit late data up to 2 seconds after a window closes.
3. Replace `archive` with a direct `batch_index()` / `batch_size()` mapping to compute richer per-batch aggregates like a running maximum.
4. Switch to a sliding window by adding `slide: 2s` to `system_window`.

---

## Why tumbling windows matter

Tumbling windows are the entry point to streaming analytics — "events per X" is the most-asked dashboard question, and Bento answers it without needing Flink, Spark, or kSQL.

Note: Bento windows are in-memory. Restarting the pipeline drops any in-flight window data. For durable, large-scale stateful aggregation, push results to ClickHouse, Materialize, or Flink rather than relying solely on Bento's buffer.
