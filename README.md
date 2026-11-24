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

Private-to-private reuse inside the org works out of the box (the calling
repo must not be more visible than this one). Permissions are inherited from
the caller.

```yaml
# .github/workflows/ci.yml in a consumer repo
name: CI
on:
  push:
    branches: [main]
  pull_request:
permissions:
  contents: read
jobs:
  ci:
    uses: shoji-labs/infrastructure/.github/workflows/dotnet-ci.yml@main
```

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
