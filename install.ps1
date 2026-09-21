# MLB YT - one-line installer (no browser or Windows warnings). Paste into PowerShell:
#   irm https://raw.githubusercontent.com/MSEVENDEV/mlb-yt/main/install.ps1 | iex
# It downloads the latest official installer from this repo's releases, checks its SHA-256
# against the release's latest.json and installs it for the current user (no admin needed).
& {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $releases = 'https://github.com/MSEVENDEV/mlb-yt/releases'

    Write-Host ''
    Write-Host '   M L B   Y T' -ForegroundColor White
    Write-Host '   video & music downloader - by MSEVENDEV' -ForegroundColor DarkGray
    Write-Host ''
    try {
        Write-Host '   [1/3] Finding the latest version...'
        # cache-busting: Windows PowerShell otherwise may reuse an old cached copy
        $info = Invoke-RestMethod "$releases/latest/download/latest.json?nocache=$([DateTime]::UtcNow.Ticks)" `
            -Headers @{ 'Cache-Control' = 'no-cache' } -UseBasicParsing
        if ($info.setup.file -notmatch '^MLB-YT-Setup-\d+\.\d+\.\d+\.exe$' -or $info.setup.sha256 -notmatch '^[0-9a-f]{64}$') {
            throw 'Unexpected release info.'
        }
        $exe = Join-Path $env:TEMP $info.setup.file

        Write-Host ("   [2/3] Downloading MLB YT {0}  ({1:N0} MB)..." -f $info.version, ($info.setup.size / 1MB))
        $url = "$releases/download/v$($info.version)/$($info.setup.file)"
        if (Get-Command curl.exe -ErrorAction SilentlyContinue) {   # built into Windows 10/11: fast + resumable
            & curl.exe -fsSL --retry 3 -o $exe $url
            if ($LASTEXITCODE -ne 0) { throw "Download failed (curl $LASTEXITCODE). Check your internet and try again." }
        } else {
            Invoke-WebRequest $url -OutFile $exe -UseBasicParsing
        }
        if ((Get-FileHash $exe -Algorithm SHA256).Hash.ToLower() -ne $info.setup.sha256) {
            Remove-Item $exe -ErrorAction SilentlyContinue
            throw 'The download was damaged. Please run the command again.'
        }

        Write-Host '   [3/3] Installing...'
        $p = Start-Process $exe -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/TASKS=desktopicon', '/RELAUNCH=1' -Wait -PassThru
        Remove-Item $exe -ErrorAction SilentlyContinue
        if ($p.ExitCode -ne 0) { throw "The installer stopped (code $($p.ExitCode))." }

        Write-Host ''
        Write-Host '   Done! MLB YT is opening now. It is also on your desktop.' -ForegroundColor Green
        Write-Host '   By installing you accept the license: https://github.com/MSEVENDEV/mlb-yt/blob/main/LICENSE' -ForegroundColor DarkGray
    }
    catch {
        Write-Host ''
        Write-Host "   Install failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host '   You can also download the installer here: https://github.com/MSEVENDEV/mlb-yt' -ForegroundColor DarkGray
    }
    Write-Host ''
}
