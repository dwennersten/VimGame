# Launch VimQuest in an isolated Neovim profile.
#
# NVIM_APPNAME=vimquest makes Neovim use its own config/data directories, so
# your real ~/AppData/Local/nvim configuration is never read or written.

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot

$nvim = $null
$cmd = Get-Command nvim -ErrorAction SilentlyContinue
if ($cmd) { $nvim = $cmd.Source }

if (-not $nvim) {
    $candidates = @(
        "$env:ProgramFiles\Neovim\bin\nvim.exe",
        "${env:ProgramFiles(x86)}\Neovim\bin\nvim.exe",
        "$env:LOCALAPPDATA\Programs\Neovim\bin\nvim.exe",
        "$env:LOCALAPPDATA\Microsoft\WinGet\Links\nvim.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { $nvim = $c; break }
    }
}

if (-not $nvim) {
    Write-Error "Neovim not found. Install it with:  winget install Neovim.Neovim"
}

$env:NVIM_APPNAME = 'vimquest'
& $nvim -u (Join-Path $repo 'init.lua')
