

$pluginName = "[[PLUGIN_NAME]]"
$attribNamePluginName = "[[PLUGIN_NAME" + "]]"
if ((! $pluginName) -or ($pluginName.trim() -eq "") -or ($pluginName.trim() -eq $attribNamePluginName)) {Write-Host "Updating plugin-name to: '[[PackageName]]'" -ForegroundColor Cyan; $pluginName = "[[PackageName]]"}
$pluginDirName = $pluginName
$notepadPlusPlusSoftwareName   = 'Notepad\+\+*'
$toolsPath = Split-Path -parent $MyInvocation.MyCommand.Definition
$pluginDllFileName = "$pluginName.dll"
$removePluginDir = $false

# Load helpers file
$helpersFile = Join-Path $toolsPath "helpers.ps1"
$helpersFile = Get-Item $helpersFile
Write-Host "Loading helpers file: $helpersFile"
. "$helpersFile"


# Read package parameters for notepad++ installation dir:
$pp = Get-PackageParameters
if ($pp -and $pp.Keys.Count -gt 0) {Write-Host "`nReceived package params:" -ForegroundColor Cyan; $pp.Keys | foreach {Write-Host $_ = $pp[$_]}; Write-Host "`n" }
if ($pp['nppInstallDir']) { $installLocation = $pp['nppInstallDir']}
if ($pp['removePluginDir']) { $removePluginDir = $true}


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


# Check plugin dir exists:
if (! (Test-Path -Path $pluginInstallLocation)) {Write-Warning "Plugin: '$pluginName' installation dir is missing from: $pluginInstallLocation `nNothing to do here.."; exit 0}


# Kill any running Notepad++ instances
killOpenProcesses "notepad++.exe"

# Check plugin dll file exists:
if (! (Test-Path -Path $pluginInstallLocationDllFile)) {
	Write-Warning "Plugin: '$pluginName' dll file is missing from: $pluginInstallLocationDllFile"
	checkAndRemovePluginDir $pluginInstallLocation
	exit 0
}

# Remove plugin DLL file
$errHelpMsg = "Failed to remove plugin dll: '$pluginInstallLocationDllFile'"
Write-Host "Removing plugin dll: $pluginInstallLocationDllFile"
Remove-Item -Path $pluginInstallLocationDllFile -Force
if (! $?) {Write-Host "Error - Remove action seems to have failed`n$errHelpMsg" -ForegroundColor RED ; exit 1}
if (Test-Path -Path $pluginInstallLocationDllFile) {Write-Host "Error - Remove action seems to have failed`n$errHelpMsg" -ForegroundColor RED ; exit 1}


checkAndRemovePluginDir $pluginInstallLocation
exit 0


