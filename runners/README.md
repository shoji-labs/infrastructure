# Self-hosted runners

Currently one: **OscarsMacStudio** (Apple silicon, macOS) registered at org
level for `shoji-labs`, installed in `~/actions-runner`, labels
`self-hosted, macOS, ARM64, macos-latest`.

The `macos-latest` label is deliberate: it matches the existing `runs-on:`
values in the repos' workflows. A self-hosted runner is picked before a
hosted one when both match and it is online, so macOS jobs run here for free;
when the Mac is offline the run falls back to the hosted runner (10x minutes,
but nothing stalls).

## Install on a new Mac

```sh
pwsh -File Install-Runner.ps1                      # defaults: org shoji-labs, name = hostname, label macos-latest, dir ~/actions-runner
```

The script fetches a short-lived registration token (needs a `gh` login with
the `admin:org` scope), resolves the latest runner tarball from the
actions/runner releases (the asset name embeds the version, so the
`latest/download` URL pattern does not work) and registers the runner.

## Start at login (no sudo)

Copy `com.shoji-labs.actions-runner.plist` to `~/Library/LaunchAgents/`,
adjust the home-directory paths, then:

```sh
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.shoji-labs.actions-runner.plist
```

The plist is already live on OscarsMacStudio. Logs: `~/actions-runner/launchd.log`.

## Start at boot (needs sudo)

Unregister the agent first (`launchctl bootout gui/$UID/com.shoji-labs.actions-runner`),
then from `~/actions-runner`:

```sh
sudo ./svc.sh install
sudo ./svc.sh start
```

## Remove a runner

```sh
launchctl bootout gui/$(id -u)/com.shoji-labs.actions-runner   # or sudo ./svc.sh stop && sudo ./svc.sh uninstall
cd ~/actions-runner && ./svc.sh status
gh api /orgs/shoji-labs/actions/runners --jq '.runners[] | "\(.id) \(.name)"'
gh api -X DELETE /orgs/shoji-labs/actions/runners/<id>
```

## Security notes

- The runner has **no inbound ports**: outbound HTTPS long-poll only.
- The config token expires in one hour and is used once; the long-lived
  runner credential lives in `.credentials` and can only poll for jobs.
- **Jobs execute repo workflow code as the user running the runner.** Keep
  "require approval for first-time contributors / fork PRs" enabled on every
  repo in the org (default for private repos). The hardening step is running
  the service as a dedicated `runner` user with no access to interactive
  users' homes or keychains.
