[CmdletBinding()]
param(
    [switch] $Help
)

$ErrorActionPreference = 'Stop'

function Write-Header {
    Write-Host ''
    Write-Host '=== Pi for Windows: interactive installer ===' -ForegroundColor Cyan
    Write-Host 'Installs Pi, its Node.js runtime, and the selected command environment.'
    Write-Host ''
}

function Read-MenuChoice {
    param([string] $Prompt, [string[]] $Choices)
    while ($true) {
        Write-Host $Prompt
        for ($i = 0; $i -lt $Choices.Count; $i++) {
            Write-Host ("  {0}. {1}" -f ($i + 1), $Choices[$i])
        }
        $answer = Read-Host 'Enter a number'
        $number = 0
        if ([int]::TryParse($answer, [ref] $number) -and $number -ge 1 -and $number -le $Choices.Count) {
            return ($number - 1)
        }
        Write-Host 'Please enter one of the listed numbers.' -ForegroundColor Yellow
    }
}

function Invoke-Checked {
    param([string] $File, [string[]] $Arguments)
    & $File @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed (exit $LASTEXITCODE): $File $($Arguments -join ' ')"
    }
}

function Install-Native {
    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        throw 'winget was not found. Install App Installer from Microsoft Store, then rerun.'
    }
    if (-not (Test-Path "$env:ProgramFiles\Git\bin\bash.exe") -and -not (Test-Path "${env:ProgramFiles(x86)}\Git\bin\bash.exe")) {
        Write-Host 'Installing Git for Windows (provides Git Bash)...' -ForegroundColor Cyan
        Invoke-Checked 'winget.exe' @('install', '--id', 'Git.Git', '--exact', '--source', 'winget', '--accept-package-agreements', '--accept-source-agreements')
    }
    if (-not (Get-Command node.exe -ErrorAction SilentlyContinue) -or -not (Get-Command npm.cmd -ErrorAction SilentlyContinue)) {
        Write-Host 'Installing Node.js LTS...' -ForegroundColor Cyan
        Invoke-Checked 'winget.exe' @('install', '--id', 'OpenJS.NodeJS.LTS', '--exact', '--source', 'winget', '--accept-package-agreements', '--accept-source-agreements')
    }
    if (-not (Get-Command npm.cmd -ErrorAction SilentlyContinue)) {
        throw 'Node.js/npm was installed or is present but not on this PowerShell PATH. Open a new terminal and rerun.'
    }
    Invoke-Checked 'npm.cmd' @('install', '--global', '@mariozechner/pi-coding-agent')
    Write-Host "Pi installed. Start it with: pi" -ForegroundColor Green
    Write-Host 'If Pi cannot find Bash, restart PowerShell or configure shellPath in ~/.pi/agent/settings.json.'
}

function Install-Wsl {
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        throw 'wsl.exe is unavailable. Use a supported Windows 10/11 version and rerun.'
    }
    $distros = (& wsl.exe --list --quiet 2>$null | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ })
    if (-not $distros) {
        Write-Host 'Installing WSL and Ubuntu. Windows may ask for administrator approval or a reboot...' -ForegroundColor Cyan
        & wsl.exe --install -d Ubuntu
        if ($LASTEXITCODE -ne 0) {
            throw 'WSL installation did not finish. Reboot if requested, complete Ubuntu first-run setup, then rerun this script.'
        }
        Write-Host 'Complete the Ubuntu username/password setup, then rerun this script to install Pi inside WSL.' -ForegroundColor Yellow
        return
    }
    $distro = Read-Host ("Enter the installed WSL distribution name (default: {0})" -f $distros[0])
    if ([string]::IsNullOrWhiteSpace($distro)) { $distro = $distros[0] }
    if ($distros -notcontains $distro) { throw "WSL distribution '$distro' is not installed. Available: $($distros -join ', ')" }
    $linuxCommand = 'set -e; if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then if command -v apt-get >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y nodejs npm; else echo "Install Node.js and npm for this distribution, then rerun." >&2; exit 1; fi; fi; npm install --global @mariozechner/pi-coding-agent; pi'
    Write-Host 'Installing Pi in WSL; you may be prompted for your Linux password...' -ForegroundColor Cyan
    & wsl.exe -d $distro -- bash -lc $linuxCommand
    if ($LASTEXITCODE -ne 0) { throw 'Pi setup in WSL failed. Review the command output and rerun after resolving it.' }
}

if ($Help) {
    Write-Host 'Usage: .\Install-Pi.ps1'
    Write-Host 'Interactively selects a language and native Git Bash or WSL setup.'
    exit 0
}

Write-Header
$languageIndex = Read-MenuChoice 'Choose the language for your setup note:' @('English', 'Mandarin Chinese (中文)', 'Hindi (हिन्दी)', 'Spanish (Español)', 'French (Français)')
$languages = @('English', 'Mandarin Chinese', 'Hindi', 'Spanish', 'French')
$language = $languages[$languageIndex]
$environmentIndex = Read-MenuChoice 'Choose where to install Pi:' @('Native Windows with Git Bash (recommended)', 'WSL (Linux environment)')
$environment = if ($environmentIndex -eq 0) { 'native' } else { 'wsl' }
Write-Host "`nSelection: $language; $environment. Software will be installed from Microsoft winget and npm." -ForegroundColor Yellow
$confirmation = Read-Host 'Continue? [y/N]'
if ($confirmation -notmatch '^(y|yes)$') { Write-Host 'Cancelled; no changes made.'; exit 0 }

try {
    if ($environment -eq 'native') { Install-Native } else { Install-Wsl }
    $piDirectory = Join-Path $HOME '.pi\agent'
    New-Item -ItemType Directory -Path $piDirectory -Force | Out-Null
    $languageNote = "# Pi setup preference`n`nPreferred language: $language`nEnvironment: $environment`n"
    Set-Content -Path (Join-Path $piDirectory 'INSTALL_LANGUAGE.md') -Value $languageNote -Encoding utf8
    Write-Host "Saved language preference to $piDirectory\INSTALL_LANGUAGE.md" -ForegroundColor Green
    Write-Host 'Authenticate on first run with: pi' -ForegroundColor Cyan
} catch {
    Write-Error $_
    exit 1
}
