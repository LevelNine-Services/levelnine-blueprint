# LevelNine Actionable Blueprint

The blueprint below is an execution-only playbook. Follow the steps in order; each checklist must be satisfied before advancing.

## 0. Prerequisites
- [ ] Fork or clone `levelnine-blueprint` with GitHub Actions enabled.
- [ ] Grant Codex ChatOps bot `contents:write` and `workflows` scopes.
- [ ] Populate mandatory repository secrets: `OPENAI_API_KEY`, `OPENAI_TTS_MODEL`, `OPENAI_TTS_VOICE`, `STABILITY_API_KEY`, `FLY_API_TOKEN`, `VERCEL_TOKEN`, `SUPABASE_SERVICE_ROLE`, `POSTGRES_URL`.
- [ ] Confirm `infra/terragrunt.hcl` references the correct GitHub org/repo.

## 1. Bootstrap Infrastructure
- [ ] In the root PR or issue comment, run `/bootstrap tier=demo`.
- [ ] Wait for `.github/workflows/bootstrap.yml` to succeed; review state outputs in the logs.
- [ ] After success, capture the emitted `demo` connection details and store them in `config/env-manifest.json`.
- [ ] Repeat the same `/bootstrap` command for `tier=dev` once demo validates.

## 2. Rotate Critical Secrets
- [ ] Trigger `/rotate-secrets tier=demo` and `/rotate-secrets tier=dev` sequentially.
- [ ] Validate GitHub Actions uploaded `secrets.json` artifacts; archive them in the secure vault.
- [ ] Update the shared secret index in `docs/security.md` (or create it if missing).

## 3. Provision Application Services
- [ ] Run `/apply target=infra/core tier=demo`.
- [ ] Confirm Fly.io app, Redis, and Postgres resources exist via provider dashboards.
- [ ] Execute `/apply target=infra/core tier=dev` after demo verification.
- [ ] Record provisioned resource IDs in `config/env-manifest.json`.

## 4. Deploy Runtime Services
### Frontend (`frontend` → Vercel)
- [ ] Merge latest main to ensure build cache availability.
- [ ] Run `/deploy service=frontend tier=demo`.
- [ ] Verify Vercel preview URL responds with healthy status badge.
- [ ] Promote to dev using `/deploy service=frontend tier=dev`.

### API (`api` → Fly.io)
- [ ] Check `supabase`/`postgres` connection strings in GitHub Actions secrets.
- [ ] Issue `/deploy service=api tier=demo`.
- [ ] Hit `/healthz` endpoint and log response in the deployment tracker.
- [ ] Repeat for dev once demo passes checks.

### Agent Core (`agent-core` → Fly.io)
- [ ] Ensure provider keys (OpenAI, Ollama, Stability) and TTS configuration (`OPENAI_TTS_MODEL`, `OPENAI_TTS_VOICE`) exist in tiered secrets.
- [ ] Run `/deploy service=agent-core tier=demo`.
- [ ] Execute the smoke test script `scripts/agent-smoke.sh demo`.
- [ ] Move to dev after demo passes smoke tests.

## 5. Quality Gates
- [ ] Execute `/plan target=infra` before any infrastructure PR merge.
- [ ] Observe `chatops` workflow output; resolve drift before re-running `/apply`.
- [ ] For code services, require `bun test`, `pnpm test`, and `pnpm lint` in CI prior to deployment.
- [ ] Document exceptions or waivers in `docs/quality-gates.md`.

## 6. Cutover to Production
- [ ] Promote database schema using `/apply target=infra/db tier=prod`.
- [ ] Deploy API and Agent Core to `prod` with `--canary=25%` flag in the command payload.
- [ ] After 30 minutes of stable metrics, run `/deploy service=frontend tier=prod`.
- [ ] Announce completion in the #ops channel with links to workflow runs.

## 7. Ongoing Operations
- [ ] Schedule `/rotate-secrets tier=*` weekly via GitHub Actions workflow dispatch.
- [ ] Review `plan` workflow outputs for drift every Tuesday.
- [ ] Regenerate provider credentials quarterly and update vault references.
- [ ] Post an ops summary in `docs/runbooks/ops-journal.md` at the end of each sprint.
