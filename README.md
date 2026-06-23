# no-ai-coauthors

`no-ai-coauthors` is a `commit-msg` hook and GitHub action.  
It rejects commit messages containing AI attribution trailers like `Co-authored-by: <bot>`.

> [!IMPORTANT]
> ```
> AI co-author git-commit bylines are an impressive marketing
> hook — but provide no useful signal of provenance.
> 
> It is mid-2026. All code written is facilitated by a host of
> sophisticated tools. The most recent of these are AI 'co-authors'.
> These have incredible utility, but as with the other tools in the
> development toolchain they are not meaningfully accountable for
> their output.
>
> At best, tagging the bot used to generate code as a 'co-author'
> in a commit messages adds noise to the single most important
> accountability and attribution mechanism in the development
> hierarchy.
> At worst the practice implies similarly diffused responsibility.
>
> As much as the act of code authorship is changing, the social rules for
> authorship must not slip: we are responsible for our contributions.
> The 'author' is, as ever, the contributing person.
>
> Remove corporate spam from commit messages. No AI co-authors.
>```

The hook is a POSIX `sh` script using `awk`, so it does not need Python, Node, Ruby, or a managed hook environment.

Public repository URL:

```text
https://github.com/GoodHatsLLC/no-ai-coauthors
```

Use the `1.0.0` tag for repeatable installation from the public URL.

## pre-commit

Add the hook repo to `.pre-commit-config.yaml`:

```yaml
default_install_hook_types: [pre-commit, commit-msg]
repos:
  - repo: https://github.com/GoodHatsLLC/no-ai-coauthors
    rev: 1.0.0
    hooks:
      - id: no-ai-coauthors
```

Then install the `commit-msg` hook:

```sh
pre-commit install --hook-type commit-msg
```

If `default_install_hook_types` includes `commit-msg`, `pre-commit install` is enough.

## prek

`prek` can consume the same `.pre-commit-config.yaml`. A native `prek.toml` entry looks like this:

```toml
default_install_hook_types = ["pre-commit", "commit-msg"]

[[repos]]
repo = "https://github.com/GoodHatsLLC/no-ai-coauthors"
rev = "1.0.0"
hooks = [{ id = "no-ai-coauthors" }]
```

Install the `commit-msg` hook:

```sh
prek install --hook-type commit-msg
```

If `default_install_hook_types` includes `commit-msg`, `prek install` is enough.

## Lefthook

This repo includes a root `lefthook.yml` and `.lefthook/commit-msg/no-ai-coauthors` so it can be used as a Lefthook remote config:

```yaml
remotes:
  - git_url: https://github.com/GoodHatsLLC/no-ai-coauthors
    ref: 1.0.0
    configs:
      - lefthook.yml
```

Then run:

```sh
lefthook install
```

## GitHub Actions

Use the repo directly as a composite action:

```yaml
name: no-ai-coauthors

on:
  pull_request:
  push:

jobs:
  no-ai-coauthors:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: read
    steps:
      - uses: GoodHatsLLC/no-ai-coauthors@1.0.0
```

On `push`, the action checks commit messages from the GitHub event payload and does not require checkout.
On `pull_request`, it reads the pull request commit list through the GitHub API. If that API lookup is not available, it falls back to the local git range `base.sha..head.sha`, which requires checkout with enough history.

You can also provide an explicit local range:

```yaml
steps:
  - uses: actions/checkout@v5
    with:
      fetch-depth: 0
  - uses: GoodHatsLLC/no-ai-coauthors@1.0.0
    with:
      commit-range: origin/main..HEAD
```

Action inputs:

- `commit-message-file`: check one commit-message file.
- `commit-range`: check messages from a local git revision range.
- `github-token`: token for reading pull request commits. Defaults to the workflow token.
- `fail-on-empty`: whether to fail if no messages are found. Defaults to `true`.

## Plain Git

Download the public hook script and configure Git's `core.hooksPath`:

```sh
mkdir -p .githooks
curl -fsSL \
  https://raw.githubusercontent.com/GoodHatsLLC/no-ai-coauthors/1.0.0/hooks/no-ai-coauthors \
  -o .githooks/commit-msg
chmod +x .githooks/commit-msg
git config core.hooksPath .githooks
```

Replace `1.0.0` with a newer released tag when you upgrade.

## Husky and simple-git-hooks

The package exposes a `no-ai-coauthors` bin for Node-oriented hook managers.

With Husky, `.husky/commit-msg` can contain:

```sh
no-ai-coauthors "$1"
```

With `simple-git-hooks`, use:

```json
{
  "simple-git-hooks": {
    "commit-msg": "no-ai-coauthors \"$1\""
  }
}
```

## Direct use

```sh
curl -fsSL \
  https://raw.githubusercontent.com/GoodHatsLLC/no-ai-coauthors/1.0.0/hooks/no-ai-coauthors \
  -o /tmp/no-ai-coauthors
chmod +x /tmp/no-ai-coauthors
/tmp/no-ai-coauthors .git/COMMIT_EDITMSG
```

## Development

```sh
sh tests/run.sh
pre-commit validate-manifest .pre-commit-hooks.yaml
```
