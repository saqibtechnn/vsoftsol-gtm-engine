# Phase D3 — Container & Image Supply Chain

**Lead subagent:** `container-engineer`
**Prerequisite:** D2 gate signed

## Objective
Trustworthy, minimal, reproducible images with a verifiable supply chain.

## Deliverables
1. Multi-stage Dockerfiles for `api`, `worker`, `scheduler`, `console`:
   - minimal base pinned **by digest** (distroless or slim)
   - non-root user; read-only root filesystem where feasible
   - no build tooling in the runtime layer
   - healthcheck defined
2. `.dockerignore` that provably excludes secrets, `.env`, test fixtures, `.git`.
3. Deterministic dependency installation from lockfiles only.
4. SBOM per image (Syft), committed as a build artefact.
5. Vulnerability scanning (Trivy or Grype) in the build with a failing threshold — no suppressions added to pass.
6. Image signing with cosign; signature **verification enforced at deploy time**.
7. GHCR publishing with immutable semantic tags plus digest pinning in deployment manifests.
8. `deploy/docs/IMAGE_POLICY.md` — base image policy, update cadence, size budgets, scan thresholds.

## Verification
- [ ] Build twice; compare digests and SBOMs for reproducibility.
- [ ] Confirm each container runs as non-root (`id` inside the container).
- [ ] Introduce a known-vulnerable dependency; confirm the build **fails**.
- [ ] Attempt to deploy an unsigned image; confirm rejection.
- [ ] Inspect all image layers for secrets, `.env` files or fixtures; evidence their absence.
- [ ] Confirm each image is within its documented size budget.

## Exit gate
All images signed, scanned, non-root and within budget. Tag `deploy-v0.3.0`.
