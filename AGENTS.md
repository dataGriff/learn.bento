# learn.bento — agent context

## What this repo is

A public tutorial for Bento (declarative stream processing). It serves two purposes simultaneously:
1. A forkable, runnable tutorial people can `git clone` and use directly
2. A content source for `hungovercoders.com/training/bento`, where `content/` files are rendered as lesson pages

## Repo layout

```
content/    long-form lesson markdown, consumed by the site build
examples/   self-contained runnable examples (one folder per example)
```

One lesson = `content/NN-slug.md` + `examples/NN-slug/`. Concept-only lessons may have a `content/` file with no matching example directory.

## Conventions

**Frontmatter is required on every `content/` file.** The site build fails without it. Required fields:

```yaml
---
title: "Human-readable title"
series: bento
order: N
description: "One sentence, no trailing period."
canonical_url: https://hungovercoders.com/training/bento/NN-slug
---
```

**Naming**: Both `content/` files and `examples/` directories use leading-zero numbering and kebab-case slugs — `01-hello-world`, `02-file-to-file`, etc.

**YAML in `examples/`** uses 2-space indentation. No tabs.

**Example READMEs** explain goals, run instructions, and things to try. Keep them self-contained — assume the reader hasn't read the full lesson.

**Do not add placeholder values** to example configs. Every example must run as-is (`bento -c config.yaml`) without editing.
