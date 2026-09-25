#!/bin/bash
set -euo pipefail
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
if ! command -v python3 >/dev/null 2>&1; then
  echo '需要 Python 3：先运行 macOS Setup，或 brew install python。' >&2
  exit 1
fi
exec python3 "$APP_DIR/qbt.py" "$@"
