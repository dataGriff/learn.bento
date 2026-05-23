---
title: "Tutorial Setup"
series: bento
order: 3
description: "Fork or clone the learn.bento repo to follow along with hands-on lessons."
canonical_url: https://hungovercoders.com/training/bento/03-tutorial-setup
---

# 03 — Tutorial Setup

Every hands-on lesson ships with a ready-to-run `config.yaml` and any sample data inside its directory. You do not need to write configs from scratch — they are there to study, modify, and run.

**Prerequisites:** Bento installed — see [02 — Installation](../02-installation/).

---

## Fork then clone (recommended)

Forking gives you your own copy on GitHub to save experiments and optionally contribute back.

1. Go to [github.com/hungovercoders/learn.bento](https://github.com/hungovercoders/learn.bento) and click **Fork**.
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/learn.bento.git
   cd learn.bento
   ```

---

## Clone directly

Just want to run the examples without saving changes:

```bash
git clone https://github.com/hungovercoders/learn.bento.git
cd learn.bento
```

---

## What you get

```
learn.bento/
└── docs/
    ├── 04-hello-world/
    │   ├── README.md
    │   └── config.yaml        ← run: bento -c config.yaml
    ├── 08-file-to-file/
    │   ├── README.md
    │   ├── config.yaml
    │   └── data/orders.csv
    └── ...
```

Each hands-on lesson directory contains `config.yaml` and any required data files. Run examples from inside the lesson directory:

```bash
cd docs/04-hello-world
bento -c config.yaml
```
