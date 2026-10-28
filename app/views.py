from django.db import connection
from django.http import JsonResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.views.decorators.http import require_POST

from .forms import TareaForm
from .models import Tarea


def lista_tareas(request):
    if request.method == "POST":
        form = TareaForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect("lista_tareas")
    else:
        form = TareaForm()
    return render(
        request,
        "app/lista_tareas.html",
        {"tareas": Tarea.objects.all(), "form": form, "motor_bd": connection.vendor},
    )


@require_POST
def alternar_tarea(request, pk):
    tarea = get_object_or_404(Tarea, pk=pk)
    tarea.completada = not tarea.completada
    tarea.save(update_fields=["completada"])
    return redirect("lista_tareas")


@require_POST
def eliminar_tarea(request, pk):
    get_object_or_404(Tarea, pk=pk).delete()
    return redirect("lista_tareas")


def health(request):
    """Endpoint usado por el pipeline para validar el despliegue."""
    with connection.cursor() as cursor:
        cursor.execute("SELECT 1")
    return JsonResponse({"status": "ok", "database": connection.vendor})
