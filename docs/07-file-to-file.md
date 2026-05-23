---
title: "File to File (CSV to JSON)"
series: bento
order: 7
description: "Read a CSV, coerce types with Bloblang, and write structured JSON-Lines."
canonical_url: https://hungovercoders.com/training/bento/07-file-to-file
---

# 07 — File to File (CSV to JSON)

> **Goal:** read a CSV, transform each row, write structured JSON.

**Prerequisites:** Bento installed — see [02 — Installation](02-installation.md).

---

## What this lesson covers

| Concept | Where to look |
|---|---|
| `csv` input — parses headers, emits one message per row | `config.yaml` → `input` |
| `mapping` processor in `pipeline.processors[]` | `config.yaml` → `pipeline` |
| `file` output with a static path | `config.yaml` → `output` |
| Bloblang type coercion (`.number()`, `.bool()`) | `config.yaml` |

---

## The config

```yaml
input:
  csv:
    paths:
      - ./examples/02-file-to-file/data/orders.csv
    parse_header_row: true
    delimiter: ","

pipeline:
  processors:
    - mapping: |
        root.order_id     = this.order_id.number()
        root.customer     = this.customer
        root.amount       = this.amount.number()
        root.paid         = this.paid.bool()
        root.processed_at = now()

output:
  file:
    path: ./examples/02-file-to-file/out/orders.jsonl
    codec: lines
```

**`input.csv`** reads the file, uses the first row as field names (`parse_header_row: true`), and emits one message per data row. All values arrive as strings — CSV has no type system.

**`pipeline.processors[0].mapping`** coerces types using Bloblang's built-in methods: `.number()` converts a string like `"12.50"` to the float `12.5`, and `.bool()` converts `"true"` to `true`. `now()` stamps the processing time. Without this step, every field would be a string in the output JSON.

**`output.file`** writes JSON-Lines to a file on disk. The `codec: lines` setting means one complete JSON object per line — the standard JSONL format.

When the input is exhausted (the CSV is fully read) Bento exits cleanly — no `Ctrl-C` needed.

The input CSV looks like this:

```csv
order_id,customer,amount,paid
1001,alice,12.50,true
1002,bob,99.00,false
1003,carol,7.25,true
```

---

## Run it

```bash
make ex02
```

> Don't have the repo? `git clone https://github.com/hungovercoders/learn.bento.git`

Bento reads the CSV, transforms each row, then exits. Inspect the output:

```bash
cat examples/02-file-to-file/out/orders.jsonl
```

Expected:

```json
{"order_id":1001,"customer":"alice","amount":12.5,"paid":true,"processed_at":"..."}
{"order_id":1002,"customer":"bob","amount":99,"paid":false,"processed_at":"..."}
{"order_id":1003,"customer":"carol","amount":7.25,"paid":true,"processed_at":"..."}
```

---

## Things to try

1. Add a column `currency` to the CSV — Bento picks it up automatically because `csv` is header-driven.
2. Filter unpaid orders by adding this to the mapping:
   ```yaml
   root = if !this.paid { deleted() } else { this }
   ```
3. Change the output `path` to route by `paid`:
   ```yaml
   path: "./examples/02-file-to-file/out/${! this.paid }/orders.jsonl"
   ```
4. Lint the config:
   ```bash
   bento lint examples/02-file-to-file/config.yaml
   ```

---

## Why this matters

This is the canonical batch ETL shape: bounded input, transformation, bounded output. Bento exits cleanly when the input completes — perfect for cron jobs and one-off backfills. It requires no code, no ORM, no data-frame library — only YAML and Bloblang.

Continue → [08 — HTTP Server Input](08-http-server-input.md)
