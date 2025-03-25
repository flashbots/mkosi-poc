#!/bin/bash
#
# Note env variables: DESTDIR, BUILDROOT, GOCACHE

make_package() {
    local package="$1"
    local version="$2"
    local git_url="$3"
    local provided_binary="$4"
	local artifact_path="$5"

    local dest_path="$DESTDIR/usr/bin/$package"
    mkdir -p "$DESTDIR/usr/bin"

    # If binary path is provided, use it directly
    if [ -n "$provided_binary" ]; then
        echo "Using provided binary for $package"
        cp "$provided_binary" "$dest_path"
        return
    fi

    # Clone the repository
    local build_dir="$BUILDROOT/build/$package"
    git clone --depth 1 --branch "$version" "$git_url" "$build_dir"

    # Build inside mkosi chroot
    mkosi-chroot bash -c "cd '/build/$package' && make build"

    cp "$build_dir/$artifact_path" "$dest_path"
}
