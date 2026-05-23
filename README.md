# learn.bento

A hands-on tutorial for **[Bento](https://warpstreamlabs.github.io/bento/)** — the declarative, YAML-first stream processor maintained by [WarpStream Labs](https://www.warpstream.com/).

Read the full tutorial: **[hungovercoders.com/training/bento](https://hungovercoders.com/training/bento)**

---

## Repo layout

```
learn.bento/
├── docs/                     # 21 lesson files — concepts and hands-on walkthroughs in tutorial order
│   ├── 01-what-is-bento.md
│   ├── 02-installation.md
│   ├── 03-hello-world.md
│   ├── 04-core-concepts.md
│   ├── ...
│   └── 21-troubleshooting.md
└── examples/                 # runnable Bento configs — one folder per example
    ├── 01-hello-world/       # config.yaml + data/
    ├── 02-file-to-file/
    ├── ...
    └── 14-testing-pipelines/
```

The `docs/` files are the lessons as rendered on the site. Each example lesson in `docs/` references the corresponding `examples/` folder for the runnable config.

---

## Prerequisites

- **Bento** ≥ `v1.4.0` — install instructions in [docs/02-installation.md](docs/02-installation.md)
- **Docker** + **Docker Compose** — required for WarpStream examples (lessons 13–18)
- **`curl`** + **`jq`** — for the HTTP server example (lesson 08)
- **`make`** — optional convenience wrapper; all examples can also be run directly with `bento -c`

---

## Running the examples

Clone this repo, then use `make` or run directly:

```bash
git clone https://github.com/hungovercoders/learn.bento.git
cd learn.bento

# Run example 01 (hello world)
make ex01
# or
bento -c examples/01-hello-world/config.yaml

# Bring up a local WarpStream agent (needed for lessons 13–18)
make warpstream-up
make ex07   # produce to WarpStream
```

Each `examples/NN-slug/` folder has a short README pointing to the full lesson on the site.

---

## Links

- Full tutorial: <https://hungovercoders.com/training/bento>
- Bento docs: <https://warpstreamlabs.github.io/bento/>
- Bloblang playground: <https://warpstreamlabs.github.io/bento/blobl/>
- WarpStream docs: <https://docs.warpstream.com/>
