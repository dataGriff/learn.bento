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

## Hands-on walkthrough: deploy a hosted Bento endpoint

This walkthrough gives you a concrete outcome: a public HTTP endpoint running Bento.

We'll host [`examples/03-http-server-input/config.yaml`](../examples/03-http-server-input/config.yaml)
on a Linux VM with Docker and verify it from your laptop.

### Step 1) Provision a small Linux VM

Any provider works (DigitalOcean, Hetzner, Lightsail, or a free-tier VM if available).

- Ubuntu 22.04+
- 1 vCPU / 1 GB RAM is enough for this demo
- Open inbound TCP port `22` (SSH) and `4195` (demo endpoint)

Assume your VM public IP is `203.0.113.10`.

Free option: if you can get an **Oracle Cloud Always Free** VM, the exact same steps below work.

### Step 2) SSH in and install Docker

```bash
ssh ubuntu@203.0.113.10
sudo apt-get update
sudo apt-get install -y ca-certificates curl
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
exit
```

Re-connect so group membership is refreshed:

```bash
ssh ubuntu@203.0.113.10
docker --version
```

### Step 3) Put a Bento config on the VM

Create `/opt/bento/config.yaml`:

```bash
sudo mkdir -p /opt/bento
sudo tee /opt/bento/config.yaml >/dev/null <<'YAML'
http:
  address: 0.0.0.0:4195

input:
  http_server:
    address: ""
    path: /post
    allowed_verbs: [POST]
    timeout: 5s

pipeline:
  processors:
    - mapping: |
        meta request_id = uuid_v4()
    - mapping: |
        root.ok             = true
        root.received_user  = this.user.or("anonymous")
        root.received_event = this.event.or("unknown")
        root.request_id     = meta("request_id")

output:
  sync_response: {}
YAML
```

### Step 4) Run Bento as a hosted container

```bash
docker run -d --name bento-http --restart unless-stopped \
  -p 4195:4195 \
  -v /opt/bento/config.yaml:/bento/config.yaml:ro \
  ghcr.io/warpstreamlabs/bento:latest \
  -c /bento/config.yaml
```

Check it is up:

```bash
docker ps --filter name=bento-http
docker logs --tail 20 bento-http
```

### Step 5) Verify from your local machine

```bash
curl -s -X POST http://203.0.113.10:4195/post \
  -H 'content-type: application/json' \
  -d '{"user":"alice","event":"login"}'
```

Expected response (shape):

```json
{"ok":true,"received_user":"alice","received_event":"login","request_id":"..."}
```

✅ At this point you have a hosted Bento solution reachable over the internet.

### Step 6) Production hardening (next steps)

For real workloads, add:
- TLS + auth in front of Bento (Caddy/Nginx/Cloudflare tunnel)
- firewall rules limiting who can call the endpoint
- monitoring and alerts
- a deployment method (systemd unit, compose file, or IaC) instead of ad-hoc commands

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
