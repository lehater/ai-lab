# Candidate — first optional AI module: local inference API

**Status:** PROPOSAL; no runtime accepted or deployed. Decision and image/model
versions must be confirmed from an actual `lab-test` run. The accepted
`main` remains unchanged until review/merge.

## Concrete capability and consumer

**Goal:** an operator on `lab-test` can submit a text request to a locally
hosted AI model through HTTP and receive a generated response. This is
a minimal **AI inference capability**, not an application, an agent
orchestrator, an AI platform, or a mandatory component of Infrastructure Core.

**Input:** text prompt, selected model, CPU/RAM/disk, Docker image and model
artifacts. **Output:** successful response from a running model and recorded
resource/latency evidence. **Owner:** one optional service module, not S0/S1-D.

## Tool selection (candidate)

| Option | Assessment |
| --- | --- |
| Ollama Docker (CPU) | Preferred for initial spike: official CPU container, model pull, HTTP API, minimal dependencies. |
| llama.cpp server | Good for fine-grained CPU inference/GGUF control; less convenient model lifecycle for first trial. |
| vLLM CPU | Official CPU images exist, but additional configuration is not justified for a small initial lab probe. |
| Cloud model API / gateway | Useful later if a concrete provider and API credentials are required; not needed for first no-key local inference. |

Proposed first model: `qwen3:1.7b` (about 1.4 GB download, Apache 2.0).
This is a lightweight **functional sample**, not a claim of suitable quality,
speed or reliability for any research workflow. Check free memory and disk
first. Source references:

- https://docs.ollama.com/docker
- https://docs.ollama.com/api/chat
- https://docs.ollama.com/api/openai-compatibility
- https://ollama.com/library/qwen3:1.7b
- https://docs.docker.com/engine/network/port-publishing/

## Architecture boundary

```text
operator / test client (lab-test host)
    -> http://127.0.0.1:11434
    -> optional Ollama service (Docker Compose, later)
    -> local model cache (dedicated Docker volume)
    -> model inference on CPU
```

- No ingress from LAN, no privileged container, no Docker group membership.
  Local Ollama API has **no built-in authentication**: never bind to
  `0.0.0.0`. If remote access is later required, design authorization and
  external LAN checks independently.
- Standard Compose bridge networking remains baseline (D-011). The
  **Docker daemon proxy** permits image pulls but is **not** automatically
  available for a model registry pull from *within* Ollama.
- Xray is bound to host loopback; `host.docker.internal:10808` is **not**
  a known working proxy for containers. Do not change Xray to
  `0.0.0.0` or implement a custom proxy-forwarder for this spike.
- Cache may persist between restarts. No business data, credentials or
  backups required for the first probe; models can be downloaded again.
- Avoid `restart: always`, global daemons, new packages or general-purpose
  management wrappers in the first experiment.

## Phase A — feasibility probe, not installation into Core

**Before scripting a reusable Compose module**, execute one temporary
Ollama container on the existing verified S1-D environment. Capture:

1. `git rev-parse HEAD`, `docker --version`,
   `docker compose version`, `free -h`, `df -h`; confirm port 11434
   is not already in use.
2. Pull official Ollama image with the existing Docker daemon proxy;
   record its immutable image ID/digest and actual version.
3. Start it with host publication restricted to
   `127.0.0.1:11434:11434`, no GPU and no auto-restart; use a uniquely
   named test volume.
4. Attempt `ollama pull qwen3:1.7b` **inside the container**. Record
   outcome, registry errors, elapsed time and model ID. Do not silently
   add a container-level proxy if it fails.
5. Send a non-streaming `POST /api/chat` or `POST /api/generate` with
   a short prompt; check HTTP success, valid non-empty generated content
   and response latency. Model quality is a separate evaluation.
6. Inspect Docker port bindings and stop/remove **only** the probe's
   container; delete its model volume only on an explicit cleanup
   decision. Confirm no services were changed.

