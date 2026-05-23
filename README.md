# learn.bento

A hands-on tutorial for **[Bento](https://warpstreamlabs.github.io/bento/)** — the declarative, YAML-first stream processor maintained by [WarpStream Labs](https://www.warpstream.com/).

Read the full tutorial: **[hungovercoders.com/training/bento](https://hungovercoders.com/training/bento)**

---

## Repo layout

```
learn.bento/
└── docs/                          # 22 lessons in tutorial order
    ├── 01-what-is-bento/
    │   └── README.md              # concept lesson — prose only
    ├── 04-hello-world/
    │   ├── README.md              # lesson content
    │   └── config.yaml            # runnable Bento config
    ├── 08-file-to-file/
    │   ├── README.md
    │   ├── config.yaml
    │   └── data/orders.csv        # sample input data
    └── ...
```

Each lesson directory contains `README.md` (the full lesson, rendered on the site and on GitHub) plus, for hands-on lessons, a `config.yaml` and any required `data/` files alongside it.

---

## Prerequisites

- **Bento** ≥ `v1.4.0` — install instructions in [docs/02-installation](docs/02-installation/README.md)
- **Docker** + **Docker Compose** — required for WarpStream examples (lessons 13–19)
- **`curl`** + **`jq`** — for the HTTP server example (lesson 09)

---

## Running the examples

Clone or fork the repo, then run any lesson directly from its directory:

```bash
git clone https://github.com/hungovercoders/learn.bento.git
cd learn.bento

# Run lesson 04 — hello world
cd docs/04-hello-world
bento -c config.yaml

# Bring up a local WarpStream agent (needed for lessons 13–19)
docker compose up -d warpstream kafka-tools
cd docs/14-warpstream-produce
bento -c config.yaml
```

---

## Links

- Full tutorial: <https://hungovercoders.com/training/bento>
- Bento docs: <https://warpstreamlabs.github.io/bento/>
- Bloblang playground: <https://warpstreamlabs.github.io/bento/blobl/>
- WarpStream docs: <https://docs.warpstream.com/>
