#!/usr/bin/env bash
set -euo pipefail

# Usage: /bootstrap CONFIRM=YES env=demo|dev|test|prod
# Safe by default: requires CONFIRM=YES to actually create resources.

ARGS="${*:-}"
CONFIRM="$(echo "$ARGS" | sed -n 's/.*CONFIRM=\([^ ]*\).*/\1/p')"
ENV_TIER="$(echo "$ARGS" | sed -n 's/.*env=\([^ ]*\).*/\1/p')"
ENV_TIER="${ENV_TIER:-dev}"

echo "🧩 LevelNine bootstrap starting…"
echo "• args: $ARGS"
echo "• env:  $ENV_TIER"
echo "• confirm: ${CONFIRM:-NO}"

ORG="LevelNine-Services"
REPOS=("frontend" "api" "agent-core" "infra")

dry_echo(){ echo "DRYRUN: $*"; }

create_repo(){
  local name="$1"
  if gh repo view "$ORG/$name" >/dev/null 2>&1; then
    echo "ℹ️ Repo exists: $ORG/$name"
  else
    if [[ "${CONFIRM:-NO}" == "YES" ]]; then
      gh repo create "$ORG/$name" --private --add-readme --disable-wiki=true --clone=false
      echo "✅ Created https://github.com/$ORG/$name"
    else
      dry_echo gh repo create "$ORG/$name" --private --add-readme --disable-wiki=true --clone=false
    fi
  fi
}

echo "📁 Ensuring service repos exist…"
for r in "${REPOS[@]}"; do create_repo "$r"; done

echo "🔐 Seeding secrets (example)…"
seed_secret(){
  local repo="$1" key="$2" val="$3"
  if [[ "${CONFIRM:-NO}" == "YES" ]]; then
    gh secret set "$key" -R "$ORG/$repo" --body "$val" >/dev/null || true
  else
    dry_echo gh secret set "$key" -R "$ORG/$repo" --body '***'
  fi
}
# Example only (wire real values via GH environment vars or OIDC):
# seed_secret "api" "DATABASE_URL" "$DATABASE_URL_DEV"

echo "⚙️ Pushing initial CI/workflows (stubs)…"
push_file(){
  local repo="$1" path="$2" msg="$3" content="$4"
  if [[ "${CONFIRM:-NO}" == "YES" ]]; then
    gh api -X PUT "repos/$ORG/$repo/contents/$path" \
      -f message="$msg" -f content="$content" >/dev/null
    echo "📄 $repo/$path"
  else
    dry_echo gh api -X PUT "repos/$ORG/$repo/contents/$path" -f message="$msg" -f content='…'
  fi
}

b64(){ base64 | tr -d '\n'; }

# Tiny README seeders:
push_file "frontend" "README.md" "docs: seed" "$(printf "%s" "# LevelNine Frontend" | b64)"
push_file "api"      "README.md" "docs: seed" "$(printf "%s" "# LevelNine API" | b64)"
push_file "agent-core" "README.md" "docs: seed" "$(printf "%s" "# LevelNine Agent-Core (MCP)" | b64)"
push_file "infra"    "README.md" "docs: seed" "$(printf "%s" "# LevelNine Infra (OpenTofu + Terragrunt)" | b64)"

echo "🧪 NOTE: This is a guarded bootstrap. Re-run with CONFIRM=YES to actually create resources."
echo "✅ Bootstrap completed (mode: ${CONFIRM:-DRYRUN})."
