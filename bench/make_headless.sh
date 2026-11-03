#!/bin/bash
# Make a DGX Spark headless the same way spark1/2 are (set Aug 26 2026): boot to multi-user.target and
# disable the desktop/peripheral units they have disabled. Reversible:
#   sudo systemctl set-default graphical.target && sudo systemctl enable gnome-remote-desktop cups cups-browsed \
#     bluetooth avahi-daemon avahi-daemon.socket cups.socket cups.path ModemManager && sudo reboot
# Does NOT reboot; with --now also isolates multi-user.target immediately (kills GDM, keeps SSH/Docker).
set -u
UNITS="gnome-remote-desktop cups cups-browsed cups.socket cups.path bluetooth avahi-daemon avahi-daemon.socket ModemManager"
sudo -n systemctl set-default multi-user.target
sudo -n systemctl disable --now $UNITS 2>&1 | grep -v -E "^Removed|^Synchronizing|^Executing" || true
[ "${1:-}" = --now ] && sudo -n systemctl isolate multi-user.target
echo "$(hostname) default=$(systemctl get-default) gdm=$(systemctl is-active gdm) $(for u in $UNITS; do printf '%s=%s ' $u $(systemctl is-enabled $u 2>/dev/null); done)"
