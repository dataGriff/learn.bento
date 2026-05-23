# learn.bento — agent context

## What this repo is

A public tutorial for Bento (declarative stream processing). It serves two purposes simultaneously:
1. A forkable, runnable tutorial people can `git clone` and use directly
2. A content source for `hungovercoders.com/training/bento`, where `docs/` files are rendered as lesson pages

## Repo layout

```
docs/   21 lesson directories in tutorial order — each contains README.md + (if hands-on) config.yaml + data/
```

Every lesson is a directory under `docs/`. Hands-on lessons include a runnable `config.yaml` alongside `README.md`. Concept-only lessons have only `README.md`.

```
docs/01-what-is-bento/README.md          ← concept only
docs/03-hello-world/README.md            ← hands-on
docs/03-hello-world/config.yaml          ← runnable config
docs/07-file-to-file/README.md
docs/07-file-to-file/config.yaml
docs/07-file-to-file/data/orders.csv     ← sample data
```

## Conventions

**Frontmatter is required on every `README.md`.** The site build fails without it. Required fields:

```yaml
---
title: "Human-readable title"
series: bento
order: N
description: "One sentence, no trailing period."
canonical_url: https://hungovercoders.com/training/bento/NN-slug
---
```

**Naming**: `docs/` directories use leading-zero numbering and kebab-case slugs — `01-what-is-bento`, `03-hello-world`, etc.

**YAML configs** use 2-space indentation. No tabs.

**Config file paths** use portable relative paths (`./data/orders.csv`, `./out/orders.jsonl`). All paths are relative to the lesson directory — run `bento -c config.yaml` from within the lesson folder.

**Do not add placeholder values** to configs. Every config must run as-is (`bento -c config.yaml` from the lesson directory) without editing.
