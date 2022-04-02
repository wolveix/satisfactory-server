---
name: Bug report
about: Create a report to help us improve this project!
title: Explain Your Issue
labels: ''
assignees: ''
---

**Describe the Bug**
A clear and concise description of what the bug is.

**Your Runtime Command or Docker Compose File**
Please censor anything sensitive.

**System Specs (please complete the following information):**
If you're on Linux, just paste the following block as a single command, and paste the output here.
```
echo "===== START ISSUE REPORT =====
OS:  $(uname -a)
CPU: $(lscpu | grep 'Model name:' | sed 's/Model name:[[:space:]]*//g')
RAM: $(awk '/MemAvailable/ {printf( "%d\n", $2 / 1024000 )}' /proc/meminfo)GB/$(awk '/MemTotal/ {printf( "%d\n", $2 / 1024000 )}' /proc/meminfo)GB
HDD: $(df -h | awk '$NF=="/"{printf "%dGB/%dGB (%s used)\n", $3,$2,$5}')
===== END ISSUE REPORT ====="
```

Alternatively, you can find the information manually. Here's what we're looking for:
-   OS: [e.g. Ubuntu 18.04 x86_64] (Linux: `uname -a`)
-   CPU: [e.g. AMD Ryzen 5 3600 6-Core Processor] (Linux: `lscpu`)
-   RAM: [e.g. 4GB/16GB] (Linux: `cat /proc/meminfo | grep Mem`)
-   HDD; [e.g. 22GB/251GB (9% used)] (Linux: `df -h`)

**Additional Context**
Add any other context about the problem here.
