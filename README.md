# learn.bento

A hands-on tutorial for **[Bento](https://warpstreamlabs.github.io/bento/)** — the declarative, YAML-first stream processor maintained by [WarpStream Labs](https://www.warpstream.com/).

Full lessons: **[hungovercoders.com/training/bento](https://hungovercoders.com/training/bento)**

---

## Repo layout

```
learn.bento/
├── content/                  # long-form lesson markdown (rendered on the site)
│   ├── 01-what-is-bento.md
│   ├── 02-installation.md
│   ├── 03-core-concepts.md
│   ├── 04-configuration-anatomy.md
│   ├── 05-bloblang-cheatsheet.md
│   ├── 06-warpstream-setup.md
│   └── 07-troubleshooting.md
└── examples/                 # runnable code — fork, clone, and run locally
    ├── 01-hello-world/
    ├── 02-file-to-file/
    ├── 03-http-server-input/
    ├── 04-bloblang-transform/
    ├── 05-filter-and-route/
    ├── 06-fan-out-broker/
    ├── 07-warpstream-produce/
    ├── 08-warpstream-consume-process/
    ├── 09-error-handling-dlq/
    ├── 10-windowing-aggregation/
    ├── 11-enrichment-http-cache/
    ├── 12-end-to-end-pipeline/
    ├── 13-observability/
    └── 14-testing-pipelines/
```

Each example folder has its own `README.md` with run instructions and a `config.yaml` you can use directly.

---

## Prerequisites

- **Bento** ≥ `v1.4.0` — see [`content/02-installation.md`](content/02-installation.md)
- **Docker** + **Docker Compose** — required for WarpStream examples (07–12)
- **`curl`** + **`jq`** — for examples that expose HTTP

---

## Quick start

```bash
# Run the smallest possible pipeline
bento -c examples/01-hello-world/config.yaml

# Or use the Makefile
make ex01

# Bring up a local WarpStream agent (needed for examples 07–12)
make warpstream-up
```

---

## Links

- Bento docs: <https://warpstreamlabs.github.io/bento/>
- Bloblang playground: <https://warpstreamlabs.github.io/bento/blobl/>
- WarpStream docs: <https://docs.warpstream.com/>
