$ErrorActionPreference = 'Stop'

$pluginName = "[[PLUGIN_NAME]]"
$pluginPkgName = $env:ChocolateyPackageName
$pluginPkgVersion = $env:ChocolateyPackageVersion
if ((! $pluginName) -or ($pluginName.trim() -like "*[PLUGIN_NAME]*") -or ($pluginName.trim() -eq "")) {$pluginName = "bettermultiselection"}
$pluginDirName = $pluginName
$notepadPlusPlusSoftwareName   = 'Notepad\+\+*'
$toolsPath = Split-Path -parent $MyInvocation.MyCommand.Definition
$pluginDll = $null
$pluginDllFileName = "$pluginName.dll"
$skipIfAlreadyInstalled = $false

# Load helpers file
$helpersFile = Join-Path $toolsPath "helpers.ps1"
$helpersFile = Get-Item $helpersFile
Write-Host "Loading helpers file: $helpersFile"
. "$helpersFile"

if ((Get-ProcessorBits 32) -or ($env:ChocolateyForceX86 -eq $true)) {
	Write-Host "Installing x32 bit version" -ForegroundColor Yellow
	$pluginDll = Get-Item "$(Join-Path $toolsPath `"x32\$pluginDllFileName`")"
} else {
	Write-Host "Installing x64 bit version" -ForegroundColor Yellow
	$pluginDll = Get-Item "$(Join-Path $toolsPath `"x64\$pluginDllFileName`")"
}


# Check plugin DLL exists and reachable
if (! $pluginDll) {Write-Host "Error - Missing or unreachable plugin dll file: '$pluginDll'" -ForegroundColor RED ; exit 1}



# Read package parameters for notepad++ installation dir:
$pp = Get-PackageParameters
if ($pp -and $pp.Keys.Count -gt 0) {Write-Host "`nReceived package params:" -ForegroundColor Cyan; $pp.Keys | foreach {Write-Host $_ = $pp[$_]}; Write-Host "`n" }
if ($pp['nppInstallDir']) { $installLocation = $pp['nppInstallDir']}
if ($pp['skipIfAlreadyInstalled']) { $skipIfAlreadyInstalled = $true}


# Attempt to get current installed notepad++ dir
if (! $installLocation) {
	Write-Host "Did not receive param: '/nppInstallDir' - Attempting to locate $notepadPlusPlusSoftwareName installation dir"
	$installLocation = getNppInstallationDir $notepadPlusPlusSoftwareName
}

# Validate
checkNppInstallationDirIsValid $installLocation

# Prepare envs
$pluginsDir = Join-Path $installLocation "plugins"
$pluginInstallLocation = Join-Path $pluginsDir "$pluginDirName"
$pluginInstallLocationDllFile = Join-Path $pluginInstallLocation $pluginDllFileName

# Make sure dest plugin dir exists
createDir $pluginInstallLocation

# Check if already exists
if ((Test-Path -Path $pluginInstallLocationDllFile) -and $skipIfAlreadyInstalled) {
	Write-Host "Found plugin dll: '$pluginInstallLocationDllFile' `nPlugin: '$pluginName' is already installed"
	Write-Host " and flag: '/skipIfAlreadyInstalled' was received - skipping installation of this plugin's version: '$pluginPkgVersion'" -ForegroundColor Yellow
	cleanup
	exit 0
}

# Kill any running Notepad++ instances
killOpenProcesses "notepad++.exe"

# Removing any existing previous installed plugin dll files
Write-Host "Checking for existing previous installation of plugin: '$pluginName' dll files under: '$pluginInstallLocation'"
$existingPluginDllFiles = Get-ChildItem $pluginInstallLocation\*.dll
if ($existingPluginDllFiles -and ($existingPluginDllFiles.Length -gt 0)) {
	Write-Host "Removing any existing previous installed plugin: '$pluginName' dll files under: '$pluginInstallLocation'" -ForegroundColor Yellow
	$existingPluginDllFiles | foreach {Write-Host " - $_"}
	$existingPluginDllFiles | ForEach-Object { Remove-Item $_ -Force; Start-Sleep -Milliseconds 200; if (Test-Path $_) {Write-Host "Error - Failed to remove existing plugin: '$pluginName' previous installed dll file: '$_' `nFile might be in use.`nTry removing it yourself and reinstall this package" -ForegroundColor RED ; exit 1} }
}


# Copy plugin new dll file to: $pluginInstallLocation
Write-Host "Copying plugin: '$pluginName' new dll file `n from: '$pluginDll' to: '$pluginInstallLocation' "
$errHelpMsg = "Failed to copy plugin: '$pluginName' new dll file`n from: '$pluginDll' to: '$pluginInstallLocation'"
Copy-Item -Path $pluginDll -Destination $pluginInstallLocation -Force
if (! $?) {Write-Host "Error - Copy command seems to have failed `n$errHelpMsg" -ForegroundColor RED ; exit 1}
if (! (Test-Path -Path $pluginInstallLocationDllFile)) {Write-Host "Error - Missing or unreachable: '$pluginInstallLocationDllFile' `n$errHelpMsg" -ForegroundColor RED ; exit 1}


# Success
Write-Host "Success - Finished installing plugin: '$pluginName' new dll file to: '$pluginInstallLocation' " -ForegroundColor Green

# Cleanup func call
cleanup

Write-Host "Done"



