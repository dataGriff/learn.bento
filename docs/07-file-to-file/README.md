---
title: "File to File (CSV to JSON)"
series: bento
order: 8
description: "Read a CSV, coerce types with Bloblang, and write structured JSON-Lines."
canonical_url: https://hungovercoders.com/training/bento/07-file-to-file
---

# 08 — File to File (CSV to JSON)

I wanted a dead-simple hands-on pipeline that shows Bento doing real ETL work without needing a running broker or database. This one reads a CSV of orders, coerces the types with Bloblang, and writes structured JSON-Lines to disk. It's the canonical batch shape: bounded input, transformation, bounded output — and Bento exits cleanly when the CSV is exhausted. No `Ctrl-C` required.

**Prerequisites:** Bento installed — see [02 — Installation](../02-installation/).

---

## Cracking open the CSV — the input

```yaml
input:
  csv:
    paths:
      - ./data/orders.csv
    parse_header_row: true
    delimiter: ","
```

The `csv` input reads the file, uses the first row as field names (`parse_header_row: true`), and emits one message per data row. Every value arrives as a string — CSV has no type system, so that's all it can do.

The input file looks like this:

```csv
order_id,customer,amount,paid
1001,griff,18.50,true
1002,morgan,42.00,false
1003,rhys,27.75,true
```

---

## Giving the data a shape — the processor

```yaml
pipeline:
  processors:
    - mapping: |
        root.order_id     = this.order_id.number()
        root.customer     = this.customer
        root.amount       = this.amount.number()
        root.paid         = this.paid.bool()
        root.processed_at = now()
```

This is where the type coercion happens. `.number()` converts `"12.50"` to the float `12.5`; `.bool()` converts `"true"` to `true`. Without this step every field would be a string in the output — which is usually not what you want downstream. `now()` stamps the row with a processing timestamp while we're at it.

I'll be honest — forgetting this coercion step is something I've done more than once. You look at the output and everything looks right until something downstream tries to do arithmetic on a string and falls over.

---

## Pouring the output — writing JSON-Lines

```yaml
output:
  file:
    path: ./out/orders.jsonl
    codec: lines
```

`codec: lines` means one complete JSON object per line — the standard JSONL format. Simple, appendable, and readable with `cat`.

---

## Running it

```bash
cd docs/07-file-to-file
bento -c config.yaml
```

> Don't have the repo? `git clone https://github.com/hungovercoders/learn.bento.git`

Bento reads the CSV, transforms each row, writes the output, then exits. Inspect what it produced:

```bash
cat ./out/orders.jsonl
```

Expected:

```json
{"order_id":1001,"customer":"griff","amount":18.5,"paid":true,"processed_at":"..."}
{"order_id":1002,"customer":"morgan","amount":42,"paid":false,"processed_at":"..."}
{"order_id":1003,"customer":"rhys","amount":27.75,"paid":true,"processed_at":"..."}
```

---

## Have a go

1. Add a column `currency` to the CSV — Bento picks it up automatically because `csv` is header-driven.
2. Filter unpaid orders by adding this to the mapping:
   ```yaml
   root = if !this.paid { deleted() } else { this }
   ```
3. Change the output `path` to route by `paid`:
   ```yaml
   path: "./out/${! this.paid }/orders.jsonl"
   ```
4. Lint the config:
   ```bash
   bento lint config.yaml
   ```

---

## Why this shape matters

No code, no ORM, no data-frame library — only YAML and Bloblang. This is what makes Bento genuinely useful for cron jobs and one-off backfills: the pipeline describes the transformation declaratively, Bento handles the plumbing, and when the input is exhausted it gets out of the way. Read on, fellow hungovercoder.
