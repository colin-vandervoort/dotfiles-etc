# Supporting documentation
# https://learn.microsoft.com/en-us/powershell/scripting/whats-new/migrating-from-windows-powershell-51-to-powershell-7?view=powershell-7.4
#
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/set-alias?view=powershell-7.4

# Get information about current PowerShell
# $MajorVersion = $PSVersionTable.PSVersion.Major

# Setup Fast Node Manager
# https://github.com/Schniz/fnm
fnm env --use-on-cd --shell power-shell | Out-String | Invoke-Expression

# Remove some default aliases
Remove-Item -Force alias:gc

# Common bash aliases
Set-Alias -Name "ll" Get-ChildItem
function Get-ChildItem-With-Hidden { Get-ChildItem -Path "." -Force }
Set-Alias -Name "la" Get-ChildItem-With-Hidden

# Mac aliases
Set-Alias -Name "pbcopy" Set-Clipboard
Set-Alias -Name "pbpaste" Get-Clipboard

# Git aliases
function GitCommit { & git commit $args }
Set-Alias -Name "gc" GitCommit

function GitTag { & git tag $args }
Set-Alias -Name "gc" GitTag

function GitSwitch { & git switch $args }
Set-Alias -Name "gs" GitSwitch

# Directory shortcuts
function Set-Location-To-Home-Dir { Set-Location -Path "~" }
Set-Alias -Name "homedir" Set-Location-To-Home-Dir

# Init Starship
Invoke-Expression (&starship init powershell)
