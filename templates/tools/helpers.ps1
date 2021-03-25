# Contains helper functions for chocolateyInstall.ps1 & chocolateyUninstall.ps1 scripts

function getNppInstallationDir($nppSoftwareName) {
### Returns Notepad++ installation dir or $null if it can't find it
	$_nppInstallationDir = Get-AppInstallLocation $nppSoftwareName

	if (! $_nppInstallationDir)  {
		Write-Warning "Can't find $notepadPlusPlusSoftwareName install location via Chocolatey"
		
		# Default Install Locations
		$notepadPlusPlusDefaultInstallLocations = [System.Collections.ArrayList]::new()
		$notepadPlusPlusDefaultInstallLocations.add("$(Join-Path $env:ProgramFiles 'Notepad++')") | Out-Null
		$notepadPlusPlusDefaultInstallLocations.add("$(Join-Path $env:ProgramW6432 'Notepad++')") | Out-Null
		$notepadPlusPlusDefaultInstallLocations.add("$(Join-Path ${env:ProgramFiles(x86)} 'Notepad++')") | Out-Null

		# Remove Duplicate Paths
		$notepadPlusPlusDefaultInstallLocations = $notepadPlusPlusDefaultInstallLocations | select -Unique
		
		Write-Host "Looking for $notepadPlusPlusSoftwareName installation dir in default locations:"
		$notepadPlusPlusDefaultInstallLocations | foreach {Write-Host " - $_"}
		
		# Check for first path that exists
		$notepadPlusPlusDefaultInstallLocations | foreach {if (Test-path -Path $_) {$_nppInstallationDir = $_; Write-Host "Found $notepadPlusPlusSoftwareName installation dir: $_nppInstallationDir" -ForegroundColor Yellow; return $_nppInstallationDir} }
	}
	
	return $_nppInstallationDir
}

function checkNppInstallationDirIsValid($nppInstallationDir) {
### Checks that provided path is actually a Notpad++ installation dir
###  by testing if it exists & contains a 'plugins' dir
	Write-Host "Validating $notepadPlusPlusSoftwareName installation dir: $nppInstallationDir"
	$errHelpMsg = "You can try to reinstall this package and provide the $notepadPlusPlusSoftwareName existing installation dir via param: '/nppInstallDir'. `nExample: choco install $pluginPkgName --yes --params `" /nppInstallDir:`"`"C:\Notepad++`"`" `" "
	if (! $nppInstallationDir) {Write-Host "Error - No $notepadPlusPlusSoftwareName installation dir provided ('nppInstallationDir' is null) `nFailed to find $notepadPlusPlusSoftwareName installation dir`n${errHelpMsg}" -ForegroundColor RED ; exit 1}
	if (! (Test-Path -Path $nppInstallationDir)) {Write-Host "Error - Missing or unreachable $notepadPlusPlusSoftwareName installation dir: '$nppInstallationDir'`n${errHelpMsg}" -ForegroundColor RED ; exit 1}
	$pluginsDir = Join-Path $nppInstallationDir "plugins"
	if (! (Test-Path -Path $pluginsDir)) {Write-Host "Error - Missing or unreachable $notepadPlusPlusSoftwareName plugins dir: '$pluginsDir'`n${errHelpMsg}" -ForegroundColor RED ; exit 1}
}

function checkAndRemovePluginDir($nppPluginDir) {
	# Check if plugin dll dir is empty - if so then remove it
	$directoryInfo = Get-ChildItem $nppPluginDir | Measure-Object
	# $directoryInfo.count  Returns the count of all of the objects in the directory
	if (($directoryInfo.count -gt 0) -and (! $removePluginDir)) {Write-Warning "Plugin: '$pluginName' dir: ${nppPluginDir} is not empty and flag: '/removePluginDir' was not received. You should delete it by yourself later"; exit 0}
	Write-Host "Removing plugin dir: '${nppPluginDir}' "
	
	# Delete dir content
	Get-ChildItem -Path $nppPluginDir -Recurse | Remove-Item -force -recurse
	# Remove the dir itself
	Remove-Item $nppPluginDir -Force
}


function createDir($directoryPath) {
### Creates a directory at a given path
### Fails execution upon failure
	if (! (Test-Path -Path $directoryPath)) {
		Write-Host "Creating dir: '$directoryPath'"
		New-Item -Type Directory -Path $directoryPath -Force
		if (! (Test-Path -Path $directoryPath)) {Write-Host "Error - Missing or unreachable dir: '$directoryPath'`nand also failed to create it" -ForegroundColor RED ; exit 1}
	}
}


function cleanup() {
# Removes dirs: 'x32' & 'x64' from 'tools' dir
	Write-Host "Cleaning unncessary files: $toolsPath\*.dll" -ForegroundColor Yellow
	if (! $toolsPath) {Write-Host "Resetting var: 'toolsPath'"; $toolsPath = Split-Path -parent $MyInvocation.MyCommand.Definition}
	Get-ChildItem -Recurse $toolsPath\*.dll | ForEach-Object { Remove-Item $_ -ea 0; if (Test-Path $_) { Set-Content "$_.ignore" '' } }
}


function killProcess($procName, $procId) {
	Write-Host "Killing process: '$procName'   pid: $procId" -ForegroundColor Yellow
	& "taskkill" "/f" "/t" "/PID" "$procId"
	if ($LASTEXITCODE -ne 0) {Write-Host "Error - Failed killing process: $procName" -ForegroundColor RED; return}
}


function killOpenProcesses($processName) {
	$ownPid = $pid
	Write-Host "Looking for processes with name: '$processName'"
	$targetProcessesList = Get-WmiObject Win32_Process | where { ($_.ProcessId -ne $ownPid) -and (($_.Caption -Like "*${processName}*") -or ($_.Name -Like "*${processName}*") -or ($_.Description -Like "*${processName}*") -or ($_.ProcessName -Like "*${processName}*")) }
	if (! $targetProcessesList) {return}
	
	if (! $targetProcessesList.Count) {Write-Host "Found 1 process to kill"; killProcess $targetProcessesList.Name $targetProcessesList.ProcessId; return}
	Write-Host "Found $($targetProcessesList.Count) processes to kill" -ForegroundColor Cyan
	$targetProcessesList | foreach {killProcess $_.Name $_.ProcessId}  # Multiple processes
}


