$WingetPackages = @(
    'GitExtensionsTeam.GitExtensions'
    'GitHub.GitLFS',
    'Hashicorp.Vagrant',
    'Microsoft.PowerShell',
    'Microsoft.VisualStudioCode',
    'Microsoft.VisualStudioCode.CLI',
    'Microsoft.WindowsTerminal',
    'Microsoft.PowerToys',
    'Neovim.Neovim',
    'Oracle.VirtualBox',
    'RedHat.Podman-Desktop'
)

foreach ($Package in $WingetPackages) {
    winget install -e --id $Package
}
