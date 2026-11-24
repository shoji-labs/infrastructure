# release-please templates

Per-repo setup for version + changelog automation. This repo stores the
templates; each consumer keeps its own copy at the repo root, because the
release PR commits them into the consumer's history.

## Setup in a consumer repo

1. Copy `release-please-config.json` to the repo root. Set `package-name`,
   and list the files carrying a version marker in `extra-files`
   (`Directory.Build.props` for .NET, `ModuleName.psd1` for PowerShell
   modules).
2. Leave `.release-please-manifest.json` absent or `{}` on the first run -
   release-please bootstraps it and commits it on the first release PR.
3. Add `release.yml` - normally just the `uses:` call to
   `.github/workflows/dotnet-release.yml@main` (see the root README).
4. Put the version marker in `Directory.Build.props` (or the psd1):

   ```xml
   <!-- Bumped by release-please (generic updater): keep the marker on this line. -->
   <Version>0.1.0</Version> <!-- x-release-please-version -->
   ```

   The generic updater rewrites the annotated attribute; keep the marker
   comment on the same line.

## Commit discipline

Conventional Commits drive everything: `feat:` bumps minor while `0.x`,
`fix:` bumps patch, `BREAKING CHANGE:` bumps major even while `0.x`.
Never commit to `main` directly in a release-please repo - branch, open a
PR, let the release PR flow handle `main`.

## Flow on private repos

The whole chain (open release PR -> test -> squash-merge -> tag) runs inside
one `release.yml` execution because `GITHUB_TOKEN` events do not trigger
other workflows; the merge is done with `gh pr merge` and the tag is created
by a second `release-please-action` step. See
`.github/workflows/dotnet-release.yml` for the canonical chain.
