---
title: "Tutorial Setup"
series: bento
order: 3
description: "Fork or clone the learn.bento repo to follow along with hands-on lessons."
canonical_url: https://hungovercoders.com/training/bento/03-tutorial-setup
---

# 03 — Tutorial Setup

The hands-on lessons in this series don't make you write configs from scratch. Each lesson directory ships with a ready-to-run `config.yaml` and any sample data it needs — you clone the repo, `cd` into a lesson, and run it. The configs are there to study, break, and modify. Crack on.

**Prerequisites:** Bento installed — see [02 — Installation](../02-installation/).

---

## Fork it (recommended)

Forking gives you your own copy to experiment on, save your changes, and come back to later. If you spot something wrong in a lesson you can even send a pull request — always appreciated.

1. Head to [github.com/hungovercoders/learn.bento](https://github.com/hungovercoders/learn.bento) and hit **Fork**.
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/learn.bento.git
   cd learn.bento
   ```

---

## Or just clone it

No GitHub account, no ceremony:

```bash
git clone https://github.com/hungovercoders/learn.bento.git
cd learn.bento
```

---

## What's in the box

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

Every hands-on lesson lives in its own directory. To run any of them:

```bash
cd docs/04-hello-world
bento -c config.yaml
```

Right — you're set up. On to the first pipeline, fellow hungovercoder.
