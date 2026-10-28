#!/bin/sh
# Punto de entrada del contenedor: espera a PostgreSQL, aplica migraciones
# y luego ejecuta el comando recibido (por defecto gunicorn, ver CMD).
set -e

if [ "$DB_ENGINE" != "sqlite" ]; then
  echo "Esperando a PostgreSQL en ${POSTGRES_HOST:-localhost}:${POSTGRES_PORT:-5432}..."
  python - <<'EOF'
import os, socket, sys, time

host = os.environ.get("POSTGRES_HOST", "localhost")
port = int(os.environ.get("POSTGRES_PORT", "5432"))
for _ in range(60):
    try:
        socket.create_connection((host, port), timeout=2).close()
        print("PostgreSQL disponible.")
        sys.exit(0)
    except OSError:
        time.sleep(1)
print("PostgreSQL no respondió a tiempo.", file=sys.stderr)
sys.exit(1)
EOF
fi

python manage.py migrate --noinput

exec "$@"
