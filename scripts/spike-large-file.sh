#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES="$ROOT/fixtures"
FILE="$FIXTURES/large-sample.log"
MEGABYTES="${1:-100}"

mkdir -p "$FIXTURES"

echo "==> Generating ${MEGABYTES}MB sample log at $FILE"

python3 - "$FILE" "$MEGABYTES" <<'PY'
import random
import sys
from datetime import datetime, timedelta

path = sys.argv[1]
mb = int(sys.argv[2])
target = mb * 1024 * 1024
levels = ["INFO", "WARN", "ERROR", "DEBUG"]
hosts = [f"server-{i:03d}" for i in range(1, 50)]
start = datetime(2026, 1, 1)

with open(path, "w", encoding="utf-8") as f:
    written = 0
    i = 0
    while written < target:
        ts = (start + timedelta(seconds=i)).isoformat()
        level = random.choices(levels, weights=[70, 10, 5, 15])[0]
        host = random.choice(hosts)
        line = f"{ts} {level} server={host} message=request_id={i:08d} status={'ok' if level != 'ERROR' else 'timeout'}\n"
        f.write(line)
        written += len(line.encode("utf-8"))
        i += 1
PY

echo "==> Running Phase 0 benchmark (100MB load + regex find)"
cd "$ROOT/LexPad"
swift run -c release LexPadBenchmark "${MEGABYTES}"

echo "==> Spike complete"
