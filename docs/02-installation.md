# 02 — Installation

You only need the `bento` binary on your `PATH`. Pick whichever method fits your OS.

---

## macOS — Homebrew (recommended)

```bash
brew install warpstreamlabs/tap/bento
```

Verify:

```bash
bento --version
# bento version v1.x.x
```

---

## Linux — binary release

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

## Docker — no install

Every example in this repo can be run via Docker without installing Bento locally:

```bash
docker run --rm -v "$PWD/examples/01-hello-world:/cfg" \
  ghcr.io/warpstreamlabs/bento:latest \
  -c /cfg/config.yaml
```

The `Makefile` wraps this so you can simply run `make ex01` and not memorize the Docker command.

---

## Verifying things work

```bash
# Lint a config without running it
bento lint examples/01-hello-world/config.yaml

# List every available input/processor/output for the version you installed
bento list inputs
bento list processors
bento list outputs

# Print the rich docs for a single component
bento list processors --format full | less
```

---

## Editor support

- **VS Code** — install [`redhat.vscode-yaml`](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) and add to your `settings.json`:

  ```json
  "yaml.schemas": {
    "https://warpstreamlabs.github.io/bento/schemas/config.json": [
      "**/bento*.yaml",
      "**/examples/**/config.yaml"
    ]
  }
  ```

  You'll get autocomplete and hover-docs for every component — a huge productivity win.

- **JetBrains** — paste the same schema URL in *Settings → Languages & Frameworks → Schemas and DTDs → JSON Schema Mappings*.

---

Continue → [03 — Core concepts](03-core-concepts.md)
