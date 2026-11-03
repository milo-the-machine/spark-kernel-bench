#!/bin/bash
# T0 boot facts for one DGX Spark. Prints a JSON object. Read-only (uses sudo -n only for kern.log).
set -u
j() { python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))'; }
xid=$(sudo -n grep -c 'NVRM: Xid' /var/log/kern.log 2>/dev/null; true); xid=${xid:-0}; xid=$(echo "$xid" | head -1)
xid_boot=$(journalctl -k -b 0 --no-pager 2>/dev/null | grep -c 'NVRM: Xid'; true); xid_boot=$(echo "${xid_boot:-0}" | head -1)
cat <<EOF
{"kind":"facts","host":$(hostname | j),"date":$(date -Is | j),
 "kernel":$(uname -r | j),"uname":$(uname -a | j),"cmdline":$(cat /proc/cmdline | j),
 "page_size":$(getconf PAGESIZE),"boot_id":$(cat /proc/sys/kernel/random/boot_id | j),
 "uptime_s":$(cut -d. -f1 /proc/uptime),
 "dgx_release":$(grep -h DGX_OTA_VERSION /etc/dgx-release 2>/dev/null | tail -1 | j),
 "driver":$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>&1 | j),
 "gpu":$(nvidia-smi --query-gpu=name,pstate,clocks.max.sm,temperature.gpu --format=csv,noheader 2>&1 | j),
 "nvidia_mod":$(modinfo -F version nvidia 2>&1 | j),
 "memtotal_kib":$(awk '/MemTotal/{print $2}' /proc/meminfo),"memavail_kib":$(awk '/MemAvailable/{print $2}' /proc/meminfo),
 "hca":$(for d in rocep1s0f0 roceP2p1s0f0; do echo "$d $(cat /sys/class/infiniband/$d/fw_ver 2>/dev/null) $(cat /sys/class/infiniband/$d/ports/1/state 2>/dev/null) $(cat /sys/class/infiniband/$d/ports/1/rate 2>/dev/null)"; done | j),
 "ethtool":$(ethtool -i enp1s0f0np0 2>/dev/null | grep -E '^(driver|version|firmware)' | tr '\n' ';' | j),
 "xid_kernlog_total":$xid,"xid_this_boot":$xid_boot,
 "boot_time":$(systemd-analyze 2>&1 | head -1 | j),
 "system_state":$(systemctl is-system-running 2>&1 | j),
 "failed_units":$(systemctl --failed --no-legend 2>/dev/null | awk '{print $2}' | tr '\n' ' ' | j),
 "userns_max":$(sysctl -n user.max_user_namespaces),"apparmor_userns":$(sysctl -n kernel.apparmor_restrict_unprivileged_userns 2>/dev/null || echo -1),
 "ksmbd_loaded":$(lsmod | grep -c '^ksmbd')}
EOF
