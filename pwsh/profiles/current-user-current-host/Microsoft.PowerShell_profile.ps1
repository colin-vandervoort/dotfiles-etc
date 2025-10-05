# Supporting documentation
# https://learn.microsoft.com/en-us/powershell/scripting/whats-new/migrating-from-windows-powershell-51-to-powershell-7?view=powershell-7.4
#
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/set-alias?view=powershell-7.4
#
# Testing framework to investigate: https://pester.dev/

function Test-ProgramExists {
    param (
        [string]$ProgramName
    )
    return (Get-Command $ProgramName -ErrorAction SilentlyContinue | Out-Null)
}

# Get information about current PowerShell
# $MajorVersion = $PSVersionTable.PSVersion.Major

# Setup Fast Node Manager
# https://github.com/Schniz/fnm
if (Test-ProgramExists fnm) {
    fnm env --use-on-cd --shell power-shell | Out-String | Invoke-Expression
}

# Common bash aliases
Set-Alias -Name "ll" Get-ChildItem
function Get-ChildItem-With-Hidden { Get-ChildItem -Path "." -Force }
Set-Alias -Name "la" Get-ChildItem-With-Hidden

# Mac aliases
Set-Alias -Name "pbcopy" Set-Clipboard
Set-Alias -Name "pbpaste" Get-Clipboard

# Git aliases
function GitCommit { & git commit $args }
Remove-Item -Force alias:gc
Set-Alias -Name "gc" GitCommit

function GitTag { & git tag $args }
Set-Alias -Name "gt" GitTag

function GitSwitch { & git switch $args }
Set-Alias -Name "gs" GitSwitch

function GitBranch { & git branch $args }
Set-Alias -Name "gb" GitBranch

# Directory shortcuts
function Set-Location-To-Home-Dir { Set-Location -Path "~" }
Set-Alias -Name "homedir" Set-Location-To-Home-Dir

# PowerShell ReadLine options
$PSReadLineOptions = @{
    EditMode = "Emacs"
    HistoryNoDuplicates = $true
}
Set-PSReadLineOption @PSReadLineOptions

# Init Starship
if (Test-ProgramExists starship) {
    Invoke-Expression (&starship init powershell)
}
