@echo off
setlocal

set DEVICE_NAME=cfw-tap
set DEVICE_HWID=tap0901

set PATH=%PATH%;%SystemRoot%\system32;%SystemRoot%\system32\wbem;%SystemRoot%\system32\WindowsPowerShell/v1.0

netsh interface show interface name=%DEVICE_NAME% >nul
if %errorlevel% equ 0 (
  echo TAP network device already exists.
  goto :configure
)

set BEFORE_DEVICES=%tmp%\outlineinstaller-tap-devices-before.txt
set AFTER_DEVICES=%tmp%\outlineinstaller-tap-devices-after.txt

echo Creating TAP network device...
echo Storing current network device list...
wmic nic where "netconnectionid is not null" get netconnectionid > "%BEFORE_DEVICES%"
if %errorlevel% neq 0 (
  echo Could not store network device list. >&2
  exit /b 1
)
type "%BEFORE_DEVICES%"

echo Creating TAP network device...
%1\amd64\tapinstall install %1\amd64\OemVista.inf %DEVICE_HWID%
if %errorlevel% neq 0 (
  echo Could not create TAP network device. >&2
  exit /b 1
)
echo Storing new network device list...
wmic nic where "netconnectionid is not null" get netconnectionid > "%AFTER_DEVICES%"
if %errorlevel% neq 0 (
  echo Could not store network device list. >&2
  exit /b 1
)
type "%AFTER_DEVICES%"

echo Searching for new TAP network device name...
powershell "(compare-object (cat \"%BEFORE_DEVICES%\" | foreach-object {$_.trim()}) (cat \"%AFTER_DEVICES%\" | foreach-object {$_.trim()}) | format-wide -autosize | out-string).trim() | set-variable NEW_DEVICE; write-host \"New TAP device name: ${NEW_DEVICE}\"; netsh interface set interface name = \"${NEW_DEVICE}\" newname = \"%DEVICE_NAME%\"" <nul
if %errorlevel% neq 0 (
  echo Could not find or rename new TAP network device. >&2
  exit /b 1
)

echo Testing that the new TAP network device is visible to netsh...
netsh interface ip show interfaces | find "%DEVICE_NAME%" >nul
if %errorlevel% equ 0 goto :configure

:loop
echo waiting...
waitfor /t 10 thisisnotarealsignalname >nul 2>&1
netsh interface ip show interfaces | find "%DEVICE_NAME%" >nul
if %errorlevel% neq 0 goto :loop

:configure

echo (Re-)enabling TAP network device...
netsh interface set interface "%DEVICE_NAME%" admin=enabled

echo Configuring TAP device subnet...
netsh interface ip set address %DEVICE_NAME% static 10.0.0.1 255.255.255.0 10.0.0.0
if %errorlevel% neq 0 (
  echo Could not set TAP network device subnet. >&2
  exit /b 1
)

echo Configuring primary DNS...
netsh interface ip set dnsservers %DEVICE_NAME% static address=127.0.0.1
if %errorlevel% neq 0 (
  echo Could not configure TAP device primary DNS. >&2
  exit /b 1
)

echo Setting interface metric (1) for this interface...
powershell "Set-NetIPInterface -InterfaceAlias \"%DEVICE_NAME%\" -InterfaceMetric 1" <nul
if %errorlevel% neq 0 (
  echo Could not set interface metric. >&2
  exit /b 1
)

REM powershell "Remove-NetRoute -DestinationPrefix 0.0.0.0/0 -NextHop 10.0.0.0 -Confirm:$false" >nul

REM powershell "New-NetRoute -InterfaceAlias \"%DEVICE_NAME%\" -DestinationPrefix 198.18.0.0/16 -NextHop 10.0.0.0 -RouteMetric 1" >nul
powershell "Remove-NetRoute -DestinationPrefix 198.18.0.0/16 -NextHop 10.0.0.0 -Confirm:$false" >nul

if %errorlevel% equ 0 (
  REM powershell "Set-NetRoute -InterfaceAlias \"%DEVICE_NAME%\" -DestinationPrefix 198.18.0.0/16 -NextHop 10.0.0.0 -RouteMetric 1" >nul
)

echo TAP network device added and configured successfully 
