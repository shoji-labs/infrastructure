# infrastructure

Shared CI/CD material for the `shoji-labs` repos: reusable workflow
templates, release-please configuration, and the self-hosted runner setup.

## Contents

| Path | Purpose |
| --- | --- |
| `.github/workflows/dotnet-ci.yml` | Reusable `workflow_call` build+test matrix (Windows, Linux; macOS on `main` only). |
| `.github/workflows/dotnet-release.yml` | Reusable `workflow_call` release-please chain, self-contained for private repos (GITHUB_TOKEN only). |
| `release-please/` | Config/manifest templates + the `x-release-please-version` marker pattern. |
| `runners/` | Install script and LaunchAgent for the self-hosted macOS runner on OscarsMacStudio. |

## Consuming the reusable workflows

**This repo must stay public.** GitHub cannot resolve a cross-repo `uses:`
reference to a private reusable workflow - the calling workflow fails
validation before any job is scheduled (verified 2026-11-24 on every event
type). Consumer repos may be private; that direction is fine.

```yaml
# .github/workflows/ci.yml in a consumer repo
name: CI
on:
  push:
    branches: [main]
  pull_request_target:
permissions:
  contents: read
jobs:
  ci:
    uses: shoji-labs/infrastructure/.github/workflows/dotnet-ci.yml@main
```

PRs trigger with `pull_request_target` (workflow evaluated on the base branch,
full repo token). The shared workflow then checks out `refs/pull/N/merge` so
PR code is still what gets built. Safe while branches come only from trusted
authors - which, in this org, they do. Note the trigger must already exist on
`main` to fire: the PR that introduces it cannot have its own green check.

```yaml
# .github/workflows/release.yml in a consumer repo
name: Release
on:
  push:
    branches: [main]
permissions:
  contents: write
  pull-requests: write
jobs:
  release:
    uses: shoji-labs/infrastructure/.github/workflows/dotnet-release.yml@main
```

Pin to a tag instead of `@main` if you want template changes to be explicit
upgrades.

## Why the macOS matrix is `main`-only

The org is on the free plan: macOS minutes bill at 10x and consumed most of
October's quota. Pull requests therefore run Windows+Linux only, and pushes to
`main` add macOS. The self-hosted ARM64 Mac carries the `macos-latest` label,
so when it is online it takes those jobs and no hosted minutes are spent;
when it is offline the run falls back to the hosted runner.
