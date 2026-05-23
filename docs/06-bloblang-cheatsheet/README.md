---
title: "Bloblang Cheat-Sheet"
series: bento
order: 6
description: "The complete Bloblang quick reference: roots, metadata, functions, string and number methods, conditionals, and filtering."
canonical_url: https://hungovercoders.com/training/bento/06-bloblang-cheatsheet
---

# 06 — Bloblang Cheat-Sheet

[Bloblang](https://warpstreamlabs.github.io/bento/docs/guides/bloblang/about) is
the assignment-based mapping language at the heart of Bento. You will write it
constantly. Bookmark this page.

There's an interactive playground at <https://warpstreamlabs.github.io/bento/blobl/>
— use it.

---

## The two roots

```coffee
root = ...     # build a brand-new message payload
this = ...     # the incoming message payload (read-only conceptually)
```

`root = this` is the identity transform.

You can also assign to specific paths:

```coffee
root.user.email = this.user.email.lowercase()
root.processed_at = now()
```

Anything not assigned is **dropped**. Start with `root = this` if you want to keep everything.

---

## Metadata

```coffee
meta("kafka_topic")            # read
meta foo = "bar"               # write
root.partition = meta("kafka_partition").number()
```

---

## Common functions

| Function | Example | Result |
|---|---|---|
| `now()`                    | `root.ts = now()`             | RFC3339 timestamp |
| `timestamp_unix()`         | `root.ts = timestamp_unix()`  | seconds since epoch |
| `uuid_v4()`                | `root.id = uuid_v4()`         | UUID |
| `hostname()`               | `meta host = hostname()`      | machine hostname |
| `env("VAR")`               | `root.tier = env("TIER")`     | env var (compile-time) |
| `random_int(min:0,max:9)`  | `root.r = random_int()`       | random int |

---

## String methods

```coffee
this.email.lowercase()
this.body.trim()
this.name.split(" ")
this.body.replace_all("foo", "bar")
this.id.hash("sha256").encode("hex")
this.payload.parse_json()
this.json_str.format_json(indent: "  ")
```

---

## Number / time methods

```coffee
this.amount * 100
this.amount.round()
this.created_at.ts_parse("2006-01-02T15:04:05Z").ts_unix()
this.created_at.ts_format("Mon, 02 Jan 2006")
```

---

## Conditionals

```coffee
root.tier = if this.balance > 1000 { "gold" } else { "standard" }

root.status = match this.code {
  200 => "ok",
  404 => "missing",
  _   => "error",
}
```

---

## Filtering / dropping a message

```coffee
root = if this.amount < 0 { deleted() } else { this }
```

`deleted()` removes the message from the stream.

---

## Working with arrays

```coffee
root.totals = this.items.map_each(item -> item.qty * item.price).sum()

root.adults = this.people.filter(p -> p.age >= 18)

root.first_name = this.people.index(0).name

root.flat = this.tags.fold("", t1, t2 -> "%s,%s".format(t1, t2))
```

---

## JSON parsing

When upstream sends a JSON-encoded string inside a JSON envelope:

```coffee
let inner = this.body.parse_json()
root = inner
root.envelope_id = this.id
```

---

## Errors are values

If a step fails (e.g. `parse_json()` on garbage), the message is **flagged**
but processing continues. Use:

```coffee
root.parsed = this.body.parse_json().catch({})       # default-on-error
root.is_bad = errored()                              # boolean
```

…or wrap with the `try` / `catch` processors at the pipeline level.

---

## Real example — putting it together

Input:
```json
{ "user": { "email": "Foo@Bar.com" }, "amount": "12.50", "items": ["a","b"] }
```

Mapping:
```coffee
root = this
root.user.email   = this.user.email.lowercase()
root.amount       = this.amount.number()
root.item_count   = this.items.length()
root.processed_at = now()
meta tier         = if root.amount > 100 { "high" } else { "low" }
```

Output:
```json
{
  "user": {"email": "foo@bar.com"},
  "amount": 12.5,
  "items": ["a","b"],
  "item_count": 2,
  "processed_at": "2026-05-11T10:00:00Z"
}
```

…with metadata `tier=low` set on the message.

---

