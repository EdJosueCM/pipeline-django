# pipeline-django

Lista de tareas en Django 5.2 y PostgreSQL 16 con pipeline CI/CD en GitHub Actions y Docker.

## Estructura

```
manage.py
requirements.txt
project/
app/
Dockerfile
docker/entrypoint.sh
docker-compose.yml
docker-compose.deploy.yml
.github/workflows/ci.yml
scripts/deploy-simulado.ps1
deploy-notes.md
```

## Ejecución local

```powershell
python -m venv .venv; .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py migrate
python manage.py test
python manage.py runserver
```

## Docker

```powershell
docker compose up --build
```

Disponible en <http://localhost:8000>.

## Pipeline

| Job | Descripción |
|---|---|
| `test` | Instala dependencias y ejecuta `python manage.py test` |
| `build` | Construye la imagen Docker y la guarda como artefacto |
| `deploy-simulado` | Ejecuta la imagen con Docker Compose y valida el despliegue |

## Despliegue simulado

```powershell
.\scripts\deploy-simulado.ps1 -RepoUrl https://github.com/EdJosueCM/pipeline-django.git
```

Detalles en [deploy-notes.md](deploy-notes.md).
