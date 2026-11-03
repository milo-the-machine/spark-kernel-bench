#!/bin/bash
# Repack the installed NVIDIA driver + 6.17-1031 kernel stack so K0 can be restored offline (superseded debs vanish).
set -u
OUT=/home/milo/kbench/rollback-595.84; mkdir -p $OUT/debs; cd $OUT/debs
if ! command -v dpkg-repack >/dev/null; then (cd $OUT && apt-get download dpkg-repack >/dev/null 2>&1 && dpkg-deb -x dpkg-repack_*.deb x); RP="sudo -n env HOME=$OUT PERL5LIB=$OUT/x/usr/share/perl5 perl $OUT/x/usr/bin/dpkg-repack"; else RP="sudo -n env HOME=$OUT dpkg-repack"; fi
dpkg-query -W -f='${Package} ${Status}\n' | awk '/ok installed/{print $1}' | grep -E '^(nvidia-|libnvidia-|xserver-xorg-video-nvidia|linux-(image|headers|modules|modules-nvidia-fs|modules-nvidia-595-open)-(6\.17\.0-1031|nvidia-hwe)|linux-modules-nvidia-595-open-nvidia-hwe|nv-docker|nvidia-container)' > $OUT/pkglist.txt
for p in $(cat $OUT/pkglist.txt); do $RP $p >/dev/null 2>&1 || echo "REPACK_FAIL $p"; done
sudo -n chown -R milo:milo $OUT
dpkg-query -W -f='${Package}=${Version}\n' $(cat $OUT/pkglist.txt) > $OUT/versions.txt
apt-mark showhold > $OUT/holds.txt; cp /etc/default/grub.d/zz-milo-default-6.17.cfg $OUT/ 2>/dev/null
echo "REPACKED $(ls $OUT/debs/*.deb | wc -l)/$(wc -l < $OUT/pkglist.txt) $(du -sh $OUT/debs | cut -f1) on $(hostname)"
