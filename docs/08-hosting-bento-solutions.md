# 08 — Hosting Bento solutions

If you're asking "where can I host this?" the short answer is: **almost anywhere that runs a container**.

Bento is a single process, so hosting choices mostly come down to:
- Do you need **always-on streaming** or just scheduled/batch runs?
- How much operational control do you want?
- Do you need this to be **free** (or just very cheap)?

---

## Option 1: Single VM + systemd (simplest production baseline)

Run Bento on a small Linux VM (Hetzner, DigitalOcean, EC2 Lightsail, etc.) and manage it with `systemd`.

Pros:
- Predictable, always-on process.
- Easy to reason about logs/restarts.
- Works great for long-running Kafka/WarpStream consumers.

Cons:
- You patch and monitor the VM yourself.
- Not free long-term (usually low monthly cost).

---

## Option 2: Docker host / PaaS container runtime

Deploy the Bento container image to platforms like:
- Fly.io
- Render
- Railway
- Google Cloud Run
- Azure Container Apps
- AWS ECS/Fargate

Pros:
- Fastest path if your pipeline is already in Docker.
- Managed deploy/restart experience.

Cons:
- Free tiers often sleep, throttle, or cap runtime/network.
- Always-on streaming workloads can outgrow free tiers quickly.

---

## Option 3: Kubernetes (when you already run K8s)

If your organization already has Kubernetes, Bento fits cleanly as a Deployment.

Pros:
- Familiar scaling, rollout, and secret management primitives.
- Good fit for many pipelines with shared ops standards.

Cons:
- Overkill for a single small pipeline.
- Highest operational complexity.

---

## Can I host Bento for free?

**Yes — with caveats.** Realistic free options:

1. **Run locally** on your laptop/home server (free, best for learning/dev).
2. **Use free trial credits** from cloud providers.
3. **Use free container tiers** (Fly.io/Render/Railway-style plans), if your workload tolerates:
   - sleep/scale-to-zero,
   - low CPU/RAM,
   - limited monthly runtime/egress.

For production-like, always-on streaming consumers, expect to pay at least a small monthly amount.

---

## Recommended path for this repo

- **Learning/dev:** run locally (`make ex01` … `make ex14`) or with Docker.
- **First hosted deployment:** start with one small VM and `systemd`.
- **Scale-out / team ops:** move to container platform or Kubernetes if needed.

---

## Minimal container deployment shape

```bash
docker run --name bento-pipeline --restart unless-stopped \
  -e WARPSTREAM_BROKER=your-broker:9092 \
  -e TOPIC=orders \
  -v "$PWD/config.yaml:/bento/config.yaml:ro" \
  ghcr.io/warpstreamlabs/bento:latest \
  -c /bento/config.yaml
```

That pattern works on nearly every host with Docker support.
