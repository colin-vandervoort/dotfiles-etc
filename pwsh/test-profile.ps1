#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Test script to validate PowerShell profile before installation
.DESCRIPTION
    This script validates the PowerShell profile for potential issues including:
    - Syntax errors
    - Missing dependencies
    - Alias conflicts
    - Module availability
    - Cross-platform compatibility
.PARAMETER ProfilePath
    Path to the PowerShell profile to test (defaults to the current-user-current-host profile)
.PARAMETER Verbose
    Enable verbose output showing all test details
.EXAMPLE
    ./test-profile.ps1
.EXAMPLE
    ./test-profile.ps1 -ProfilePath "./profiles/current-user-current-host/Microsoft.PowerShell_profile.ps1" -Verbose
#>

param(
    [string]$ProfilePath = "./profiles/current-user-current-host/Microsoft.PowerShell_profile.ps1",
    [switch]$Verbose
)

# Test result tracking
$script:TestResults = @{
    Passed = 0
    Failed = 0
    Warnings = 0
    Tests = @()
}

function Write-TestResult {
    param(
        [string]$TestName,
        [string]$Status,  # "PASS", "FAIL", "WARN"
        [string]$Message,
        [string]$Details = ""
    )

    $color = switch ($Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
    }

    $symbol = switch ($Status) {
        "PASS" { "✓" }
        "FAIL" { "✗" }
        "WARN" { "⚠" }
    }

    Write-Host "$symbol $TestName" -ForegroundColor $color
    if ($Message) {
        Write-Host "  $Message" -ForegroundColor $color
    }
    if ($Details -and ($Verbose -or $Status -eq "FAIL")) {
        Write-Host "  Details: $Details" -ForegroundColor Gray
    }

    $script:TestResults.Tests += @{
        Name = $TestName
        Status = $Status
        Message = $Message
        Details = $Details
    }

    switch ($Status) {
        "PASS" { $script:TestResults.Passed++ }
        "FAIL" { $script:TestResults.Failed++ }
        "WARN" { $script:TestResults.Warnings++ }
    }
}

function Test-ProfileExists {
    Write-Host "`n=== Profile File Tests ===" -ForegroundColor Cyan

    if (Test-Path $ProfilePath) {
        Write-TestResult "Profile file exists" "PASS" "Found at: $ProfilePath"
        return $true
    } else {
        Write-TestResult "Profile file exists" "FAIL" "File not found at: $ProfilePath"
        return $false
    }
}

function Test-ProfileSyntax {
    Write-Host "`n=== Syntax Validation ===" -ForegroundColor Cyan

    try {
        # Parse the script to check for syntax errors
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $ProfilePath -Raw), [ref]$null)
        Write-TestResult "PowerShell syntax" "PASS" "No syntax errors found"
        return $true
    } catch {
        Write-TestResult "PowerShell syntax" "FAIL" "Syntax error detected" $_.Exception.Message
        return $false
    }
}

function Test-Dependencies {
    Write-Host "`n=== Dependency Checks ===" -ForegroundColor Cyan

    # Test for external programs mentioned in profile
    $dependencies = @(
        @{ Name = "fnm"; Required = $false; Description = "Fast Node Manager" },
        @{ Name = "starship"; Required = $false; Description = "Cross-shell prompt" },
        @{ Name = "git"; Required = $true; Description = "Git version control" }
    )

    foreach ($dep in $dependencies) {
        $exists = $null -ne (Get-Command $dep.Name -ErrorAction SilentlyContinue)

        if ($exists) {
            $version = ""
            try {
                switch ($dep.Name) {
                    "git" { $version = (git --version 2>$null) }
                    "fnm" { $version = (fnm --version 2>$null) }
                    "starship" { $version = (starship --version 2>$null) }
                }
            } catch { }

            Write-TestResult "$($dep.Name) availability" "PASS" "$($dep.Description) found" $version
        } else {
            $status = if ($dep.Required) { "FAIL" } else { "WARN" }
            $message = if ($dep.Required) { "Required dependency missing" } else { "Optional dependency missing" }
            Write-TestResult "$($dep.Name) availability" $status $message $dep.Description
        }
    }
}

function Test-ModuleAvailability {
    Write-Host "`n=== PowerShell Module Tests ===" -ForegroundColor Cyan

    # Test PSReadLine module
    try {
        $psReadLineModule = Get-Module PSReadLine -ListAvailable -ErrorAction SilentlyContinue
        if ($psReadLineModule) {
            Write-TestResult "PSReadLine module" "PASS" "Version: $($psReadLineModule[0].Version)"
        } else {
            Write-TestResult "PSReadLine module" "WARN" "PSReadLine not available - some features may not work"
        }
    } catch {
        Write-TestResult "PSReadLine module" "FAIL" "Error checking PSReadLine" $_.Exception.Message
    }

    # Test clipboard functionality
    try {
        if ($IsWindows) {
            $clipboardTest = Get-Command Set-Clipboard -ErrorAction SilentlyContinue
        } elseif ($IsMacOS) {
            $clipboardTest = Get-Command pbcopy -ErrorAction SilentlyContinue
        } else {
            $clipboardTest = $null
        }

        if ($clipboardTest -or (Get-Command Set-Clipboard -ErrorAction SilentlyContinue)) {
            Write-TestResult "Clipboard functionality" "PASS" "Clipboard commands available"
        } else {
            Write-TestResult "Clipboard functionality" "WARN" "Clipboard functionality may be limited"
        }
    } catch {
        Write-TestResult "Clipboard functionality" "WARN" "Could not verify clipboard support"
    }
}

