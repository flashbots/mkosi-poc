#!/bin/bash

install_service() {
    local svc="$1"
    local type="longrun"
    
    # Parse arguments
    if [ "$1" = "--oneshot" ]; then
        type="oneshot"
        shift
        svc="$1"
    fi
    shift

    # Create service and logger directories in source
    local svcdir="$BUILDROOT/etc/s6-rc/source/$svc"
    local logdir="$BUILDROOT/etc/s6-rc/source/${svc}-log"
    mkdir -p "$svcdir/dependencies.d" "$logdir"

    # Configure main service
    echo "$type" > "$svcdir/type"
    if [ "$type" = "oneshot" ]; then
        install -m755 "services/$svc" "$svcdir/up"
    else
        install -m755 "services/$svc" "$svcdir/run"
    fi
    
    # Add any dependencies
    for dep in "$@"; do
        touch "$svcdir/dependencies.d/$dep"
    done

    # Add health check if exists
    if [ -f "services/$svc.check" ]; then
        echo "notification-fd" > "$svcdir/notification-fd"
        install -m755 "services/$svc.check" "$svcdir/notify"
    fi

    # Configure logger 
    echo "longrun" > "$logdir/type"
    echo "$svc" > "$logdir/consumer-for"
    echo "pipeline-${svc}" > "$logdir/pipeline-name"
    echo "#!/bin/sh
exec s6-log -b n20 s1000000 /var/log/$svc" > "$logdir/run"
    chmod 755 "$logdir/run"
    mkdir -p "$BUILDROOT/var/log/$svc"

    # Connect service to logger
    echo "${svc}-log" > "$svcdir/producer-for"
}