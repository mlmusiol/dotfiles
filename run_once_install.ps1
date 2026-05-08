# Windows dev setup for chezmoi

$ErrorActionPreference = "Stop"
$script:StatusCounts = [ordered]@{
    OK   = 0
    SKIP = 0
    WARN = 0
    FAIL = 0
}
$script:TableBorder = "+------------------------------+----------------------------------------------+--------+"

function Get-StatusColor {
    param(
        [string]$State
    )

    $normalizedState = $State.ToUpperInvariant()
    switch ($normalizedState) {
        "OK" { "Green" }
        "SKIP" { "DarkGray" }
        "WARN" { "DarkYellow" }
        "FAIL" { "Red" }
        default { "Gray" }
    }
}

function Write-ItemResult {
    param(
        [string]$Item,
        [string]$State,
        [string]$Reason
    )

    $normalizedState = $State.ToUpperInvariant()
    if ($script:StatusCounts.Contains($normalizedState)) {
        $script:StatusCounts[$normalizedState]++
    }

    $reasonText = if ([string]::IsNullOrWhiteSpace($Reason)) { "-" } else { $Reason }
    $stateLabel = $normalizedState.PadRight(4)
    $line = "| {0,-28} | {1,-44} | {2,-6} |" -f $Item, $reasonText, $stateLabel
    Write-Host $line -ForegroundColor (Get-StatusColor -State $normalizedState)
    Write-Host $script:TableBorder -ForegroundColor DarkGray
}

function Write-Section {
    param(
        [string]$Title
    )

    Write-Host ""
    Write-Host "" 
    Write-Host ("--- {0} ---" -f $Title) -ForegroundColor Magenta
    Write-Host $script:TableBorder -ForegroundColor DarkGray
    Write-Host ("| {0,-28} | {1,-44} | {2,-6} |" -f "Item", "Result", "State") -ForegroundColor DarkGray
    Write-Host $script:TableBorder -ForegroundColor DarkGray
}

function Write-SectionEnd {
    Write-Host ""
}

function Write-CommandOutput {
    param(
        [object]$Output
    )

    if ($Output) {
        $Output | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
    }
}

function Write-Summary {
    Write-Host ""
    Write-Host "Run summary:" -ForegroundColor Cyan
    Write-Host ("  OK   : {0}" -f $script:StatusCounts["OK"]) -ForegroundColor Green
    Write-Host ("  SKIP : {0}" -f $script:StatusCounts["SKIP"]) -ForegroundColor DarkGray
    Write-Host ("  WARN : {0}" -f $script:StatusCounts["WARN"]) -ForegroundColor DarkYellow
    Write-Host ("  FAIL : {0}" -f $script:StatusCounts["FAIL"]) -ForegroundColor Red
    Write-Host ""
}

function Install-WingetPackage {
    param(
        [string]$Id,
        [string]$Name = $Id
    )

    $installed = winget list --id $Id --exact 2>$null
    if ($LASTEXITCODE -eq 0 -and $installed -match $Id) {
        Write-ItemResult -Item $Name -State "SKIP" -Reason "already installed"
        return
    }

    $wingetOutput = winget install --id $Id --exact --source winget --accept-package-agreements --accept-source-agreements 2>&1
    $wingetExitCode = $LASTEXITCODE

    if ($wingetExitCode -eq 0) {
        Write-ItemResult -Item $Name -State "OK" -Reason "installed via winget"
        return
    }

    $wingetText = ($wingetOutput | Out-String)
    if ($wingetText -match "No package found matching input criteria") {
        Write-ItemResult -Item $Name -State "WARN" -Reason "not found in winget; skipped"
        return
    }

    Write-CommandOutput -Output $wingetOutput
    Write-ItemResult -Item $Name -State "FAIL" -Reason "winget exit code: $wingetExitCode"
    throw "Failed to install $Name"
}

