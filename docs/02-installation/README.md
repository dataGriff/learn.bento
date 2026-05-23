---
title: "Installation"
series: bento
order: 2
description: "Get the bento binary on your PATH in under a minute using Homebrew, direct download, or Docker."
canonical_url: https://hungovercoders.com/training/bento/02-installation
---

# 02 — Installation

One binary on your PATH. That's the whole job. Pick the method that fits your machine and let's crack on.

---

## Mac — the lazy install

```bash
brew install warpstreamlabs/tap/bento
```

Check it's alive:

```bash
bento --version
# bento version v1.x.x
```

Done. If that worked you're already ahead of anyone who's ever tried to set up Apache Flink from scratch.

---

## Linux — direct binary

```bash
# Replace VERSION/ARCH as needed — see https://github.com/warpstreamlabs/bento/releases
VERSION=v1.4.0
ARCH=linux_amd64
curl -L "https://github.com/warpstreamlabs/bento/releases/download/${VERSION}/bento_${VERSION#v}_${ARCH}.tar.gz" \
  | tar xz bento
sudo mv bento /usr/local/bin/
bento --version
```

---

## Docker — no install at all

If you'd rather not install anything locally, every config in this repo can be run via Docker:

```bash
docker run --rm -v "$PWD/docs/04-hello-world:/cfg" \
  ghcr.io/warpstreamlabs/bento:latest \
  -c /cfg/config.yaml
```

---

## Kicking the tyres

```bash
# Lint a config without running it
bento lint config.yaml

# List every available input/processor/output for the version you installed
bento list inputs
bento list processors
bento list outputs

# Full docs for a component — genuinely useful, pipe through less
bento list processors --format full | less
```

---

## VS Code schema — do this, it's worth it

Install [`redhat.vscode-yaml`](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) then add this to your `settings.json`:

```json
"yaml.schemas": {
  "https://warpstreamlabs.github.io/bento/schemas/config.json": [
    "**/bento*.yaml",
    "**/docs/**/config.yaml"
  ]
}
```

You'll get autocomplete and hover-docs for every Bento component. First time I wired this up I went back and read half the input docs I'd been ignoring — the inline help is genuinely good and saves a lot of tab-switching to the docs site.

**JetBrains:** same schema URL in *Settings → Languages & Frameworks → Schemas and DTDs → JSON Schema Mappings*.

---

Next up: [03 — Tutorial Setup](../03-tutorial-setup/) — get the repo cloned and the examples ready to run.