function Test-ProfileInSandbox {
    Write-Host "`n=== Profile Execution Test ===" -ForegroundColor Cyan

    try {
        # Create a temporary profile for testing
        $tempProfile = [System.IO.Path]::GetTempFileName() + ".ps1"
        Copy-Item $ProfilePath $tempProfile

        # Test loading the profile in a separate PowerShell session
        $testScript = @"
try {
    . '$tempProfile'
    Write-Output "SUCCESS: Profile loaded without errors"
    exit 0
} catch {
    Write-Error "FAILED: `$(`$_.Exception.Message)"
    exit 1
}
"@

        $testScriptPath = [System.IO.Path]::GetTempFileName() + ".ps1"
        Set-Content $testScriptPath $testScript

        $result = & pwsh -NoProfile -ExecutionPolicy Bypass -File $testScriptPath 2>&1

        # Clean up temp files
        Remove-Item $tempProfile -ErrorAction SilentlyContinue
        Remove-Item $testScriptPath -ErrorAction SilentlyContinue

        if ($LASTEXITCODE -eq 0) {
            Write-TestResult "Profile execution" "PASS" "Profile loads without errors"
        } else {
            Write-TestResult "Profile execution" "FAIL" "Profile failed to load" ($result -join "; ")
        }

    } catch {
        Write-TestResult "Profile execution" "FAIL" "Error during profile test" $_.Exception.Message
    }
}

function Test-AliasConflicts {
    Write-Host "`n=== Alias Conflict Tests ===" -ForegroundColor Cyan

    # Check for potential alias conflicts
    $aliasesToCheck = @("ll", "la", "pbcopy", "pbpaste", "gc", "gt", "gs", "gb", "homedir")

    foreach ($alias in $aliasesToCheck) {
        $existing = Get-Alias $alias -ErrorAction SilentlyContinue
        if ($existing) {
            Write-TestResult "Alias conflict: $alias" "WARN" "Alias '$alias' already exists" "Current target: $($existing.Definition)"
        } else {
            Write-TestResult "Alias availability: $alias" "PASS" "Alias '$alias' is available"
        }
    }
}

function Test-CrossPlatformCompatibility {
    Write-Host "`n=== Cross-Platform Compatibility ===" -ForegroundColor Cyan

    # Test platform detection
    if ($IsWindows) {
        Write-TestResult "Platform detection" "PASS" "Running on Windows"
    } elseif ($IsMacOS) {
        Write-TestResult "Platform detection" "PASS" "Running on macOS"
    } elseif ($IsLinux) {
        Write-TestResult "Platform detection" "PASS" "Running on Linux"
    } else {
        Write-TestResult "Platform detection" "WARN" "Unknown platform detected"
    }

    # Test profile functions that might be platform-specific
    try {
        # Test the Test-ProgramExists function definition
        $profileContent = Get-Content $ProfilePath -Raw
        if ($profileContent -match "function Test-ProgramExists") {
            Write-TestResult "Test-ProgramExists function" "PASS" "Function definition found"
        } else {
            Write-TestResult "Test-ProgramExists function" "FAIL" "Function definition missing"
        }
    } catch {
        Write-TestResult "Profile content analysis" "FAIL" "Could not analyze profile content"
    }
}

function Show-Summary {
    Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan

    $total = $script:TestResults.Passed + $script:TestResults.Failed + $script:TestResults.Warnings

    Write-Host "Total Tests: $total" -ForegroundColor White
    Write-Host "Passed: $($script:TestResults.Passed)" -ForegroundColor Green
    Write-Host "Failed: $($script:TestResults.Failed)" -ForegroundColor Red
    Write-Host "Warnings: $($script:TestResults.Warnings)" -ForegroundColor Yellow

    if ($script:TestResults.Failed -gt 0) {
        Write-Host "`n❌ CRITICAL ISSUES FOUND - Profile may not work correctly" -ForegroundColor Red
        Write-Host "Please fix the failed tests before installing the profile." -ForegroundColor Red
        exit 1
    } elseif ($script:TestResults.Warnings -gt 0) {
        Write-Host "`n⚠️  Some warnings detected - Profile should work but some features may be limited" -ForegroundColor Yellow
        exit 0
    } else {
        Write-Host "`n✅ All tests passed - Profile should work correctly" -ForegroundColor Green
        exit 0
    }
}

# Main execution
Write-Host "PowerShell Profile Validator" -ForegroundColor Magenta
Write-Host "Testing profile: $ProfilePath" -ForegroundColor Gray
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray

if (Test-ProfileExists) {
    Test-ProfileSyntax
    Test-Dependencies
    Test-ModuleAvailability
    Test-ProfileInSandbox
    Test-AliasConflicts
    Test-CrossPlatformCompatibility
}

Show-Summary