#!/bin/bash

make_git_package() {
    local package="$1"
    local version="$2"
    local git_url="$3"
    local build_cmd="$4"
    # All remaining arguments are artifact mappings in src:dest format
    
    mkdir -p "$DESTDIR/usr/bin"
    
    # Clone the repository
    local build_dir="$BUILDROOT/build/$package"
    git clone --depth 1 --branch "$version" "$git_url" "$build_dir"

    # Build inside mkosi chroot with custom build command
    mkosi-chroot bash -c "cd '/build/$package' && $build_cmd"
    
    # Process each artifact mapping
    for artifact_map in "${@:5}"; do
        # Split the mapping into source and destination
        local src=$(echo "$artifact_map" | cut -d':' -f1)
        local dest=$(echo "$artifact_map" | cut -d':' -f2)
        
        # Create destination directory if needed
        mkdir -p "$(dirname "$DESTDIR$dest")"
        
        # Copy the artifact
        cp "$build_dir/$src" "$DESTDIR$dest"
    done
}

# Example usage:
# make_git_package "myapp" "v1.0.0" "https://github.com/user/myapp.git" "make build" \
#    "bin/myapp:/usr/bin/myapp" \
#    "config/myapp.conf:/etc/myapp/myapp.conf"
