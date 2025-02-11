#!/bin/bash
set -euxo pipefail

# TODO: Convert this file into a service that pulls from buildernet

ENV_FILE="env.json"
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: env.json not found"
    exit 1
fi

# Find and process all mustache templates in skeleton directory
find buildernet/mkosi.skeleton -type f -name "*.mustache" | while read -r template; do
    rel_path="${template#buildernet/mkosi.skeleton/}"
    output_path="$BUILDROOT/${rel_path%.mustache}"
    mustache "$ENV_FILE" "$template" > "$output_path"
    rm "$BUILDROOT/$rel_path"
done

# Download rbuilder-bidding binary
export rbuilder_version="v0.4.2"
export github_token="$(jq -j ".bidding_service.github_token" env.json)"
export rbuilder_url="https://api.github.com/repos/flashbots/rbuilder-bidding-service/releases/tags/$rbuilder_version"
export headers="Authorization: token $github_token"
export asset_url=$(curl -s -H "$headers" "$rbuilder_url" | jq -j '.assets[] | select(.name == "bidding-service") | .url')
curl -s -H "$headers" -H "Accept: application/octet-stream" -L "$asset_url" -o "$BUILDROOT/usr/bin/bidding-service"
chmod +x "$BUILDROOT/usr/bin/bidding-service"

# Set permissions of templated files
chmod 640 "$BUILDROOT/etc/rbuilder.config"
chmod 600 "$BUILDROOT/etc/rclone.conf"
