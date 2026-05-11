# learn.bento

A hands-on, walk-through tutorial for **[Bento](https://warpstreamlabs.github.io/bento/)** — the
declarative, YAML-first stream processor maintained by [WarpStream Labs](https://www.warpstream.com/)
(a fork of the original [Benthos](https://www.benthos.dev/) project).

Each example is **self-contained, runnable, and incrementally introduces new
capabilities**. By the end you should be comfortable building production-grade
streaming pipelines that read from / write to **WarpStream** (Kafka-compatible),
transform data with **Bloblang**, enrich, window, route, and observe — all
without writing a single line of Go.

---

## Why Bento?

| Problem | Bento's answer |
|---|---|
| "I need glue between systems X and Y" | 50+ inputs, 50+ outputs, 80+ processors out of the box |
| "I don't want to deploy a JVM cluster" | Single static binary, ~30 MB, runs anywhere |
| "I want to express transformations declaratively" | [Bloblang](https://warpstreamlabs.github.io/bento/docs/guides/bloblang/about) — a purpose-built mapping language |
| "I need at-least-once with back-pressure" | Built into every input/output by default |
| "I want to test my pipeline" | First-class unit-test framework (`bento test`) |

Bento pairs especially well with **WarpStream** because both are designed to be
operationally cheap, BYOC-friendly, and stateless on the compute layer.

---

## Prerequisites

- **Bento** ≥ `v1.4.0` — see [`docs/02-installation.md`](docs/02-installation.md)
- **Docker** + **Docker Compose** — for the WarpStream agent and supporting services
- **`curl`** + **`jq`** — for poking pipelines that expose HTTP
- A terminal, a YAML-friendly editor, and patience for one or two YAML indentation errors

> No programming language runtime is required to follow along — Bento is configured entirely in YAML.

---

## How to use this repo

The repo is structured as **read-then-run**:

1. **Read the concept docs in [`docs/`](docs/)** — start with `01-what-is-bento.md`.
2. **Walk the examples in [`examples/`](examples/) in order** — each folder has its own
   `README.md` that explains *what's new*, *what to look at*, and *how to run it*.
3. **Use the `Makefile`** for convenience: `make ex01`, `make ex02`, …, `make warpstream-up`.

Every example follows the same shape:

```
examples/NN-name/
├── README.md          ← what you'll learn + step-by-step run instructions
├── config.yaml        ← the Bento pipeline config
└── (data/ or test/)   ← optional sample input or unit tests
```

---

## Concept docs

| # | Doc | What it covers |
|---|---|---|
| 01 | [What is Bento?](docs/01-what-is-bento.md) | Mental model, history, where it fits |
| 02 | [Installation](docs/02-installation.md) | Binary, Docker, Homebrew, verifying the install |
| 03 | [Core concepts](docs/03-core-concepts.md) | Inputs, processors, outputs, buffers, caches, rate limits, resources |
| 04 | [Configuration anatomy](docs/04-configuration-anatomy.md) | Anatomy of a `config.yaml`, env vars, includes, lints |
| 05 | [Bloblang cheat-sheet](docs/05-bloblang-cheatsheet.md) | The mapping language you will live and breathe |
| 06 | [WarpStream setup](docs/06-warpstream-setup.md) | Running a local WarpStream agent and connecting Bento |
| 07 | [Troubleshooting](docs/07-troubleshooting.md) | Common pitfalls and how to debug a pipeline |

---

## Examples — the learning path

| # | Example | Capability demonstrated |
|---|---|---|
| 01 | [Hello world](examples/01-hello-world/) | `generate` → `stdout`, the smallest possible pipeline |
| 02 | [File to file](examples/02-file-to-file/) | CSV → JSON, the `mapping` processor, structured outputs |
| 03 | [HTTP server input](examples/03-http-server-input/) | Receive events over HTTP, return synchronous responses |
| 04 | [Bloblang transform](examples/04-bloblang-transform/) | Real-world Bloblang: types, conditionals, root mutation |
| 05 | [Filter & route](examples/05-filter-and-route/) | `switch` processor, `switch` output, content-based routing |
| 06 | [Fan-out broker](examples/06-fan-out-broker/) | Send the same message to many destinations with `broker` |
| 07 | [WarpStream produce](examples/07-warpstream-produce/) | Generate events and produce to a WarpStream topic |
| 08 | [WarpStream consume + process](examples/08-warpstream-consume-process/) | Consume, enrich, write back, with consumer groups |
| 09 | [Error handling & DLQ](examples/09-error-handling-dlq/) | `try`, `catch`, `retry`, dead-letter queue topology |
| 10 | [Windowing & aggregation](examples/10-windowing-aggregation/) | `system_window` buffer + `group_by` for tumbling windows |
| 11 | [Enrichment (HTTP + cache)](examples/11-enrichment-http-cache/) | `branch` processor, HTTP enrichment, cache-aside pattern |
| 12 | [End-to-end pipeline](examples/12-end-to-end-pipeline/) | WarpStream → enrich → window → fan-out, all the things |
| 13 | [Observability](examples/13-observability/) | Prometheus metrics, OpenTelemetry tracing, structured logs |
| 14 | [Testing pipelines](examples/14-testing-pipelines/) | `bento test` — unit tests for your YAML |

---

## Quick start (5 minutes)

```bash
# 1. Install Bento (macOS)
brew install warpstreamlabs/tap/bento

# 2. Run the smallest possible pipeline
make ex01
# (or)  bento -c examples/01-hello-world/config.yaml

# 3. Bring up a local WarpStream agent
make warpstream-up

# 4. Produce real events into WarpStream
make ex07
```

---

## Cleaning up

```bash
make warpstream-down   # stop docker-compose
make clean             # remove generated data/ outputs
```

---

## Where to go next

- Official Bento docs: <https://warpstreamlabs.github.io/bento/>
- Bloblang playground: <https://warpstreamlabs.github.io/bento/blobl/>
- WarpStream docs: <https://docs.warpstream.com/>
- This repo's [`docs/07-troubleshooting.md`](docs/07-troubleshooting.md) when something doesn't work
