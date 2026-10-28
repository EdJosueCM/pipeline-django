# pipeline-django

Lista de tareas en **Django 5.2 + PostgreSQL 16** con un pipeline CI/CD completo:
tests en GitHub Actions, build de imagen Docker y despliegue simulado.

## Estructura

```
manage.py
requirements.txt
project/                 # configuración Django (settings, urls, wsgi)
app/                     # app funcional: modelo Tarea, vistas, plantilla, tests
  tests.py               # 8 tests (python manage.py test)
Dockerfile               # python:3.10 + ENTRYPOINT docker/entrypoint.sh
docker/entrypoint.sh     # espera a PostgreSQL, migra y arranca gunicorn
docker-compose.yml       # web + db, construye la imagen (desarrollo/validación)
docker-compose.deploy.yml# web + db usando una imagen ya construida (despliegue)
.github/workflows/ci.yml # test -> build -> deploy-simulado
scripts/deploy-simulado.ps1
deploy-notes.md
```

## Ejecutar en local sin Docker (requiere PostgreSQL)

```powershell
python -m venv .venv; .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py migrate
python manage.py test
python manage.py runserver
```

## Sesión 1 – CI

```powershell
git init -b main
git add .; git commit -m "Proyecto Django base"
git remote add origin https://github.com/<usuario>/pipeline-django.git
git push -u origin main

git checkout -b ci-setup
git push -u origin ci-setup     # dispara GitHub Actions
```

Evidencia: pestaña **Actions** del repositorio → job `CI - Tests`.
Para la captura con fallos, cambiar temporalmente una aserción en `app/tests.py`,
hacer push, capturar y revertir.

## Sesión 2 – Docker

```powershell
docker compose up --build
```

Abrir <http://localhost:8000>. Evidencia: `docker compose ps` + navegador.

## Sesión 3 – Despliegue continuo simulado

El job `build` construye la imagen, la guarda como artefacto `pipeline-django-image`
y simula el push a DockerHub. El job `deploy-simulado` la descarga en otra carpeta,
la ejecuta con Docker Compose y la valida. Pasos locales en [deploy-notes.md](deploy-notes.md).

## Sesión 4 – Validación integral

Un push a `main` o `ci-setup` (o *Run workflow* manual) ejecuta las tres etapas:

1. **CI:** `test`
2. **Build:** `build`
3. **Despliegue simulado:** `deploy-simulado`

Después, `.\scripts\deploy-simulado.ps1` reproduce el despliegue en `C:\deploy-simulado`.
