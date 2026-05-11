# 04 — Bloblang transform

> **Goal:** see Bloblang earn its keep on a realistic event shape —
> conditionals, type coercion, array operations, metadata, error handling.

---

## What's new

| Concept | Where to look |
|---|---|
| Multi-step Bloblang script | `config.yaml` → big `mapping` block |
| Conditional + `match` expressions | `config.yaml` |
| Array `map_each` / `filter` / `sum` | `config.yaml` |
| `.or(default)` and `.catch(default)` for safe access | `config.yaml` |
| Reading from / writing to metadata | `config.yaml` |

---

## The data

`data/events.jsonl` — five raw events, each slightly different in shape.

---

## Run it

```bash
make ex04
```

Look at the output:

```bash
cat examples/04-bloblang-transform/out/events.jsonl | jq
```

You'll see normalised events with:

- `customer.email` lower-cased
- `total` re-computed from `items[]`
- `tier` set by amount thresholds (`gold` / `silver` / `bronze`)
- `is_high_value` boolean derived from `tier`
- Metadata `routing_key` populated for downstream routing

---

## Things to try

Open `bento blobl` interactively:

```bash
echo '{"items":[{"qty":2,"price":3.5},{"qty":1,"price":4}]}' \
  | bento blobl 'root.total = this.items.map_each(i -> i.qty * i.price).sum()'
```

Try mutating the mapping in `config.yaml`:

1. Add a new field `discounted_total = root.total * 0.9`.
2. Add a guard: `root = if this.items.length() == 0 { deleted() } else { this }`.
3. Use `match` to map a `currency` field from ISO codes to symbols.

---

## Why this matters

Bloblang **is** the value Bento adds beyond plumbing. Everything in this
example — type coercion, conditionals, derived fields, defaults, metadata —
appears in every real pipeline. Get fluent here and the rest is downhill.

Next → [05 — Filter & route](../05-filter-and-route/)
