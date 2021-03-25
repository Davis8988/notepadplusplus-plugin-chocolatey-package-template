@echo off

set pkgName=notepadplusplus-plugin.template

pushd "%~dp0"

title pack
cpack
if %errorlevel% neq 0 echo Error - Failed packing %pkgName% pacakge && pause && exit 1

title uninstall
cuninst %pkgName% -y

title install
cinst %pkgName% -s . -y --force %*
if %errorlevel% neq 0 echo Error - Failed installing %pkgName% pacakge && pause && exit 1
