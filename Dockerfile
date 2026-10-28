FROM python:3.10

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /code

# Dependencias primero para aprovechar la caché de capas de Docker
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY . .

# Normaliza fin de línea (por si el repo se clonó en Windows) y da permisos
RUN sed -i 's/\r$//' docker/entrypoint.sh && chmod +x docker/entrypoint.sh

# Archivos estáticos (admin, etc.) servidos por WhiteNoise
RUN DB_ENGINE=sqlite python manage.py collectstatic --noinput

EXPOSE 8000

ENTRYPOINT ["/code/docker/entrypoint.sh"]
CMD ["gunicorn", "project.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "2"]
