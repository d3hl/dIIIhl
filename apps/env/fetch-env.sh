#!/usr/bin/env bash
set -euo pipefail

ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
Appps_DIR="$(dirname "$ENV_DIR")"

for tpl_file in "$ENV_DIR"/*.env.tpl; do
    app_name="$(basename "$tpl_file" .env.tpl)"
    app_dir="$Appps_DIR/$app_name"

    if [ -d "$app_dir" ]; then
        echo "Fetching: $app_name"
        TARGET_ENV="d3hl" op inject -f -i "$tpl_file" -o "$app_dir/.env"
    else
        echo "Skip: $app_name (no matching app directory)"
    fi
done

echo "Done."
