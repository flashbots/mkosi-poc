#!/bin/bash

install_service() {
    local svc="$1"
    local svcdir="$BUILDROOT/etc/runit/runsvdir/default/$svc"

    mkdir -p "$svcdir/log" "$BUILDROOT/var/log/$svc"

    # Copy service from local services/ folder
    cp "services/$svc" "$svcdir/run"

    # Create basic logger using svlogd
    echo '#!/bin/sh' > "$svcdir/log/run"
    echo 'exec 2>&1' >> "$svcdir/log/run"
    echo "exec svlogd -tt /var/log/$svc" >> "$svcdir/log/run"

    chmod 755 "$svcdir"/{,log/}run
}