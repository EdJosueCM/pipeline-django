from django.db import models


class Tarea(models.Model):
    titulo = models.CharField(max_length=200)
    descripcion = models.TextField(blank=True)
    completada = models.BooleanField(default=False)
    creada = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["completada", "-creada"]

    def __str__(self):
        return self.titulo
