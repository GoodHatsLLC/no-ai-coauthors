#!/usr/bin/env sh

set -eu

repo_dir=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
hook="$repo_dir/hooks/no-ai-coauthors"
git_wrapper="$repo_dir/githooks/commit-msg"
lefthook_wrapper="$repo_dir/.lefthook/commit-msg/no-ai-coauthors"
action_wrapper="$repo_dir/github-action/check-commit-messages"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

write_msg() {
  path=$1
  shift
  {
    printf '%s\n' "feat: fixture"
    printf '\n'
    for line in "$@"; do
      printf '%s\n' "$line"
    done
  } > "$tmpdir/$path"
}

expect_block() {
  name=$1
  if "$hook" "$tmpdir/$name" >/dev/null 2>/dev/null; then
    >&2 printf 'expected block, got pass: %s\n' "$name"
    exit 1
  fi
}

expect_pass() {
  name=$1
  if ! "$hook" "$tmpdir/$name" >/dev/null 2>/dev/null; then
    >&2 printf 'expected pass, got block: %s\n' "$name"
    "$hook" "$tmpdir/$name" || true
    exit 1
  fi
}

write_msg claude 'Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>'
write_msg claude_session 'Claude-Session: https://claude.ai/share/example'
write_msg copilot 'Co-authored-by: Copilot <copilot@github.com>'
write_msg cursor 'Co-authored-by: Cursor <cursoragent@cursor.com>'
write_msg aider 'Co-authored-by: aider (openrouter/anthropic/claude-sonnet-4) <aider@aider.chat>'
write_msg opencode 'Co-authored-by: OpenCode <opencode@example.com>'
write_msg human 'Co-authored-by: Claude Shannon <claude.shannon@example.com>'
write_msg comment '# Co-authored-by: Claude <noreply@anthropic.com>'

expect_block claude
expect_block claude_session
expect_block copilot
expect_block cursor
expect_block aider
expect_block opencode
expect_pass human
expect_pass comment

if "$git_wrapper" "$tmpdir/claude_session" >/dev/null 2>/dev/null; then
  >&2 printf 'expected plain Git wrapper to block Claude-Session\n'
  exit 1
fi

if "$lefthook_wrapper" "$tmpdir/claude_session" >/dev/null 2>/dev/null; then
  >&2 printf 'expected Lefthook wrapper to block Claude-Session\n'
  exit 1
fi

if NO_AI_COAUTHORS_COMMIT_MESSAGE_FILE="$tmpdir/claude_session" \
  "$action_wrapper" >/dev/null 2>/dev/null; then
  >&2 printf 'expected GitHub Action wrapper to block commit-message-file fixture\n'
  exit 1
fi

NO_AI_COAUTHORS_COMMIT_MESSAGE_FILE="$tmpdir/human" "$action_wrapper" >/dev/null

push_event="$tmpdir/push-event.json"
cat > "$push_event" <<'JSON'
{
  "commits": [
    {
      "id": "1111111111111111111111111111111111111111",
      "message": "feat: okay\n\nCo-authored-by: Grace Hopper <grace@example.com>"
    },
    {
      "id": "2222222222222222222222222222222222222222",
      "message": "feat: bad\n\nClaude-Session: https://claude.ai/share/example"
    }
  ]
}
JSON

if GITHUB_EVENT_NAME=push GITHUB_EVENT_PATH="$push_event" \
  "$action_wrapper" >/dev/null 2>/dev/null; then
  >&2 printf 'expected GitHub Action wrapper to block push event fixture\n'
  exit 1
fi

range_repo="$tmpdir/range-repo"
mkdir "$range_repo"
git -C "$range_repo" init >/dev/null
git -C "$range_repo" config user.name "Test User"
git -C "$range_repo" config user.email "test@example.com"
printf 'one\n' > "$range_repo/file.txt"
git -C "$range_repo" add file.txt
git -C "$range_repo" commit -m "initial" >/dev/null
printf 'two\n' >> "$range_repo/file.txt"
git -C "$range_repo" add file.txt
git -C "$range_repo" commit \
  -m "feat: bad" \
  -m "Co-authored-by: Cursor <cursoragent@cursor.com>" >/dev/null

if (cd "$range_repo" && NO_AI_COAUTHORS_COMMIT_RANGE="HEAD~1..HEAD" \
  "$action_wrapper" >/dev/null 2>/dev/null); then
  >&2 printf 'expected GitHub Action wrapper to block commit-range fixture\n'
  exit 1
fi

base_sha=$(git -C "$range_repo" rev-parse HEAD~1)
head_sha=$(git -C "$range_repo" rev-parse HEAD)
pr_event="$tmpdir/pr-event.json"
cat > "$pr_event" <<JSON
{
  "pull_request": {
    "base": { "sha": "$base_sha" },
    "head": { "sha": "$head_sha" }
  }
}
JSON

if (cd "$range_repo" && GITHUB_EVENT_NAME=pull_request GITHUB_EVENT_PATH="$pr_event" \
  "$action_wrapper" >/dev/null 2>/dev/null); then
  >&2 printf 'expected GitHub Action wrapper to block pull_request git fallback fixture\n'
  exit 1
fi

printf 'no-ai-coauthors fixture checks passed\n'
