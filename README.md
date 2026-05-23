# learn.bento

A hands-on tutorial for **[Bento](https://warpstreamlabs.github.io/bento/)** — the declarative, YAML-first stream processor maintained by [WarpStream Labs](https://www.warpstream.com/).

Read the full tutorial: **[hungovercoders.com/training/bento](https://hungovercoders.com/training/bento)**

---

## Repo layout

```
learn.bento/
└── docs/                          # 21 lessons in tutorial order
    ├── 01-what-is-bento/
    │   └── README.md              # concept lesson — prose only
    ├── 03-hello-world/
    │   ├── README.md              # lesson content
    │   └── config.yaml            # runnable Bento config
    ├── 07-file-to-file/
    │   ├── README.md
    │   ├── config.yaml
    │   └── data/orders.csv        # sample input data
    └── ...
```

Each lesson directory contains `README.md` (the full lesson, rendered on the site and on GitHub) plus, for hands-on lessons, a `config.yaml` and any required `data/` files alongside it.

---

## Prerequisites

- **Bento** ≥ `v1.4.0` — install instructions in [docs/02-installation](docs/02-installation/README.md)
- **Docker** + **Docker Compose** — required for WarpStream examples (lessons 13–18)
- **`curl`** + **`jq`** — for the HTTP server example (lesson 08)
- **`make`** — optional convenience wrapper; all examples can also be run directly with `bento -c`

---

## Running the examples

Clone this repo, then use `make` or run directly from the lesson directory:

```bash
git clone https://github.com/hungovercoders/learn.bento.git
cd learn.bento

# Run lesson 03 — hello world
make ex01
# or run directly:
cd docs/03-hello-world && bento -c config.yaml

# Bring up a local WarpStream agent (needed for lessons 13–18)
make warpstream-up
make ex07   # produce to WarpStream
```

---

## Links

- Full tutorial: <https://hungovercoders.com/training/bento>
- Bento docs: <https://warpstreamlabs.github.io/bento/>
- Bloblang playground: <https://warpstreamlabs.github.io/bento/blobl/>
- WarpStream docs: <https://docs.warpstream.com/>
