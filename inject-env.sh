#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="$SCRIPT_DIR/apps/env"
APPS_DIR="$SCRIPT_DIR/apps"

for tpl_file in "$ENV_DIR"/*.env.tpl; do
    app_name="$(basename "$tpl_file" .env.tpl)"
    app_dir="$APPS_DIR/$app_name"

    if [ -d "$app_dir" ]; then
        echo "Injecting: $app_name"
        TARGET_ENV="d3hl" op inject -f -i "$tpl_file" -o "$app_dir/.env"
    else
        echo "Skip: $app_name (no matching app directory)"
    fi
done

echo "Done."
