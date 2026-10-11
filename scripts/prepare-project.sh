#!/usr/bin/env bash
set -euo pipefail
repo=${1:?Usage: prepare-project.sh owner/repository}
[[ $repo =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || exit 2
# gh must already be authenticated. Repository needs an initial commit.
sha=$(gh api "repos/$repo/commits" --jq '.[0].sha')
for branch in staging main; do
  if ! gh api "repos/$repo/git/ref/heads/$branch" >/dev/null 2>&1; then
    gh api --method POST "repos/$repo/git/refs" -f ref="refs/heads/$branch" -f sha="$sha"
  fi
done
for label in 'agent:ready' 'agent:running' 'agent:done' 'agent:failed'; do
  gh label create "$label" --repo "$repo" --color 006B75 --force
done
