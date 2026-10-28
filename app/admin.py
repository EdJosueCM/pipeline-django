from django.contrib import admin

from .models import Tarea


@admin.register(Tarea)
class TareaAdmin(admin.ModelAdmin):
    list_display = ("titulo", "completada", "creada")
    list_filter = ("completada",)
    search_fields = ("titulo",)
