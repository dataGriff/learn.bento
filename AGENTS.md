# learn.bento — agent context

## What this repo is

A public tutorial for Bento (declarative stream processing). It serves two purposes simultaneously:
1. A forkable, runnable tutorial people can `git clone` and use directly
2. A content source for `hungovercoders.com/training/bento`, where `docs/` files are rendered as lesson pages

## Repo layout

```
docs/       21 numbered lesson files in tutorial order (concepts + hands-on walkthroughs)
examples/   14 self-contained runnable examples (config.yaml + data), one per hands-on lesson
```

Every hands-on lesson has two files linked by the same slug: `docs/NN-slug.md` (full lesson) and `examples/NN-slug/` (runnable code). Concept-only lessons have a `docs/` file with no matching example directory.

## Conventions

**Frontmatter is required on every `docs/` file.** The site build fails without it. Required fields:

```yaml
---
title: "Human-readable title"
series: bento
order: N
description: "One sentence, no trailing period."
canonical_url: https://hungovercoders.com/training/bento/NN-slug
---
```

**Naming**: Both `docs/` files and `examples/` directories use leading-zero numbering and kebab-case slugs — `01-what-is-bento`, `03-hello-world`, etc. The numbering in `docs/` is the tutorial order; `examples/` uses its own sequential numbering (01–14) that maps to the hands-on lessons.

**YAML in `examples/`** uses 2-space indentation. No tabs.

**Example READMEs** are minimal pointers — just the title, a link to the full lesson on the site, and the run command. Full lesson content lives in `docs/`.

**Do not add placeholder values** to example configs. Every example must run as-is (`bento -c config.yaml`) without editing.
