# 14 — Testing pipelines

> **Goal:** unit-test your YAML. `bento test` runs assertions against a
> config without ever needing a real input or output.

---

## What's new

| Concept | Where to look |
|---|---|
| `tests:` block in a config (or sibling `*_test.yaml`) | `config_test.yaml` |
| `target_processors:` — which range to test | `config_test.yaml` |
| `input_batch:` + `output_batches:` assertions | `config_test.yaml` |
| `metadata` assertions | `config_test.yaml` |
| `bento test` CLI | run instructions below |

---

## Run it

```bash
make ex14
# (or)  bento test examples/14-testing-pipelines/config.yaml
```

You should see:

```
Test 'happy path' [examples/14-testing-pipelines/config.yaml]: PASS
Test 'drops empty items' [examples/14-testing-pipelines/config.yaml]: PASS
Test 'flags negative qty as error' [examples/14-testing-pipelines/config.yaml]: PASS
```

A failure prints a unified diff between expected and actual output.

---

## How tests are structured

A test file (`*_test.yaml` next to a config, or inline `tests:` in the
config itself) lists named scenarios. Each one provides:

- An `input_batch` (a list of messages — payload + metadata).
- The `target_processors` to exercise (e.g. `0` for the first, or `0-2`).
- The expected `output_batches` (a list of lists of messages).
- Optional metadata assertions per message.

Bento runs the slice of pipeline you point at, against the input batch,
and compares the result.

---

## Things to try

1. Break the mapping in `config.yaml` and re-run — see the diff.
2. Add a new test for the high-value tier branch.
3. Use `json_equals:` instead of `content_equals:` for order-insensitive object matching.
4. Wire `bento test ./examples/**/config.yaml` into CI for regression coverage.

---

## Why this matters

Streaming pipelines that change without tests are streaming pipelines that
silently start dropping or corrupting data. `bento test` is the single
biggest reason to choose Bento over a hand-rolled stream service: your
business logic is testable in isolation with no Kafka, no Docker, no
fixtures.
