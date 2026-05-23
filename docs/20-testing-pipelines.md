---
title: "Testing Pipelines"
series: bento
order: 20
description: "Unit-test your YAML — bento test runs assertions against processor logic without any real input or output."
canonical_url: https://hungovercoders.com/training/bento/20-testing-pipelines
---

# 20 — Testing Pipelines

> **Goal:** unit-test your YAML. `bento test` runs assertions against a config without ever needing a real input or output.

**Prerequisites:** Bento installed — see [02 — Installation](02-installation.md).

---

## What this lesson covers

| Concept | Where to look |
|---|---|
| `tests:` block in a sibling `*_test.yaml` | `config_test.yaml` |
| `target_processors:` — which range to test | `config_test.yaml` |
| `input_batch:` + `output_batches:` assertions | `config_test.yaml` |
| `json_equals:` for order-insensitive object matching | `config_test.yaml` |
| `error_contains:` for asserting processor errors | `config_test.yaml` |
| `bento test` CLI | run instructions below |

---

## The config under test

```yaml
input:
  file:
    paths:
      - ./examples/14-testing-pipelines/data/in.jsonl
    codec: lines

pipeline:
  processors:
    # 0: validate
    - mapping: |
        if this.qty == null || this.qty < 0 {
          throw("qty must be >= 0")
        }
        root = this

    # 1: drop empty-items orders
    - mapping: |
        root = if this.items == null || this.items.length() == 0 { deleted() } else { this }

    # 2: enrich with total + tier
    - mapping: |
        root        = this
        root.total  = this.items.map_each(i -> i.qty * i.price).sum()
        root.tier   = match {
          root.total >= 100 => "gold",
          root.total >= 25  => "silver",
          _                 => "bronze",
        }

output:
  file:
    path:  ./examples/14-testing-pipelines/out/out.jsonl
    codec: lines
```

## The test file (`config_test.yaml`)

```yaml
tests:

  - name: happy path
    target_processors: '0-2'
    input_batch:
      - content: |
          {"order_id":"o-1","qty":1,"items":[{"qty":2,"price":15},{"qty":1,"price":5}]}
    output_batches:
      -
        - json_equals:
            order_id: "o-1"
            qty:      1
            items:
              - { qty: 2, price: 15 }
              - { qty: 1, price: 5 }
            total:    35
            tier:     "silver"

  - name: drops empty items
    target_processors: '0-2'
    input_batch:
      - content: '{"order_id":"o-2","qty":0,"items":[]}'
    output_batches: []

  - name: flags negative qty as error
    target_processors: '0'
    input_batch:
      - content: '{"order_id":"o-3","qty":-1,"items":[{"qty":1,"price":5}]}'
    output_batches:
      -
        - error_contains: 'qty must be >= 0'
```

**How tests are structured:**

- `name` — identifies the test in output.
- `target_processors` — a range (`'0'`, `'0-2'`, `'1-3'`) selecting which processors to run. Bento injects the `input_batch` directly into those processors and compares the result, bypassing the real input/output entirely.
- `input_batch` — a list of messages. Each has a `content` (the raw payload string) and optionally `metadata` key-value pairs.
- `output_batches` — a list of batches, each a list of message assertions. Set to `[]` to assert that all messages were dropped.

**Assertion types:**

- `json_equals` — compares the output as a JSON object. Field order doesn't matter.
- `content_equals` — exact string match of the raw payload bytes.
- `error_contains` — asserts the message carries an error whose text contains the given string.
- `metadata_equals` — asserts a metadata field value.

The test file lives next to the config and is named `config_test.yaml`. Bento discovers it automatically when you run `bento test config.yaml`.

---

## Run it

```bash
make ex14
```

> Don't have the repo? `git clone https://github.com/hungovercoders/learn.bento.git`

You should see:

```
Test 'happy path': PASS
Test 'drops empty items': PASS
Test 'flags negative qty as error': PASS
```

A failure prints a unified diff between expected and actual output.

---

## Things to try

1. Break the tier thresholds in `config.yaml` (swap `>= 100` for `>= 50`) and re-run — see the diff.
2. Add a test for the `gold` tier: `total >= 100`.
3. Add a `metadata` assertion to verify a metadata field set in a mapping:
   ```yaml
   - metadata:
       routing_key: gold
   ```
4. Wire `bento test` into CI:
   ```bash
   bento test ./examples/**/config.yaml
   ```

---

## Why this matters

Streaming pipelines that change without tests are pipelines that silently start dropping or corrupting data. `bento test` is the single biggest reason to choose Bento over a hand-rolled stream service: your business logic is testable in isolation with no Kafka, no Docker, no fixture setup. A fast, zero-dependency test loop that runs in milliseconds.

Continue → [21 — Troubleshooting](21-troubleshooting.md)
