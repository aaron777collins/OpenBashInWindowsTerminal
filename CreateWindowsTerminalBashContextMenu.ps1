# PowerShell script to add context menu option with icon

# Function to check and prompt for admin rights
function Ensure-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
    if (-not $currentUser.IsInRole($adminRole)) {
        # Relaunch as administrator
        Start-Process PowerShell.exe -ArgumentList "-File",("`"" + $MyInvocation.MyCommand.Path + "`""), "-Verb", "RunAs"
        exit
    }
}

Ensure-Admin

# ANSI-like color function
function Write-Color {
    param([string]$Text, [ConsoleColor]$Color)
    $previousColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color
    Write-Host $Text -NoNewline
    $Host.UI.RawUI.ForegroundColor = $previousColor
}

# Default values
$default_name = "Open Bash In Windows Terminal"
$default_icon = "C:\Program Files\Git\mingw64\share\git\git-for-windows.ico"
$default_profile = "Git Bash"

# Prompt for custom values
Write-Color "Enter the name for the context menu option (default: $default_name): " -Color Yellow
$name = Read-Host
if ([string]::IsNullOrWhiteSpace($name)) { $name = $default_name }

Write-Color "Enter the full path to the icon (default: $default_icon): " -Color Yellow
$icon = Read-Host
if ([string]::IsNullOrWhiteSpace($icon)) { $icon = $default_icon }

Write-Color "Enter the Git Bash profile name in Windows Terminal (default: $default_profile): " -Color Yellow
$profile = Read-Host
if ([string]::IsNullOrWhiteSpace($profile)) { $profile = $default_profile }

# Adjusted registry paths
$regPathBase = "HKLM:\Software\Classes"
$regPath1 = "$regPathBase\Directory\Background\shell\$name"
$regPath2 = "$regPathBase\Directory\Background\shell\$name\command"
$regPath3 = "$regPathBase\Directory\shell\$name"
$regPath4 = "$regPathBase\Directory\shell\$name\command"

# Ensure running as Administrator
Ensure-Admin

# Correcting the path handling for the icon
$icon_escaped = $icon -replace '\\', '\\'

# Create registry entries
Try {
    New-Item -Path $regPath1 -Force
    New-ItemProperty -Path $regPath1 -Name "Icon" -Value $icon -PropertyType String -Force
    New-Item -Path $regPath2 -Force
    New-ItemProperty -Path $regPath2 -Name "(Default)" -Value "cmd.exe /c wt -p `"$profile`" -d ." -PropertyType String -Force

    New-Item -Path $regPath3 -Force
    New-ItemProperty -Path $regPath3 -Name "Icon" -Value $icon -PropertyType String -Force
    New-Item -Path $regPath4 -Force
    New-ItemProperty -Path $regPath4 -Name "(Default)" -Value "cmd.exe /c wt -p `"$profile`" -d ." -PropertyType String -Force

    Write-Color "The context menu option has been added successfully with the specified icon." -Color Green
} Catch {
    Write-Color "An error occurred: $_" -Color Red
}
