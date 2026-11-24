# Installs a self-hosted GitHub Actions runner (macOS arm64) for an org.
# The registration token is fetched at runtime and never printed.
#
# Usage (defaults install a runner for shoji-labs in ~/actions-runner):
#   pwsh -File Install-Runner.ps1 [-Org org] [-Name name] [-Labels l1,l2] [-InstallDir path]
#
# After this succeeds, start the runner:
#   LaunchAgent (login scope): see runners/README.md
#   LaunchDaemon (boot scope): cd $InstallDir && sudo ./svc.sh install && sudo ./svc.sh start
[CmdletBinding()]
param(
    [string] $Org = 'shoji-labs',
    [string] $Name = (hostname),
    [string] $Labels = 'macos-latest',
    [string] $InstallDir = (Join-Path $HOME 'actions-runner')
)

$ErrorActionPreference = 'Stop'
$tmp = Join-Path ([IO.Path]::GetTempPath()) 'actions-runner-osx-arm64.tar.gz'

Write-Output 'fetching registration token'
$token = gh api -X POST "/orgs/$Org/actions/runners/registration-token" --jq .token
if ($LASTEXITCODE -ne 0 -or -not $token) { throw 'could not acquire registration token' }

if (-not (Test-Path (Join-Path $InstallDir 'run.sh'))) {
    Write-Output 'downloading runner tarball'
    $url = gh api repos/actions/runner/releases/latest --jq '.assets[] | select(.name | test("^actions-runner-osx-arm64-.*\\.tar\\.gz$")) | .browser_download_url' | Select-Object -First 1
    if (-not $url) { throw 'could not resolve runner download URL' }
    Invoke-WebRequest -Uri $url -OutFile $tmp
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    tar -xzf $tmp -C $InstallDir
    if ($LASTEXITCODE -ne 0) { throw 'tar extract failed' }
    Remove-Item $tmp -Force
}
else {
    Write-Output 'runner binary already present, skipping download'
}

Push-Location $InstallDir
try {
    if (Test-Path '.runner') {
        Write-Output 'already configured, skipping config'
    }
    else {
        Write-Output "configuring runner ${Name} for org ${Org}"
        $config = bash ./config.sh --unattended --url "https://github.com/$Org" --token $token --name $Name --labels $Labels 2>&1
        $config | Where-Object { $_ -notmatch [regex]::Escape($token) } | ForEach-Object { Write-Output $_ }
        if ($LASTEXITCODE -ne 0) { throw "config.sh failed with exit ${LASTEXITCODE}" }
    }
}
finally {
    Pop-Location
}

Write-Output ('configured: ' + (Test-Path (Join-Path $InstallDir '.runner')))
