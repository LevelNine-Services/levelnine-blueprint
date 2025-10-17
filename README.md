# levelnine-blueprint

Cloud-only blueprint, ChatOps, and automation for **LevelNine-Services**.

## How to use (ChatOps)
Post comments in this repo (Issues or PRs):

- `/bootstrap CONFIRM=YES env=dev` — create/seed service repos (guarded; requires CONFIRM=YES)
- `/deploy env=dev` — run deploy flow stub (wire to Vercel/Fly)
- `/db:provision env=demo` — provision DB (Supabase/Neon/Render/Fly)
- `/secrets:sync` — sync secrets to child repos

All actions run in **GitHub Actions** (no local execution).
