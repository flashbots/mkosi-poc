#!/bin/bash
set -euxo pipefail

build_dir="$BUILDROOT/build/s6-rc"
mkdir -p "$build_dir"
git clone --depth 1 --branch v0.5.5.0 git://git.skarnet.org/s6-rc "$build_dir"

mkosi-chroot bash -c "
    cd /build/s6-rc

    # Configure with reproducible build flags
    ./configure \
        --prefix=/usr \
        --libdir=/usr/lib \
        --with-sysdeps=/usr/lib/x86_64-linux-gnu/skalibs/sysdeps \
        CC='gcc -static-libgcc' \
        CFLAGS='-O2 -Wall' \
        SOURCE_DATE_EPOCH=0

    make -j1
    make DESTDIR=$DESTDIR install
"