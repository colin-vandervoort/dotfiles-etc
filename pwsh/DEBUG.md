# PowerShell Profile Debugging Quick Reference

## Running the Validation

### Quick Test
```bash
cd pwsh && ./test-profile.ps1
```

### Verbose Output
```bash
./test-profile.ps1 -Verbose
```

## Common Issues & Quick Fixes

### 🚨 **Syntax Errors**
**Symptom**: `✗ PowerShell syntax - Syntax error detected`
```bash
# Check syntax manually:
pwsh -NoProfile -Command "Get-Content './profiles/current-user-current-host/Microsoft.PowerShell_profile.ps1' | Invoke-Expression"
```

### ⚠️ **Missing Dependencies** 
**Symptom**: `⚠ fnm availability - Optional dependency missing`
```bash
# Install fnm (Fast Node Manager)
curl -fsSL https://fnm.vercel.app/install | bash

# Install starship (Cross-shell prompt)
curl -sS https://starship.rs/install.sh | sh
```

### ⚠️ **PSReadLine Issues**
**Symptom**: `⚠ PSReadLine module - PSReadLine not available`
```powershell
# Install PSReadLine
Install-Module PSReadLine -Scope CurrentUser -Force
```

### 🚨 **Profile Won't Load**
**Symptom**: `✗ Profile execution - Profile failed to load`
```powershell
# Test step by step:
pwsh -NoProfile

# Try loading individual parts:
function Test-ProgramExists { param([string]$ProgramName); return (Get-Command $ProgramName -ErrorAction SilentlyContinue | Out-Null) }

# Test aliases one by one:
Set-Alias -Name "ll" Get-ChildItem
```

### ⚠️ **Alias Conflicts**  
**Symptom**: `⚠ Alias conflict: gc - Alias 'gc' already exists`
```powershell
# Check what the existing alias does:
Get-Alias gc

# Your profile will overwrite it - usually safe for 'gc' (Get-Content -> Git Commit)
```

## Manual Testing Steps

### 1. **Basic Loading Test**
```powershell
pwsh -NoProfile
. "./profiles/current-user-current-host/Microsoft.PowerShell_profile.ps1"
```

### 2. **Test Individual Functions**
```powershell
# Test the Test-ProgramExists function
Test-ProgramExists git      # Should return nothing (success)
Test-ProgramExists fakecmd  # Should return nothing (not found)

# Test aliases  
ll          # Should list directory contents
homedir     # Should navigate to home directory
gc --help   # Should show git commit help
```

### 3. **Test Platform-Specific Features**
```powershell
# On macOS - test clipboard aliases
echo "test" | pbcopy
pbpaste

# Test PSReadLine options
Get-PSReadLineOption
```

## Debugging Commands

### Check PowerShell Version
```powershell
$PSVersionTable
```

### List All Aliases
```powershell
Get-Alias | Sort-Object Name
```

### Check Available Modules
```powershell
Get-Module -ListAvailable
```

### Test Command Availability
```powershell
Get-Command starship -ErrorAction SilentlyContinue
Get-Command fnm -ErrorAction SilentlyContinue
```

### Profile Location Check
```powershell
$PROFILE                    # Current user, current host
$PROFILE.AllUsersAllHosts   # All users, all hosts
```

## Installation Flow Debug

### 1. **Run Validation First**
```bash
cd pwsh && ./test-profile.ps1 -Verbose
```

### 2. **Check Installation Paths**
```bash
# Your profile will be installed to:
# macOS: ~/.config/powershell/Microsoft.PowerShell_profile.ps1
# Windows: ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1
```

### 3. **Verify Symlink/Copy**
```bash
# Check if the profile is properly linked:
ls -la ~/.config/powershell/
```

### 4. **Test in New Session**
```bash
# Start fresh PowerShell session to test:
pwsh
# Your prompt should change if starship is available
# Aliases should work: ll, homedir, etc.
```

## Error Recovery

### Reset PowerShell Profile
```powershell
# Remove the profile temporarily
rm $PROFILE
pwsh -NoProfile
```

### Clean Install
```bash
# Re-run the installer
cd tools && cargo run --bin install-cfgs
```

### Backup Before Install
```bash
# The installer uses OverwriteAlways, so back up manually if needed:
cp ~/.config/powershell/Microsoft.PowerShell_profile.ps1 ~/.config/powershell/Microsoft.PowerShell_profile.ps1.backup
```