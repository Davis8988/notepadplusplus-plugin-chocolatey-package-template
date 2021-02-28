@echo off

set pkgName=notepadplusplus-plugin.template

title pack
cpack
if %errorlevel% neq 0 echo Error - Failed packing %pkgName% pacakge && pause && exit 1

title install
cinst notepadplusplus-plugin.template -s . -y
if %errorlevel% neq 0 echo Error - Failed installing %pkgName% pacakge && pause && exit 1
