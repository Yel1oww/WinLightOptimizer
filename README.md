# ⚡ Win Light Optimizer

> **An aggressive Windows performance toolkit built exclusively for gaming PCs.**
> Fast. Opinionated. Not designed to be secure.

![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-blue?style=flat-square&logo=windows)
![Language](https://img.shields.io/badge/Language-Batch%20%2F%20PowerShell-green?style=flat-square)
![Purpose](https://img.shields.io/badge/Purpose-Gaming%20Performance-red?style=flat-square)
![Admin](https://img.shields.io/badge/Requires-Administrator-orange?style=flat-square)

---

## 🔴 IMPORTANT — After Rebooting, Check Your Power Plan

> **After the script finishes and you restart your PC, open Power Options and make sure the CoreVeeAir plan is selected.**

After reboot, go to: **Control Panel → Hardware and Sound → Power Options**

You should see **CoreVeeAir's** listed. Click the radio button next to it to make sure it is the active plan.

**Why this matters:** The power plan is imported and activated during the script run, but on some systems — particularly those with Modern Standby (S0) — Windows reverts to the default Balanced plan after rebooting. This has been tested directly: running without the CoreVeeAir plan selected causes a significant FPS drop. On Black Desert Online for example, the difference was **270 FPS (Balanced) vs 320 FPS (CoreVeeAir's)** — a loss of 50 frames just from having the wrong power plan active.

If CoreVeeAir is not listed at all, re-run the script and run Option 1 again — Step 13 will re-import and re-activate it.

---

## ⚠️ READ THIS BEFORE YOU RUN ANYTHING

**Win Light Optimizer is not a general-purpose Windows tweaker. It was built for dedicated gaming machines where performance is the only priority.**

By running this tool you are accepting the following:

| What gets disabled | Why it matters |
|--------------------|----------------|
| **Windows Update** | Your system will no longer receive security patches |
| **Windows Defender** (temporarily during run) | Malware could execute undetected during the optimization window |
| **Spectre & Meltdown mitigations** | Known CPU side-channel vulnerabilities are re-exposed |
| **UAC (User Account Control)** | Any software on your PC gains silent administrator access |
| **Core Isolation / Memory Integrity** | Kernel-level exploit protection is removed |
| **TLS 1.0 / TLS 1.1** | Some legacy software or internal network tools may stop working |
| **SMB1** | Legacy file sharing (rarely needed, known ransomware vector) |
| **Storage Sense** | Windows will stop auto-managing disk cleanup in the background |

**This tool is not suitable for:**
- Work or office machines
- Laptops that store sensitive personal data
- Any PC connected to a corporate or enterprise network
- Users who are not comfortable with the above tradeoffs

If you do not understand what a step does, **do not run this tool.**

---

## 🧰 What is Win Light Optimizer?

A single `.bat` file that combines three tools into one interactive menu. No installers, no dependencies beyond what Windows already has.

```
  =====================================================
       Win Light Optimizer
  =====================================================

   [1]  System Optimizations
   [2]  Clean Temp Files
   [3]  Windows Update  (Enable / Disable)
   [4]  Windows Activation
   [0]  Exit

  =====================================================
```

| Option | Tool | Purpose |
|--------|------|---------|
| `[1]` | **System Optimizations** | 33-step aggressive Windows configuration for gaming |
| `[2]` | **Clean Temp Files** | Frees disk space by removing system junk |
| `[3]` | **Windows Update Toggle** | Disable or fully restore Windows Update on demand |
| `[4]` | **Windows Activation** | Activate Windows using MAS (Microsoft Activation Scripts) |

---

## 🚀 How to Use

1. **Right-click** `WinLightOptimizer.bat` → **Run as Administrator**
2. Select an option from the menu
3. After Option 1, **restart your PC** — many changes require a reboot to take full effect
4. After rebooting, verify your power plan is active: open Power Options and confirm **CoreVeeAir** is selected

> The Core.pow custom power plan is embedded directly inside the script — no extra files needed.

---

## 📋 Option 1 — System Optimizations (33 Steps)

Each step is tracked individually. The summary at the end shows exactly which steps passed and which failed, with a note that many failures are harmless (unsupported registry key on your Windows version, a service that does not exist on your hardware, etc.).

Windows Activation has been moved to **Option 4** in the main menu and no longer runs as part of the optimization steps.

---

### Step 1 — Visual Performance
Switches Windows to Best Performance visual mode. Disables taskbar animations, window transition animations, menu animations, and smooth scrolling. These are rendered by the GPU and consume frame time even when a game is running in the background or on a second monitor.

---

### Step 2 — Timeout Tweaks
Cuts Windows hung-application and service kill timeouts from their defaults (5–30 seconds) down to 1 second. Reboots and shutdowns become near-instant. Frozen apps no longer block other processes while Windows waits.

---

### Step 3 — Registry Tweaks
- Disables Live Tiles notification push
- Disables Windows Ink Workspace
- Sets GPU power transition latency values to their minimum (1ms) — prevents the GPU driver from introducing delays during D3 power state transitions
- **Disables UAC entirely** — see warning above. Zero performance benefit but included as many gaming tools and anti-cheat systems interact more reliably without UAC elevation prompts

---

### Step 4 — CPU Tweaks
- **Win32PrioritySeparation = 42 — long quantum, variable, maximum foreground boost. Value 2 (Windows default) favours input latency and is better for competitive shooters. Value 42 uses longer CPU time quanta per thread, giving better raw FPS in CPU-heavy engines. Tested on Black Desert Online: +50 FPS with 42 over 2 (270 vs 320). For open world or simulation-heavy games, 42 wins on frames. For competitive shooters prioritising input latency, consider 2
- **CPU idle states disabled** — prevents the processor from entering C-states between frames, eliminating the latency spike when a core wakes from deep sleep. Increases idle heat and power draw — acceptable on a desktop, noticeable on a laptop
- **CsEnabled = 0** — disables Connected Standby / Modern Standby, required on some Windows 11 systems before custom power plans can be selected
- **Power Throttling disabled** — stops Windows from deprioritising threads it considers background work, which can incorrectly throttle game threads on hybrid-core CPUs

---

### Step 5 — Display Tweaks
Disables Adaptive Refresh Rate management, Panel Self-Refresh, and Video Idle Timeout at the GraphicsDrivers level. Ensures your display runs at a fixed uninterrupted refresh rate. Panel Self-Refresh can cause visible flicker or added latency on certain monitor and GPU combinations.

---

### Step 6 — GPU Tweaks
- Disables Frame Buffer Compression
- Enables GPU Boost
- Disables the GPU Energy Driver which throttles GPU clocks for power saving
- Enables **Hardware-Accelerated GPU Scheduling (HAGS)** — the GPU manages its own memory scheduling without going through the CPU, reducing CPU-to-GPU latency. Requires NVIDIA RTX 2000+ or AMD RX 5000+
- **GameConfigStore** — fullscreen/windowed optimization flags (FSEBehaviorMode, DSEBehavior, EFSEFeatureFlags)
- **SwapEffectUpgrade** — enables DirectX windowed game optimizations (`SwapEffectUpgradeEnable=1`)
- **DirectXUserGlobalSettings** — global DirectX GPU preferences for swap effect upgrades
- **GPU Scheduler additions** — `EnableReclaim=1`, `EnableExplicitVidMm=1`, `FrameLatency=1`
- **Direct3D tuning** — `DisableDebugLayer=1`, `ForceGPUPreemption=1`
- **DXGKrnl monitor latency** — `MonitorLatencyTolerance=1`, `MonitorRefreshLatencyTolerance=1`

---

### Step 7 — Network Tweaks
- **TCP/IP tuning** — disables timestamps, reduces delayed ACK ticks, tunes retransmission count and IRPStackSize
- **AFD (Ancillary Function Driver)** — sets send/receive window sizes to 256KB, disables dynamic send buffer resizing
- **DNS** — primary 1.1.1.1 (Cloudflare), secondary 8.8.8.8 (Google), negative cache time set to 0
- **QoS** — removes Windows' default 20% bandwidth reservation
- **Network Discovery** disabled via firewall (language-neutral rule ID used, works on all Windows language installs)
- **IPv6 fully disabled** — forces IPv4-only, eliminates dual-stack DNS resolution delays
- `NetworkThrottlingIndex` set to unlimited
- **WifiSense disabled** — Microsoft's automatic WiFi credential sharing and hotspot auto-connection. Prevents Windows from sharing saved WiFi passwords with contacts and auto-connecting to unknown networks

---

### Step 8 — System & USB Tweaks
- **USB Selective Suspend disabled** — prevents USB peripherals (mice, keyboards, headsets) from being put to sleep, eliminating wakeup-caused input stutter
- **Power Throttling disabled** system-wide
- **Hibernation disabled** — removes hiberfil.sys
- **GlobalTimerResolutionRequests = 1** — allows applications to request 0.5ms timer resolution
- **USBXHCI enhanced power management disabled** — prevents the USB host controller from throttling bandwidth

---

### Step 9 — Boot & CPU Scheduler Tweaks
Uses bcdedit to configure low-level boot behaviour. Note: the more aggressive timer and clock settings (tscsyncpolicy, x2apicpolicy, disabledynamictick, useplatformclock/tick) have been removed from this step — they caused alt+tab crashes and full in-game crashes on some hardware combinations (particularly in CS2 and other fullscreen exclusive titles).

What remains is stable across all tested hardware:

| Setting | Effect |
|---------|--------|
| `bootux normal` | Standard Windows boot (no animation removal that could conflict) |

---

### Step 10 — Disable RDP
Disables the Remote Desktop Protocol listener. Removes an attack surface and stops the service from consuming port 3389.

---

### Step 11 — Security Hardening
Security improvements included in the script:
- Disables SSL 2.0, SSL 3.0, TLS 1.0, TLS 1.1 — forces TLS 1.2+
- Disables SMB1 (EternalBlue / WannaCry attack vector)
- Disables NetBIOS over TCP/IP
- Forces NTLMv2 only, disables LM hash storage
- Disables LLMNR and multicast DNS

---

### Step 12 — Block Microsoft Telemetry
Three-layer telemetry block:

1. **HOSTS file** — maps telemetry domains to `0.0.0.0`. Windows Defender actively monitors this file (SettingsModifier:Win32/HostsFileHijack) so a specific threat allow rule is added and Defender services are stopped before writing
2. **DNS NRPT** (Name Resolution Policy Table) — redirects DNS queries for telemetry domains to an invalid server (`0.0.0.1`). Defender never monitors NRPT, so this works even when the HOSTS write is blocked
3. **Windows Firewall outbound block** — blocks all outbound traffic from the DiagTrack (Connected User Experiences and Telemetry) service

Domains blocked: `vortex.data.microsoft.com`, `settings-win.data.microsoft.com`, `watson.telemetry.microsoft.com`, `ocsp.digicert.com`, `fe3.delivery.mp.microsoft.com`, `wpad.microsoft.com`, `browser.events.data.microsoft.com`, `activity.windows.com`

---

### Step 13 — Core Power Plan (CoreVeeAir)
Imports and activates a custom power plan embedded directly in the script as base64, decoded at runtime using PowerShell's `[IO.File]::WriteAllBytes` rather than certutil (which Defender flags as suspicious).

The activation sequence is:
1. Decode and write Core.pow to a temp file
2. Run `powercfg -import`
3. **Verify** the GUID appears in `powercfg -list` before proceeding — if import failed silently, stop and report failure rather than pointing Windows at a missing scheme (which causes severe throttling)
4. Run `powercfg -setactive e62924f9-...` for immediate activation
5. Always write `ActivePowerScheme` to the registry too — ensures the plan is selected after reboot on **Modern Standby (S0)** systems where `powercfg -setactive` is blocked until `PlatformAoAcOverride=0` takes effect
6. Apply CPU idle-disable settings **directly to the CoreVeeAir plan GUID** so the plan carries its own performance profile and does not depend on prior state

---

### Step 14 — Disable Event Trace Sessions (ETS)
Stops 18 background tracing sessions including NTFSLog, WiFi tracing, SleepStudy, telemetry listeners, RDP graphics tracing, and NVIDIA ShadowPlay. These continuously write trace data to disk and consume CPU cycles on features not needed during gaming.

---

### Step 15 — Privacy & Bloat Tweaks
Disables via Group Policy registry keys: location services, message sync, Microsoft Edge background processes and tracking, News and Interests, Activity Feed, Advertising ID, App Compatibility Telemetry, Windows Spotlight, Copilot and Cortana, diagnostic data collection, Delivery Optimization P2P sharing, Error Reporting, Game DVR, handwriting data sharing, and input personalisation.

---

### Step 16 — Additional Privacy Tweaks
Disables: password reveal button, tailored experiences, speech model auto-downloads, all CEIP programs (AppV, IE, Messenger, SQMClient), Windows Search cloud and web integration, OneDrive sync service, and background app refresh globally.

---

### Step 17 — Custom Visual Effects
Handpicked visual settings — keeps effects that help usability, removes ones that waste GPU time:

| Effect | State |
|--------|-------|
| Show window contents while dragging | On |
| Smooth font edges | On |
| Thumbnail previews | On |
| Taskbar animations | Off |
| Menu show delay | 0ms |
| Window minimize/maximize animation | Off |
| Mouse cursor shadow | Off |
| **Pointer precision (mouse acceleration)** | Off — raw 1:1 mouse input |
| Desktop transparency | Off |

Explorer is restarted at the end of this step so changes apply immediately.

---

### Step 18 — PowerShell Execution Policy
Sets execution policy to Unrestricted machine-wide. Required for running unsigned scripts without `-ExecutionPolicy Bypass` on every invocation.

---

### Step 19 — Disable Core Isolation & Memory Integrity
Virtualisation-Based Security (VBS) isolates critical kernel memory. Memory Integrity (HVCI) prevents unsigned drivers from being injected into the kernel. Disabling both recovers the CPU cycles and memory bandwidth that VBS consumes. Impact is most visible on CPU-bound games and older hardware. **This removes a real security layer.** Permanent — not restored when Defender is re-enabled at the end of the script.

---

### Step 20 — Disable Spectre & Meltdown Mitigations
Removes software patches for Spectre (CVE-2017-5753, CVE-2017-5715) and Meltdown (CVE-2017-5754). These add overhead to every kernel-userspace transition.

**Performance gain:** 2–5% on modern CPUs, up to 15–20% on older ones (Intel 6th–8th gen, Ryzen 1000/2000 series).

**Risk on a dedicated gaming PC:** low in practice. Exploitation requires attacker-controlled code running locally. On any other type of machine, do not disable these.

---

### Step 21 — Disable Unnecessary Services
Permanently disables services with no gaming function. Notable ones include SysMain (Superfetch), WSearch (indexer), Themes (visual theme engine — system falls back to Windows Classic look), Spooler (printing breaks), GameInputSvc, WerSvc, and TabletInputService.

---

### Step 22 — Scheduled Tasks Cleanup
Disables 36 background tasks including the Compatibility Appraiser, all CEIP tasks, Scheduled Defrag, Disk Diagnostics, Feedback telemetry, input sync tasks, WinSAT benchmark, Maps updates, network trace collection, power efficiency diagnostics, speech model downloads, Xbox Game Save, and Windows Update scan tasks. Also permanently disables Windows Automatic Maintenance.

---

### Step 23 — Disk & File System Tweaks
- **NTFS Last Access Timestamp disabled** — eliminates unnecessary disk writes on every file open in large game asset directories
- **8.3 filename generation disabled** — removes legacy DOS short-name aliases from directory operations
- **Storage Sense disabled** — stops Windows from automatically deleting files it considers redundant. On a gaming PC you control what gets deleted
- **Hibernation fully disabled** — removes hiberfil.sys (file size equals your RAM), frees that disk space, speeds up shutdown
- **Pagefile set to a fixed size** based on installed RAM (eliminates dynamic resize overhead during gameplay):
  - Less than 8 GB RAM → 8192 MB
  - 8 to 16 GB RAM → 4096 MB
  - More than 16 GB RAM → 2048 MB

---

### Step 24 — UI & Taskbar Cleanup
Removes Widgets and Chat icons from taskbar, disables Start Menu recommendations, disables lock screen ads and Spotlight, removes OneDrive from File Explorer sidebar, disables Bing in Start Menu, and permanently disables Sticky Keys / Toggle Keys / Filter Keys shortcuts — the Shift x5 popup during gaming is gone.

---

### Step 25 — Audio Tweaks
- **Audio enhancements disabled** on all render devices — removes Windows DSP processing (EQ, reverb) that adds latency and distortion
- **MMCSS tuning** — raises audio thread scheduling priority: NoLazyMode=1, AlwaysOn=1, task priority=6, GPU priority=8, clock rate=10,000 (1ms audio scheduling resolution)

---

### Step 26 — NVIDIA & AMD GPU Cleanup
- **NvTelemetryContainer** disabled — NVIDIA background telemetry service
- **ULPS (Ultra Low Power State) disabled** on all GPU class entries — prevents the GPU from entering deep idle between frames, eliminating the frame time spike at the start of each new scene
- **AMD Crash Defender** and **AMD External Events Utility** disabled (no-op on NVIDIA systems)

---

### Step 27 — Remove Microsoft Edge
Physically removes Microsoft Edge from the system rather than just disabling it via policy:
- Runs Edge's own `setup.exe --force-uninstall` if present
- Deletes all Edge folders (`%ProgramFiles(x86)%\Microsoft\Edge`, EdgeCore, local AppData)
- Removes shortcuts and registry entries
- Blocks Edge from reinstalling via the `DoNotUpdateToEdgeWithChromium` policy key
- Creates dummy locked folders at the Edge install path so the Windows update mechanism cannot write there

Note: WebView2 (used by some apps) is separate from Edge and is not removed.

---

### Step 28 — Remove OneDrive Completely
Goes further than just disabling the sync service — runs the official Microsoft uninstaller and cleans up everything left behind:
- `OneDriveSetup.exe /uninstall`
- Removes `%UserProfile%\OneDrive`, `%LocalAppData%\Microsoft\OneDrive`, `%ProgramData%\Microsoft\OneDrive`, `OneDriveTemp`
- Removes all shortcuts from Start Menu and Desktop
- Removes the OneDrive namespace from File Explorer sidebar
- Adds a policy key blocking OneDrive from reinstalling itself through Windows Update

---

### Step 29 — Remove Microsoft Store Bloatware
Removes ~50 pre-installed Microsoft and third-party apps using `Remove-AppxPackage` and `Remove-AppxProvisionedPackage` (the provisioned version prevents them from being reinstalled for new user accounts):

Removed apps include: Clipchamp, 3D Builder, Cortana, Bing Finance/News/Sports/Weather, Copilot, Microsoft Journal, Office Hub, Solitaire Collection, Sticky Notes, Mixed Reality Portal, Skype, Todos, Dev Home, Alarms, Feedback Hub, Maps, Sound Recorder, Xbox apps (Xbox app, TCUI, Gaming Overlay, Game Overlay, Speech-to-Text), Movies & TV, Microsoft Family, Quick Assist, both versions of Teams (personal and work), Phone Link, Outlook, Messaging, Amazon Prime Video, Facebook, Candy Crush (all variants), Bubble Witch, Netflix, Spotify, TikTok, Twitter/X.

---

### Step 30 — UI, Explorer and System Cleanup
A collection of quality-of-life changes and system cleanup:

| Change | Effect |
|--------|--------|
| Show file extensions | `.exe`, `.bat`, `.dll` etc. now visible in Explorer |
| Windows 10 right-click menu | Removes the "Show more options" extra click on Windows 11 |
| Left-align taskbar | Moves taskbar icons to left (Windows 11 default is centred) |
| Hide Search icon | Removes the Search button from taskbar |
| Instant taskbar previews | `ExtendedUIHoverTime = 1` — window thumbnails appear instantly |
| Explorer opens to This PC | `LaunchTo = 1` instead of Home/Quick Access |
| Remove Home from sidebar | Removes the Windows 11 Home namespace from Explorer sidebar |
| Remove Gallery from sidebar | Removes the Gallery namespace from Explorer sidebar |
| Clear Start Menu pins | Removes `start2.bin` and `LayoutModification.xml` — resets Start to minimal default |
| Microsoft 365 ads disabled | Removes promotional content from Windows Settings |
| Hide Settings Home page | Removes the Home tab from Windows 11 Settings |
| Disable Paint AI (Cocreator) | Disables Generative AI and Cocreator features in Paint |
| Disable Notepad AI (Rewrite) | Disables the AI rewrite feature in Notepad |
| Disable WPBT | `DisableWpbtExecution = 1` — stops OEM/manufacturer scripts that live in BIOS firmware from running at Windows startup. These are scripts that survive full Windows reinstalls because they're stored on the motherboard, not the drive |

---

### Step 31 — NVIDIA 3D Profile (NVIDIA GPUs only)
Automatically skipped on non-NVIDIA systems. On systems with an NVIDIA GPU — including laptops where the discrete GPU is the second adapter listed — this step:

1. **Detects the GPU** using `wmic path win32_VideoController` which queries all video controllers so discrete laptop GPUs are caught even when the iGPU is listed first
2. **Downloads NVIDIA Profile Inspector** at runtime from the project GitHub (the portable `.exe` is deleted immediately after use)
3. **Applies a custom NIP profile** embedded directly in the script as base64 — decoded, applied via `nvidiaProfileInspector.exe profile.nip` which writes settings directly to the NVIDIA driver database, then deleted
4. **Writes `Splendid=1`** to `HKCU\Software\NVIDIA Corporation\Global\NVTweak` — this enables "Use advanced 3D image settings" in NVIDIA Control Panel at the UI level (the NIP handles the driver level, the registry handles the UI toggle)

---


---

### Step 32 — ISLC Setup
Automatically downloads and configures Intelligent Standby List Cleaner (ISLC) to prevent memory-related stuttering in games.
- Checks if ISLC is already installed or currently running.
- Downloads the executable and your pre-configured `.Config` file directly from GitHub.
- Dynamically calculates exactly half of your system's physical RAM and injects it as the `WantedFreeRAM` threshold in the config.
- Launches the app minimized to the system tray, allowing it to register its own auto-start Task Scheduler entry.

---


---

### Step 33 — Advanced Privacy Settings
Downloads and silently applies **O&O ShutUp10++** with a curated 296-setting privacy configuration. Requires internet connection. Covers settings not accessible via standard registry tweaks, organised into categories:

- **Privacy** — handwriting data, advertising ID, CEIP, typing telemetry, app notifications, language sharing
- **Activity History & Clipboard** — disables activity recording, clipboard history, cross-device clipboard sync
- **App Privacy** — per-category app access controls: account info, diagnostics, location, camera, microphone, voice activation, contacts, calendar, call history, email, tasks, messages, wireless, documents, images, videos, file system, screenshots, music library, downloads
- **Security** — password reveal button, user steps recorder, telemetry reporting
- **Microsoft Edge** — comprehensive Edge tracking, autofill, payment methods, personalisation, shopping assistant, sidebar, Copilot, AI features, diagnostics, startup boost, new tab content, spell checking, SmartScreen
- **Settings Synchronisation** — disables all sync: design, browser settings, credentials, language, accessibility, advanced Windows settings
- **Cortana & Copilot** — Cortana, online speech recognition, cloud search, Copilot button, Recall, Paint AI (Cocreator), Notepad AI
- **Location Services** — all location service components
- **User Behaviour** — application telemetry, diagnostic data, log collection, OneSettings downloads
- **Windows Update** — P2P update sharing, driver updates, speech module updates, automatic app updates
- **Windows Explorer** — app suggestions in Start, recently opened items in Jump Lists, OneDrive ads
- **Taskbar** — People icon, search box, Meet Now, News and Interests
- **Miscellaneous** — feedback reminders, Store app auto-installation, Windows Media diagnostics, remote assistance, map data auto-updates, Phone Link / mobile device access



## 🎮 Option 4 — Windows Activation
Runs [MAS (Microsoft Activation Scripts)](https://massgrave.dev) to activate Windows. Requires internet connection. Follow the on-screen prompts.

This was moved out of the optimization steps so it can be run independently at any time without re-running all optimization steps.

---


## 🧹 Option 2 — Clean Temp Files

Clears system junk and reports disk space freed before and after.

| Step | What it does |
|------|-------------|
| Windows Temp | Deletes and recreates `%SystemRoot%\Temp` |
| User Temp | Clears `%TEMP%` |
| Prefetch | Removes prefetch files (rebuilt on next boot) |
| Update Cache | Stops WU services, clears `SoftwareDistribution\Download`, restarts |
| Log Files | Deletes `.log` files from system log paths |
| Event Viewer | Clears all event log channels via `wevtutil cl` |
| DNS Cache | `ipconfig /flushdns` |
| Winsock | `netsh winsock reset` |
| Recycle Bin | Empties `C:\$Recycle.Bin` |
| Disk Cleanup | Runs `cleanmgr /sagerun:1` silently |

---

## 🔄 Option 3 — Windows Update Toggle

### Disable
- Adds Group Policy keys blocking all Windows Update internet access
- Sets `NoAutoUpdate = 1`
- Disables and stops `dosvc`, `wuauserv`, `UsoSvc`

### Enable
- Removes all blocking policy keys
- Restores `dosvc`, `wuauserv`, `UsoSvc`, `bits`, `cryptsvc`, `TrustedInstaller` to automatic startup
- Starts all services

---

## 🔬 Honest Assessment

**Genuinely effective:**
Spectre/Meltdown mitigation removal, Core Isolation disable, CPU idle states off, HAGS, ULPS off, USB Selective Suspend off, fixed pagefile, audio enhancement disable, service and task cleanup (especially on lower-end systems).

**Small but real:**
DNS to 1.1.1.1, Win32PrioritySeparation, MMCSS tuning, network buffer tweaks.

**Mostly placebo on modern Windows 10/11:**
The large `GraphicsDrivers\Power` latency registry block and most of the AFD parameter list — circulated from Windows 7-era guides, not shown to affect modern systems in controlled testing.

---

## 🛡️ Restoring Security

```batch
:: Re-enable UAC
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d 1 /f

:: Re-enable Spectre/Meltdown mitigations
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d 3 /f

:: Re-enable Core Isolation
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 1 /f
```

Reboot after running. Use Option 3 in the toolkit to re-enable Windows Update.

---

## 📁 Files

| File | Description |
|------|-------------|
| `WinLightOptimizer.bat` | The only file you need — all tools in one file |
| `Core.pow` | Custom power plan source (already embedded in the bat, not required separately) |

---

## ⚙️ Requirements

- Windows 10 or Windows 11 (x64)
- Run as Administrator
- PowerShell 5.0+ (included in all Windows 10/11 builds)
- Internet required only for Option 4 (Windows Activation) and Step 31 (NVIDIA Profile Inspector download on NVIDIA systems)

---

## 📜 Disclaimer

Win Light Optimizer is provided as-is with no warranty of any kind. By using this tool you confirm that you understand and accept every security tradeoff described above, you are running this on a machine you own, and you take full responsibility for any consequences.

**This project is not affiliated with or endorsed by Microsoft.**

---
