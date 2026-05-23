---
title: "Bloblang Transform"
series: bento
order: 10
description: "A realistic Bloblang exercise — conditionals, type coercion, array operations, metadata, and safe access."
canonical_url: https://hungovercoders.com/training/bento/09-bloblang-transform
---

# 10 — Bloblang Transform

Bloblang is where Bento earns its keep. The previous lessons showed you the plumbing — inputs, outputs, the three-part shape. This one shows you what happens in the middle, with a realistic event shape that needs conditionals, array maths, type coercion, safe field access, and metadata. By the end you'll have a config that takes messy order events and turns them into something clean enough to actually route and analyse.

**Prerequisites:** Bento installed — see [02 — Installation](../02-installation/).

---

## What this lesson covers

Worth keeping as a reference while you read the config:

| Concept | Where to look |
|---|---|
| Multi-step Bloblang script | `config.yaml` → big `mapping` block |
| Conditional + `match` expressions | `config.yaml` |
| Array `map_each` / `filter` / `sum` | `config.yaml` |
| `.or(default)` and `.catch(default)` for safe access | `config.yaml` |
| Reading from / writing to metadata | `config.yaml` |

---

## The config — two processors doing the heavy lifting

```yaml
input:
  file:
    paths:
      - ./data/events.jsonl
    codec: lines

pipeline:
  processors:
    - mapping: |
        root = if this.items.length() == 0 { deleted() } else { this }

    - mapping: |
        root = this

        root.customer.email = this.customer.email.or("unknown@example.com").lowercase()

        root.total = this.items.map_each(item -> item.qty * item.price).sum()

        root.tier = match {
          root.total >= 200 => "gold",
          root.total >= 50  => "silver",
          _                 => "bronze",
        }

        root.is_high_value = root.tier == "gold"

        root.processed_at = now()

        meta routing_key = root.tier
        meta event_type  = "order.normalised"

output:
  file:
    path:  ./out/events.jsonl
    codec: lines
```

**Two chained mapping processors.** The first filters out useless events early: `deleted()` removes the message from the pipeline entirely — nothing downstream ever sees it.

**The second mapping** does the real work:

- `root = this` copies the entire incoming payload as the starting point.
- `.or("unknown@example.com")` provides a safe fallback for a possibly-absent field — no null-pointer, no error.
- `.lowercase()` chains directly onto the string result.
- `map_each(item -> item.qty * item.price)` iterates over the `items` array and returns a new array of numbers. `.sum()` collapses it to a single total.
- `match` is Bloblang's switch expression — evaluates top-to-bottom and returns the first matching branch's value. The bare `_` at the end is the default.
- `meta routing_key = root.tier` writes to message *metadata* (not the payload). Metadata fields are invisible in the output JSON but available to output switch cases and downstream routing.

I'll be honest — `map_each` tripped me up the first time because I kept writing it like a JavaScript `.map()` and forgetting that Bloblang's lambda syntax is `item -> expression`, not `(item) => expression`. Small thing, but annoying when you can't figure out why your array is coming back empty.

---

## Running it

```bash
cd docs/09-bloblang-transform
bento -c config.yaml
```

> Don't have the repo? `git clone https://github.com/hungovercoders/learn.bento.git`

Look at the output:

```bash
cat ./out/events.jsonl | jq
```

You'll see normalised events with:

- `customer.email` lower-cased
- `total` computed from `items[]`
- `tier` set by amount thresholds (`gold` / `silver` / `bronze`)
- `is_high_value` boolean derived from `tier`

---

## Have a go

Use `bento blobl` for interactive experimentation:

```bash
echo '{"items":[{"qty":2,"price":3.5},{"qty":1,"price":4}]}' \
  | bento blobl 'root.total = this.items.map_each(i -> i.qty * i.price).sum()'
```

Then try mutating the config:

1. Add a new field: `root.discounted_total = root.total * 0.9`.
2. Add a second guard: `root = if this.items.length() > 10 { throw("too many items") } else { this }`.
3. Use `match` to map a `currency` field from ISO codes to symbols: `"USD" => "$"`.

---

Get fluent with Bloblang here and the rest of this series is downhill, fellow hungovercoder. Everything that follows — routing, fan-out, enrichment — leans on exactly these building blocks.
