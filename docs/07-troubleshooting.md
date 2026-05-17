# 07 — Troubleshooting

Things that will go wrong, in roughly the order you'll hit them.

---

## "Bento config failed to validate"

Run the linter — it tells you which line and which field:

```bash
bento lint examples/04-bloblang-transform/config.yaml
```

Common causes:
- A field name typo (`procesors:` vs `processors:`).
- A processor placed at the wrong nesting level (e.g. `mapping` directly under `pipeline:` instead of under `pipeline.processors[]`).
- YAML indentation mixing tabs and spaces.

---

## "I can't see any messages"

Add a `log` processor at the start of your pipeline:

```yaml
pipeline:
  processors:
    - log:
        level: INFO
        message: "got message: ${! content() }"
    - mapping: |
        root = this
```

Bump the global log level if needed:

```yaml
logger:
  level: DEBUG
  format: logfmt
```

---

## "My Bloblang isn't doing what I expect"

Use `bento blobl` as an interactive REPL:

```bash
bento blobl 'root.upper = this.name.uppercase()' <<<'{"name":"foo"}'
# {"upper":"FOO"}
```

Or use the playground: <https://warpstreamlabs.github.io/bento/blobl/>.

Tip: a missing field returns `null`, not an error. Use `.or(default)` or `.catch(default)`:

```coffee
root.email = this.user.email.or("unknown")
```

---

## "Connection refused" on Kafka / WarpStream

Checklist:
1. Is the agent running? `docker compose ps warpstream`
2. Is the port published? `docker compose port warpstream 9092`
3. Are you using `localhost:9092` from the host, but `warpstream:9092` from inside another container?
4. Did the topic exist? `make ws-topics`

When in doubt, set Bento log level to `DEBUG` — the `kafka_franz` client logs every connect attempt.

---

## "Slow output is making my input back-pressured"

That is *intended behaviour*. Bento back-pressures by design. If you genuinely
want to decouple, add a buffer:

```yaml
buffer:
  memory:
    limit: 10485760    # 10 MiB
```

…but understand: an in-memory buffer means **lost data on crash**. For
durable buffering, use the upstream system (Kafka).

---

## "Errors in some messages crash the whole batch"

Errors don't crash Bento — they flag the message. By default flagged messages
still flow downstream (which is usually wrong). Wrap risky steps:

```yaml
pipeline:
  processors:
    - try:
        - http:
            url: https://example.com
        - mapping: 'root.enriched = this'

# Then route errored messages to a DLQ:
output:
  switch:
    cases:
      - check: errored()
        output: { kafka_franz: { topic: orders.dlq, ... } }
      - output: { kafka_franz: { topic: orders.processed, ... } }
```

See `examples/09-error-handling-dlq` for the full pattern.

---

## "Bento eats CPU"

Most likely causes:
1. `pipeline.threads` is too high for your workload.
2. A `mapping` does heavy regex / hashing per message.
3. The `generate` input has `interval: ""` (which means *as fast as possible*).

Profile with the built-in pprof:

```bash
bento -c config.yaml --debug
# then  go tool pprof http://localhost:4195/debug/pprof/profile
```

---

## "I want to test a config without side effects"

```bash
bento -c config.yaml --dry-run
```

This still consumes the input, but **all outputs are replaced with `drop`**.
Useful for measuring throughput / processor cost.

---

## When all else fails

- The official docs are excellent: <https://warpstreamlabs.github.io/bento/>
- Bento Discord (linked from the docs) is responsive.
- `bento list processors --format full` is the comprehensive offline reference.

Continue → [08 — Hosting Bento solutions](08-hosting-bento-solutions.md)
