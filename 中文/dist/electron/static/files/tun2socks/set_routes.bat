@echo off
setlocal

set PATH=%PATH%;%SystemRoot%\system32;%SystemRoot%\system32\wbem;%SystemRoot%\system32\WindowsPowerShell/v1.0

set TAPDEVICENAME="cfw-tap"

rem :loop
rem echo waiting...
rem powershell "Get-NetIPInterface -InterfaceAlias \"%TAPDEVICENAME%\" -AddressFamily ipv4 -ConnectionState connected" < nul
rem if %errorlevel% neq 0 (
rem   waitfor /t 2 thisisnotarealsignalname >nul 2>&1
rem   goto :loop
rem )

REM powershell "while (!(Get-NetIPInterface -InterfaceAlias \"%TAPDEVICENAME%\" -AddressFamily ipv4 -ConnectionState connected)) { Start-Sleep 1 }"

powershell "Remove-NetRoute -DestinationPrefix 0.0.0.0/0 -NextHop 10.0.0.0 -Confirm:$false" >nul

powershell "New-NetRoute -InterfaceAlias \"%TAPDEVICENAME%\" -DestinationPrefix 198.18.0.0/16 -NextHop 10.0.0.0 -RouteMetric 1" >nul

if %errorlevel% equ 0 (
  powershell "Set-NetRoute -InterfaceAlias \"%TAPDEVICENAME%\" -DestinationPrefix 198.18.0.0/16 -NextHop 10.0.0.0 -RouteMetric 1" >nul
)