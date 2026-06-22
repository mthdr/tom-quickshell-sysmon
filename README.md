# Tom's Quickshell System Monitor Widgets Panel

A highly optimized, System Monitor Panel of widgets, Clock, Cpu, Memory, Network, Disks, Volume,  zero-process-fork monitoring dashboard built for Linux desktop setups using `quickshell`. This widget cluster reads telemetry data directly from virtual kernel file systems (`/proc` and `/sys`), ensuring extremely low CPU usage and near-zero runtime latency.

![Screenshot](tom-qs-sysmon.png) <!-- Add a nice screenshot here -->

## Widgets

- **Clock:** Time, Date, Uptime, seconds bar, tool tip for UTC time.
- **ClockUTC:** Optional UTC clock, Time, Date, uncomment in shell.qml to activate
- **CPU:** CPU Clock, CPU temp, CPU average usage, CPU usage per core vertical bars, tooltip shows CPU model.
- **Mem/Swap:** Memory / Swap, Total, Memory usage graph, Swap usage bar.
- **Network:** Network, Device name, IP address, Upload graph bits/sec with scale max, and Download graph bits/sec with scale max.
- **Disk:** Label for Disk/SSD type/size, mount point, Read bytes/sec graph with scale max, partition used bar, Write bytes/sec graph with scale max.
- **Volume:** Volume setting and display bar, mouse wheel or click, MUTE button.

## Features

- **Very Efficient Processing:** All shell process loops (`cat`, `awk`, `grep`) with high-speed virtual `FileView` handles.
- **Hardware Agnostic Thermal Tracking:** Fully parameterized 3-layer JSON lookup to support modern AMD (`k10temp`) and Intel (`coretemp`) sensors.
- **Unified Graph Design:** Smooth, right-to-left scrolling visualizations across all core telemetry frameworks.

## Installation & Deployment

1. Make sure you have `quickshell` package installed on your system.  Either from your repo, or from: https://git.outfoxxed.me/quickshell/quickshell.git
2. Clone or move these configuration files into your local directory:
   ```bash
   mkdir -p ~/.config/quickshell
   cd ~/.config/quickshell
   git clone https://github.com/tomgonz/tom-quickshell-sysmon  .
   ```
3. Run the dashboard using the quickshell daemon execution engine:
   ```bash
   qs
   ```
4. Setup autostart at login.
   ```bash
   cp quickshell-panel.desktop  ~/.config/autostart/
   ```
## Requirements

1. /proc files...
   ```bash
   /proc/uptime
   /proc/stat
   /proc/cpuinfo
   /proc/stat
   /proc/diskstats
   /proc/meminfo
   ```
2. /sys files...
   ```bash
   /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
   /sys/class/net/{interfaceName}/statistics/rx_bytes
   /sys/class/net/{interfaceName}/statistics/tx_bytes
   ```
3. Bash commands...
   ```bash
   /usr/bin/sensors
   /usr/bin/df
   /usr/bin/sh
   /usr/bin/ip
   /usr/bin/awk
   /usr/bin/cut
   ```


## Centralized Configuration Guide

All primary environment configurations are managed right at the top of `shell.qml`. Open `shell.qml` to adjust the variables below to match your hardware layout:

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `globalScale` | `1.00` | Multiplier scale factor. Safely scales all text fonts, layouts, canvas dimensions, and window frames seamlessly. |
| `mywidth` | `220` | Core physical bounding box width of your status bar panel tracker. |
| `myheight` | `1440` | Maximum vertical pixel space matching your monitor panel display boundaries. |
| `netDev` | `"enp9s0"` | Your target hardware network interface title. (Run `ip link` to verify yours). |
| `cpuTempSensorChip` | `"k10temp-pci-00c3"` | The primary hardware sensor device handle parsed from `sensors -j`. |
| `cpuTempSensorKey` | `"Tctl"` | The specific thermal package matrix profile category. |
| `cpuTempSensorSubKey` | `"temp1_input"` | The terminal sub-key property used to compute whole integer degree values. |
| `aboveWindows` | `"true"` | Set Panel in front or behind all other windows.|

## Modifying Storage Widgets

To swap out, add, or customize your storage monitoring components, look into the second half of `shell.qml`. Each disk panel consists of a structural background widget box. To map a device, modify the 4 specific commented lines:

1. Update the unique container block instance element title (`id: diskWidgetX`).
2. Add your custom visual descriptive drive label string (`text: "Drive Model Type"`).
3. Set your contextual layout partition path display subtitle (`text: "(/path)"`).
4. Inject your true system mount path string down to the core engine module (`mountPoint: "/target"`). This is used for partition used, and will look the device to get IO stats.
5. In some virtualization cases you may need to set the disk device (`mountDev: "nvme0n1p3"`). Start with this blank, only set this if you know you need to.

Ensure any new widget `id` tags you initialize are registered up into the top compositor window masking table structure (`mask: Region { ... }`) to enable correct backdrop window transparency clip-outs!

## License
GPL-3.0
