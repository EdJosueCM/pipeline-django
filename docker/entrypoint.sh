#!/bin/sh
set -e

python - <<'PY'
import os, socket, sys, time

host = os.environ.get("POSTGRES_HOST", "localhost")
port = int(os.environ.get("POSTGRES_PORT", "5432"))
for _ in range(60):
    try:
        socket.create_connection((host, port), timeout=2).close()
        sys.exit(0)
    except OSError:
        time.sleep(1)
sys.exit("PostgreSQL no respondió a tiempo.")
PY

python manage.py migrate --noinput

exec "$@"
