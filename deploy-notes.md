# Notas de despliegue simulado

Este documento describe cómo se simula el despliegue continuo del proyecto
**pipeline-django** (Django 5.2 + PostgreSQL 16 + Docker).

## Flujo automatizado (GitHub Actions)

El workflow `.github/workflows/ci.yml` tiene tres jobs encadenados:

| Job | Qué hace | Evidencia |
|---|---|---|
| `test` | Levanta PostgreSQL como servicio, instala dependencias, ejecuta `manage.py check` y `manage.py test`. | Log con los 8 tests en `ok`. |
| `build` | `docker build` de la imagen, la exporta con `docker save` y la sube como artefacto `pipeline-django-image`. Etiqueta la imagen como `<usuario>/pipeline-django` y simula el `docker push` a DockerHub (lo hace de verdad si existen los secretos `DOCKERHUB_USERNAME` y `DOCKERHUB_TOKEN`). | Artefacto descargable en la página del run. |
| `deploy-simulado` | Descarga el artefacto en una carpeta temporal **distinta del repositorio**, hace `docker load`, levanta `docker-compose.deploy.yml` y valida `/health/` y `/` con `curl`. | Salida de `docker compose ps` y del `curl` en el log. |

## Despliegue simulado en una carpeta externa (local)

Requisitos: Docker Desktop en ejecución y Git.

### Opción A: desde el repositorio

1. **Descargar el proyecto** en una carpeta externa:
   ```powershell
   git clone https://github.com/<usuario>/pipeline-django.git C:\deploy-simulado
   cd C:\deploy-simulado
   ```
2. **Ejecutarlo con Docker Compose**:
   ```powershell
   docker compose up -d --build
   docker compose ps
   ```
   Se deben ver los servicios `db` y `web` en estado `running (healthy)`.
3. **Validar desde el navegador**: abrir <http://localhost:8000>, crear una tarea,
   marcarla como completada. Verificar también <http://localhost:8000/health/>, que
   debe responder `{"status": "ok", "database": "postgresql"}`.

### Opción B: con la imagen construida por el pipeline

1. **Descargar el artefacto**: en GitHub → *Actions* → run más reciente → sección
   *Artifacts* → `pipeline-django-image`. Descomprimir el zip, por ejemplo en
   `C:\Users\<usuario>\Downloads\pipeline-django-image`.
2. **Ejecutarlo con Docker Compose** (sin construir nada):
   ```powershell
   mkdir C:\deploy-simulado; cd C:\deploy-simulado
   copy C:\Users\<usuario>\Downloads\pipeline-django-image\* .
   docker load -i pipeline-django-image.tar.gz
   docker compose -f docker-compose.deploy.yml up -d
   ```
3. **Validar desde el navegador**: <http://localhost:8000>.

### Script automático

Ambas opciones están automatizadas en `scripts/deploy-simulado.ps1`:

```powershell
# Opción A
.\scripts\deploy-simulado.ps1 -RepoUrl https://github.com/<usuario>/pipeline-django.git
# Opción B
.\scripts\deploy-simulado.ps1 -Artefacto C:\Users\<usuario>\Downloads\pipeline-django-image
```

El script limpia `C:\deploy-simulado`, despliega, espera a que `/health/` responda,
muestra `docker compose ps` y abre el navegador.

## Administración (opcional)

```powershell
docker compose exec web python manage.py createsuperuser
```
Luego entrar a <http://localhost:8000/admin/>.

## Detener y limpiar

```powershell
docker compose down -v          # opción A
docker compose -f docker-compose.deploy.yml down -v   # opción B
```

## Evidencias a adjuntar

- [ ] Captura del run de GitHub Actions con los jobs `test`, `build` y `deploy-simulado` en verde.
- [ ] Captura del log del job `test` mostrando los tests.
- [ ] Captura del artefacto `pipeline-django-image` en la página del run.
- [ ] Captura del log de `deploy-simulado` con `docker compose ps` y la respuesta de `/health/`.
- [ ] Captura de `docker compose ps` en local (carpeta `C:\deploy-simulado`).
- [ ] Captura del navegador en <http://localhost:8000> con tareas creadas.
