# Tom's Quickshell System Monitor Widgets Panel

A highly optimized, System Monitor Panel of widgets, Clock, Cpu, Memory, Network, Disks, Volume,  zero-process-fork monitoring dashboard built for Linux desktop setups using `quickshell`. This widget cluster reads telemetry data directly from virtual kernel file systems (`/proc` and `/sys`), ensuring extremely low CPU usage and near-zero runtime latency.

![Screenshot](tom-qs-sysmon.png) <!-- Add a nice screenshot here -->

## Widgets

- **Clock:** Time, Date, Uptime, seconds bar, TOOLTIP over time shows timezone, double click the Date to open a Calendar at timeanddate.com..
- **ClockUTC:** Optional UTC clock, Time, Date, uncomment in shell.qml to activate
- **CPU:** CPU Clock, CPU temp, CPU average usage, CPU usage per core vertical bars, TOOLTIP shows CPU model.
- **Mem/Swap:** Memory / Swap, Total, Memory usage graph, Swap usage bar.
- **Network:** Network, Device name, IP address, Upload graph bits/sec with scale max, and Download graph bits/sec with scale max.
- **Disk:** Label for Disk/SSD type/size, mount point, Read bytes/sec graph with scale max, partition used bar, Write bytes/sec graph with scale max, TOOLTIP to show used percent over usage bar, TOOLTIP to show drive model over label drive type/size, TOOLTIP to show the device over the mount point, click the mount point to open a Filemanager to that point.
- **Volume:** Volume setting and display bar, mouse wheel or click, click MUTE button.

Some features will not work correctly when run in a virtualized environment.

## Features

- **Very Efficient Processing:** Replaced all shell process loops (`cat`, `awk`, `grep`) with high-speed virtual `FileView` handles.
- **Hardware Agnostic Thermal Tracking:** Fully parameterized 2-layer lookup to support modern AMD (`k10temp`) and Intel (`coretemp`) sensors.
- **Unified Graph Design:** Smooth, right-to-left scrolling visualizations across all core telemetry frameworks.

## Installation & Deployment

1. Make sure you have `quickshell` package installed on your system.  Either from your repo, or from: https://git.outfoxxed.me/quickshell/quickshell.git  These System Monitor widgets were tested with Quickshell 0.2.1 from the Fedora repo.  Should work on the latest 0.3.0 from the GIT repo.
2. Clone or move these configuration files into your local directory:
   ```bash
   mkdir -p ~/.config/quickshell
   cd ~/.config/quickshell
   git clone https://github.com/tomgonz/tom-quickshell-sysmon  .
   ```
3. Edit configuration variables in the shell.qml file to suit your needs.  netDev, cpuTempSensors..., etc...

4. Run the dashboard using the quickshell command. This will run the shell.qml file by default.
   ```bash
   qs
   ```
5. Setup autostart at login.
   ```bash
   cp quickshell-panel.desktop  ~/.config/autostart/
   ```
## Requirements

1. Files...
   ```bash
   /etc/localtime
   /proc/uptime
   /proc/stat
   /proc/cpuinfo
   /proc/stat
   /proc/diskstats
   /proc/meminfo
   /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
   /sys/class/net/{interfaceName}/statistics/rx_bytes
   /sys/class/net/{interfaceName}/statistics/tx_bytes
   /sys/class/hwmon/hwmon*/*
   /sys/block/{drive}/device/model
   ```
2. Bash commands...
   ```bash
   /usr/bin/df
   /usr/bin/ip
   /usr/bin/sh
   /usr/bin/readlink
   /usr/bin/xdg-open
   ```
## Centralized Configuration Guide

All primary environment configurations are managed right at the top of `shell.qml`. Open `shell.qml` to adjust the variables below to match your hardware layout:

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `globalScale` | `1.00` | Multiplier scale factor. Safely scales all text fonts, layouts, canvas dimensions, and window frames seamlessly. Best usable range from 0.85 to 1.20 scaling. |
| `mywidth` | `220` | Core physical bounding box width of your status bar panel tracker. |
| `netDev` | `"enp9s0"` | Your target hardware network interface title. (Run `ip link` to verify yours). |
| `cpuTempSensorChip` | `"k10temp"` | The primary hardware sensor device handle from /sys/class/hwmon/hwmon*/name. |
| `cpuTempSensorKey` | `"Tctl"` | The specific thermal package matrix profile category from /sys/class/hwmon/hwmon*/temp*_label |
| `aboveWindows` | `"true"` | Set Panel in front or behind all other windows.|

## Modifying Storage Widgets

To swap out, add, or customize your storage monitoring components, look into the second half of `shell.qml`. Each disk panel consists of a structural background widget box. To map a device, modify the 4 specific commented lines:

1. Update the unique container id for each disk widget (`id: diskWidgetX`).
2. Add your custom visual descriptive drive label string (`text: "Drive Model Type"`).
3. Set your true system mount path string to monitor (`mountPoint: "/target"`). This is used for partition space used, and will lookup the device to get IO stats.
4. In some virtualization cases you may need to set the disk device (`mountDev: "nvme0n1p3"`). Start with this blank, only set this if you know you need to.

Ensure any new disk widget `id` is in the masking table structure (`mask: Region { ... }`) to enable correct backdrop window transparency clip-outs and Tooltips work correctly.

## License
GPL-3.0