**Stop condition:** if image/model registry access, memory/CPU or
host-only exposure is problematic, record failure and return to
tool/runtime choice. Do not build infrastructure workarounds before
determining whether the first AI capability is worth deploying.

### Operator commands for Phase A (on `lab-test` only)

Use the current accepted Docker baseline, not the unmerged PostgreSQL
branch. Check available RAM/disk and that TCP/11434 has no current
listener **before** running the service:

```bash
cd ~/projects/ai-lab
git rev-parse HEAD
make docker-verify
free -h
df -h "$HOME"
sudo ss -lnt '( sport = :11434 )'
sudo docker ps -a --format 'table {{.Names}}\t{{.Ports}}'
```

Only proceed if port 11434 is free and sufficient resources are available.
These commands create a private, test-only container and cache volume.
`latest` is acceptable for the **discovery probe only**; record the
immutable image ID/digest and choose a pinned version for a real module.

```bash
PROBE="ailab-ollama-probe-$(date +%s)"
VOLUME="${PROBE}-models"
sudo docker run -d --name "$PROBE" --restart no \
  -p 127.0.0.1:11434:11434 \
  -v "$VOLUME":/root/.ollama ollama/ollama:latest
sudo docker image inspect ollama/ollama:latest \
  --format 'Image={{.Id}} RepoDigests={{json .RepoDigests}}'
sudo docker exec "$PROBE" ollama pull qwen3:1.7b
sudo docker exec "$PROBE" ollama list
```

The model pull is the *first unresolved integration boundary*. If it
fails, record `sudo docker logs "$PROBE" --tail=100` and the failed
command; do **not** modify shared host proxy settings or introduce a
forwarder. If it succeeds, run one actual inference:

```bash
curl --noproxy '*' -fsS --max-time 180 \
  http://127.0.0.1:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3:1.7b","prompt":"Explain containerization in one short sentence.","stream":false,"think":false}' \
  | python3 -c 'import json,sys; r=json.load(sys.stdin); answer=r.get("response","").strip(); assert answer, r; print("RESPONSE:",answer); print("TOTAL_DURATION_NS:",r.get("total_duration"))'
sudo docker port "$PROBE"
```

Stop and remove **only the probe** after collecting its results:

```bash
sudo docker logs "$PROBE" --tail=40
sudo docker rm -f "$PROBE"
# Optional: delete the model cache only if it is no longer needed:
# sudo docker volume rm "$VOLUME"
```

Retain the model volume for repeat inference tests, or remove it
explicitly when the experiment is complete. Never run generic
`docker system prune` / `volume prune`. This operator probe is a
feasibility experiment, **not** an accepted repeatable deployment.

## Phase B — optional, only after Phase A works

Submit a small implementation PR for a single Compose-based
`modules/ollama/` with versioned manifest, documented model selection,
locally bound API, model storage, diagnostic commands, one actual
generation smoke test and narrowly scoped disable/removal. Record exact
image digest/model ID and evidence on `lab-test`. Keep it removable;
it must not become a dependency for S0, S1, S1-D or other AI modules.

**Acceptance:** real non-empty generated result; declared configuration,
reproducible setup on the supported baseline, startup/restart checks,
no accidental LAN publication, independent teardown, factual resource
metrics and retained test evidence in `docs/project/state.md`.

## Infrastructure gaps discovered vs assumed

- Real gap candidate: Ollama **model-download network path** from a
  Compose container; investigate only if it actually fails.
- Workload-specific: model cache size, CPU/RAM allocation, runtime version
  pinning and localhost API security.
- Not required yet: universal secrets, PostgreSQL, centralized metrics,
  GPU scheduling, Kubernetes, cross-provider inference gateway,
  platform-wide backup or forced-proxy network.
- No generic reusable S2 abstraction before evidence from more than one
  actual consumer.

**Related:** PR #9 is an unverified PostgreSQL fixture that does not
provide an AI capability; do not merge it as a substitute for this test.
