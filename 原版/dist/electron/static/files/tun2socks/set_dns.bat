@echo off
setlocal

set PATH=%PATH%;%SystemRoot%\system32;%SystemRoot%\system32\wbem;%SystemRoot%\system32\WindowsPowerShell/v1.0

set TAPDEVICENAME="cfw-tap"

rem :loop
rem echo waiting...
rem powershell "Get-NetIPInterface -InterfaceAlias \"%TAPDEVICENAME%\"" <nul
rem if %errorlevel% neq 0 (
rem 	waitfor /t 3 thisisnotarealsignalname >nul 2>&1
rem 	goto :loop
rem )

powershell "while (!(Get-NetIPInterface -InterfaceAlias \"%TAPDEVICENAME%\")) { Start-Sleep 1 }"

set dns=%1
set cmd="-ServerAddresses ('%dns%')"
if "%dns%"=="" (
  set cmd="-ResetServerAddresses"
)

echo Setting DNS(%1) for Default interface...
powershell "Set-DnsClientServerAddress -InterfaceAlias \"%TAPDEVICENAME%\" %cmd%" <nul
if %errorlevel% neq 0 (
  echo Could not set DNS. >&2
  exit /b 1
)

echo Flushing DNS to take effect.
powershell "Clear-DnsClientCache"