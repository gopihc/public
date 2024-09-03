$tapUrl = "https://swupdate.openvpn.org/community/releases/tap-windows-9.21.2.exe"
$openvpnUrl = "https://swupdate.openvpn.org/community/releases/OpenVPN-2.6.12-I001-amd64.msi"

$tapInstaller = "$env:TEMP\tap-windows-9.21.2.exe"
$openvpnInstaller = "$env:TEMP\OpenVPN-2.6.12-I001-amd64.msi"

$tapInstallLog = "$env:TEMP\tap-install.log"
$tapInstallErrorLog = "$env:TEMP\tap-install-error.log"
$openvpnInstallLog = "$env:TEMP\openvpn-install.log"
$openvpnInstallErrorLog = "$env:TEMP\openvpn-install-error.log"

function Is-TapInstalled {
    $tapInstalled = Get-CimInstance -ClassName Win32_PnPSignedDriver | Where-Object { $_.DeviceName -like "*TAP-Windows*" }
    return $tapInstalled -ne $null
}

function Is-OpenVPNInstalled {
    $openvpnInstalled = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*OpenVPN*" }
    return $openvpnInstalled -ne $null
}

function Test-Admin {
    $windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $windowsPrincipal = [System.Security.Principal.WindowsPrincipal]$windowsIdentity
    return $windowsPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Download-Installer {
    param (
        [string]$url,
        [string]$path,
        [string]$message
    )
    if (-not (Test-Path $path)) {
        Write-Output "$message"
        Invoke-WebRequest -Uri $url -OutFile $path
    } else {
        Write-Output "$message already downloaded."
    }
}

function Install-TapWindows {
    Write-Output "Starting TAP-Windows installation..."
    Start-Process -FilePath $tapInstaller -ArgumentList "/S" -Wait -NoNewWindow -RedirectStandardOutput $tapInstallLog -RedirectStandardError $tapInstallErrorLog
    Write-Output "TAP-Windows installation completed. Checking logs..."
    Get-Content -Path $tapInstallLog
    Get-Content -Path $tapInstallErrorLog
}

function Install-OpenVPN {
    Write-Output "Starting OpenVPN installation..."
    
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$openvpnInstaller`" /quiet /log `"$openvpnInstallLog`"" -Wait -NoNewWindow -PassThru -RedirectStandardError $openvpnInstallErrorLog
    

    $exitCode = $process.ExitCode

    Write-Output "OpenVPN installation completed with exit code: $exitCode"
    
   
    if ($exitCode -eq 0) {
        Write-Output "OpenVPN installation was successful. Checking logs..."
        Get-Content -Path $openvpnInstallLog
    } else {
        Write-Output "OpenVPN installation failed. Checking error logs..."
        Get-Content -Path $openvpnInstallErrorLog
    }
}

if (-not (Test-Admin)) {
    Write-Output "Script is not running with administrative permissions. Restarting as administrator..."
    $argList = $myinvocation.MyCommand.Definition + " " + $args -join " "
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$argList`"" -Verb RunAs
    exit
}

Download-Installer -url $tapUrl -path $tapInstaller -message "Downloading TAP-Windows installer"
Download-Installer -url $openvpnUrl -path $openvpnInstaller -message "Downloading OpenVPN installer"

if (-not (Is-TapInstalled)) {
    Install-TapWindows

} else {
    Write-Output "TAP-Windows is already installed. Skipping installation."
}


if (-not (Is-OpenVPNInstalled)) {
    Install-OpenVPN
} else {
    Write-Output "OpenVPN is already installed. Skipping installation."
}

function Remove-FileIfExists {
    param (
        [string]$filePath,
        [string]$message
    )
    if (Test-Path $filePath) {
        Remove-Item -Path $filePath -Force
        Write-Output "$message"
    } else {
        Write-Output "$message not found. Skipping deletion."
    }
}

Write-Output "Press Enter to exit..."
Read-Host

Remove-FileIfExists -filePath $tapInstaller -message "Deleted TAP-Windows installer"
Remove-FileIfExists -filePath $openvpnInstaller -message "Deleted OpenVPN installer"
Remove-FileIfExists -filePath $tapInstallLog -message "Deleted TAP-Windows installation log"
Remove-FileIfExists -filePath $tapInstallErrorLog -message "Deleted TAP-Windows installation error log"
Remove-FileIfExists -filePath $openvpnInstallLog -message "Deleted OpenVPN installation log"
Remove-FileIfExists -filePath $openvpnInstallErrorLog -message "Deleted OpenVPN installation error log"

Write-Output "Press Enter to exit..."
Read-Host