function Test-IsAdministrator {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-Scoop {
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-ItemResult -Item "Scoop" -State "SKIP" -Reason "already installed"
        return
    }

    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    $scoopInstaller = Invoke-RestMethod get.scoop.sh
    $scoopInstallScript = [scriptblock]::Create($scoopInstaller)

    if (Test-IsAdministrator) {
        & $scoopInstallScript -RunAsAdmin
    } else {
        & $scoopInstallScript
    }

    # Ensure this PowerShell session can find scoop immediately after installation.
    $scoopShimCandidates = @(
        (Join-Path -Path $HOME -ChildPath "scoop\shims"),
        (Join-Path -Path $env:ProgramData -ChildPath "scoop\shims")
    )

    foreach ($shimPath in $scoopShimCandidates) {
        if ((Test-Path $shimPath) -and ($env:Path -notlike "*$shimPath*")) {
            $env:Path = "$shimPath;$env:Path"
        }
    }

    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-ItemResult -Item "Scoop" -State "FAIL" -Reason "installed but not found in PATH"
        throw "Scoop was installed but is not available in PATH"
    }

    Write-ItemResult -Item "Scoop" -State "OK" -Reason "installed"
}

function Install-ScoopPackage {
    param(
        [string]$Name
    )

    $scoopAppPath = Join-Path -Path $HOME -ChildPath ("scoop\apps\{0}\current" -f $Name)
    if (Test-Path $scoopAppPath) {
        Write-ItemResult -Item $Name -State "SKIP" -Reason "already installed"
        return
    }

    $scoopOutput = scoop install $Name 2>&1
    $scoopExitCode = $LASTEXITCODE
    $scoopText = ($scoopOutput | Out-String)

    if ($scoopExitCode -eq 0 -and $scoopText -notmatch "already installed") {
        Write-ItemResult -Item $Name -State "OK" -Reason "installed via scoop"
        return
    }

    if ($scoopText -match "already installed") {
        Write-ItemResult -Item $Name -State "SKIP" -Reason "already installed"
        return
    }

    Write-CommandOutput -Output $scoopOutput
    Write-ItemResult -Item $Name -State "FAIL" -Reason "scoop exit code: $scoopExitCode"
    throw "Failed to install scoop package: $Name"
}

Write-Section -Title "Installing core tools"

Install-WingetPackage -Id "Git.Git" -Name "Git"
Install-WingetPackage -Id "GitHub.cli" -Name "GitHub CLI"
Install-WingetPackage -Id "Microsoft.PowerShell" -Name "PowerShell 7"
Install-WingetPackage -Id "wez.wezterm" -Name "WezTerm"
Install-WingetPackage -Id "glzr-io.glazewm" -Name "GlazeWM"
Install-WingetPackage -Id "JanDeDobbeleer.OhMyPosh" -Name "Oh My Posh"
Install-WingetPackage -Id "Kitware.CMake" -Name "CMake"
Install-WingetPackage -Id "Neovim.Neovim" -Name "Neovim"
Install-WingetPackage -Id "Rustlang.Rustup" -Name "Rustup"
Write-SectionEnd

Write-Section -Title "Installing JetBrainsMono Nerd Font"

Install-WingetPackage -Id "DEVCOM.JetBrainsMonoNerdFont" -Name "JetBrainsMono Nerd Font"
Write-SectionEnd

Write-Section -Title "Installing Scoop tools"

Ensure-Scoop

$extrasBucketPath = Join-Path -Path $HOME -ChildPath "scoop\buckets\extras"
if (Test-Path $extrasBucketPath) {
    Write-ItemResult -Item "Scoop bucket extras" -State "SKIP" -Reason "already added"
} else {
    $bucketAddOutput = & { scoop bucket add extras } *>&1
    $bucketAddExitCode = $LASTEXITCODE

    if ($bucketAddExitCode -eq 0) {
        Write-ItemResult -Item "Scoop bucket extras" -State "OK" -Reason "added"
    } elseif (($bucketAddOutput | Out-String) -match "already exists") {
        Write-ItemResult -Item "Scoop bucket extras" -State "SKIP" -Reason "already added"
    } elseif ((scoop bucket list 2>$null) -match "(?im)^\s*extras(?:\s|$)") {
        Write-ItemResult -Item "Scoop bucket extras" -State "SKIP" -Reason "already added"
    } else {
        Write-CommandOutput -Output $bucketAddOutput
        Write-ItemResult -Item "Scoop bucket extras" -State "FAIL" -Reason "scoop exit code: $bucketAddExitCode"
        throw "Failed to add Scoop bucket extras"
    }
}

