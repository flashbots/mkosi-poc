#!/bin/bash
set -euo pipefail

# Remove all logs and cache, but keep directory structure intact
find "$BUILDROOT/var/log" -type f -delete
find "$BUILDROOT/var/cache" -type f -delete

debloat_paths=(
    "/etc/machine-id"
    "/etc/*-"
    "/usr/share/doc"
    "/usr/share/man"
    "/usr/share/info"
    "/usr/share/locale"
    "/usr/share/gcc"
    "/usr/share/gdb"
    "/usr/share/lintian"
    "/usr/share/perl5/debconf"
    "/usr/share/debconf"
    "/usr/share/initramfs-tools"
    "/usr/share/polkit-1"
    "/usr/share/bug"
    "/usr/share/menu"
    "/usr/share/systemd"
    "/usr/share/bash-completion"
    "/usr/share/zsh"
    "/usr/share/mime"
    "/usr/lib/modules"
    "/usr/lib/udev/hwdb.d"
    "/usr/lib/udev/hwdb.bin"
    "/usr/lib/systemd/catalog"
    "/usr/lib/systemd/user"
    "/usr/lib/systemd/user-generators"
    "/usr/lib/systemd/network"
    "/usr/lib/pcrlock.d"
    "/usr/lib/tmpfiles.d"
    "/etc/systemd/network"
    "/etc/credstore"
)

for p in "${debloat_paths[@]}"; do rm -rf "$BUILDROOT$p"; done