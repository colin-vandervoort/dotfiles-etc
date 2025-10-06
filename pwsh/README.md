# PowerShell Profile Testing

## Overview

The `test-profile.ps1` script validates your PowerShell profile before installation to catch potential issues early.

## Usage

### Basic Testing
```bash
cd /Users/colin/Code/dotfiles-etc/pwsh
./test-profile.ps1
```

### Verbose Testing
```bash
./test-profile.ps1 -Verbose
```

### Test Specific Profile
```bash
./test-profile.ps1 -ProfilePath "./profiles/current-user-current-host/Microsoft.PowerShell_profile.ps1" -Verbose
```

## What It Tests

### 1. **File System Tests**
- ✅ Profile file exists
- ✅ Profile file is accessible

### 2. **Syntax Validation**
- ✅ PowerShell syntax is valid
- ✅ No parsing errors

### 3. **Dependency Checks**
- ✅ `git` (required) - for git aliases
- ⚠️ `fnm` (optional) - Fast Node Manager
- ⚠️ `starship` (optional) - Cross-shell prompt

### 4. **Module Availability**
- ✅ PSReadLine module for enhanced editing
- ✅ Clipboard functionality (`Set-Clipboard`, `pbcopy`, etc.)

### 5. **Profile Execution**
- ✅ Profile loads without errors in a sandbox
- ✅ All functions and aliases can be created

### 6. **Alias Conflicts**
- ⚠️ Checks for existing aliases that might conflict
- ⚠️ Shows what would be overwritten

### 7. **Cross-Platform Compatibility**
- ✅ Platform detection works correctly
- ✅ Required functions are defined

## Exit Codes

- **0**: All tests passed or only warnings
- **1**: Critical failures detected

## Integration with Install Script

The test script is automatically run by the Rust installation tool (`install-cfgs`) before installing the PowerShell profile. This provides early feedback about potential issues.

## Common Issues & Solutions

### Missing Dependencies
```
⚠️ fnm availability - Optional dependency missing
⚠️ starship availability - Optional dependency missing
```
**Solution**: Install the missing tools or ignore if you don't need them.

### Alias Conflicts
```
⚠️ Alias conflict: gc - Alias 'gc' already exists
```
**Solution**: The profile will overwrite existing aliases. This is usually fine but check if you have custom `gc` alias you want to keep.

### Syntax Errors
```
✗ PowerShell syntax - Syntax error detected
```
**Solution**: Fix the syntax error in the profile file.

### PSReadLine Missing
```
⚠️ PSReadLine module - PSReadLine not available
```
**Solution**: Install PSReadLine module:
```powershell
Install-Module PSReadLine -Scope CurrentUser
```

## Manual Testing

You can also manually test your profile by loading it in a new PowerShell session:

```powershell
# Test in a clean session
pwsh -NoProfile

# Then source your profile
. "./profiles/current-user-current-host/Microsoft.PowerShell_profile.ps1"

# Test various functions
Test-ProgramExists git
ll
homedir
```