Install-ScoopPackage "lazygit"
Install-ScoopPackage "ripgrep"
Install-ScoopPackage "fd"
Install-ScoopPackage "neovide"
Write-SectionEnd

Write-Section -Title "Installing cargo-binstall and tree-sitter-cli"

$env:Path = "$HOME\.cargo\bin;$env:Path"

if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    Write-ItemResult -Item "Cargo" -State "WARN" -Reason "not in PATH; rerun after shell restart"
} else {
    if (-not (Get-Command cargo-binstall -ErrorAction SilentlyContinue)) {
        Set-ExecutionPolicy Unrestricted -Scope Process -Force
        Invoke-Expression (Invoke-WebRequest "https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.ps1").Content
        Write-ItemResult -Item "cargo-binstall" -State "OK" -Reason "installed"
    } else {
        Write-ItemResult -Item "cargo-binstall" -State "SKIP" -Reason "already installed"
    }

    if (-not (Get-Command tree-sitter -ErrorAction SilentlyContinue)) {
        cargo binstall tree-sitter-cli -y
        if ($LASTEXITCODE -eq 0) {
            Write-ItemResult -Item "tree-sitter-cli" -State "OK" -Reason "installed"
        } else {
            Write-ItemResult -Item "tree-sitter-cli" -State "FAIL" -Reason "cargo exit code: $LASTEXITCODE"
            throw "Failed to install tree-sitter-cli"
        }
    } else {
        Write-ItemResult -Item "tree-sitter-cli" -State "SKIP" -Reason "already installed"
    }
}
Write-SectionEnd

Write-Section -Title "PowerShell profile forwarding"

$ProfileDir = Split-Path $PROFILE
New-Item -ItemType Directory -Force $ProfileDir | Out-Null

$ForwardProfile = @'
$CleanProfile = "$HOME\.config\powershell\profile.ps1"

if (Test-Path $CleanProfile) {
    . $CleanProfile
}
'@

Set-Content -Path $PROFILE -Value $ForwardProfile -Encoding UTF8
Write-ItemResult -Item "PowerShell profile" -State "OK" -Reason "forwarding configured"
Write-SectionEnd

Write-Section -Title "Neovim Windows config junction"

$NvimTarget = "$HOME\.config\nvim"
$NvimLink = "$HOME\AppData\Local\nvim"

if (Test-Path $NvimTarget) {
    $nvimSteps = @()
    if ((Test-Path $NvimLink) -and -not ((Get-Item $NvimLink).LinkType -eq "Junction")) {
        $Backup = "$NvimLink.backup"
        Rename-Item $NvimLink $Backup -Force
        $nvimSteps += "backup created"
    }

    if (-not (Test-Path $NvimLink)) {
        New-Item -ItemType Junction -Path $NvimLink -Target $NvimTarget | Out-Null
        $nvimSteps += "junction created"
    }

    if ($nvimSteps.Count -gt 0) {
        Write-ItemResult -Item "Neovim junction" -State "OK" -Reason ($nvimSteps -join ", ")
    } else {
        Write-ItemResult -Item "Neovim junction" -State "SKIP" -Reason "already present"
    }
} else {
    Write-ItemResult -Item "Neovim junction" -State "SKIP" -Reason "source config not found"
}
Write-SectionEnd

Write-Host ""
Write-Host "Setup completed." -ForegroundColor Green
Write-Summary
Write-Host "Manual steps still needed:" -ForegroundColor Cyan
Write-Host "1. Run: gh auth login"
Write-Host "2. Open PowerShell 7 and verify Oh My Posh loads."
Write-Host "3. For tree-sitter native parsers, install Visual Studio Build Tools C++ workload if needed."
Write-Host ""