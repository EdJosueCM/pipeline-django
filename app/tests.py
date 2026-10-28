from django.test import TestCase
from django.urls import reverse

from .models import Tarea


class TareaModelTests(TestCase):
    def test_str_devuelve_titulo(self):
        tarea = Tarea.objects.create(titulo="Configurar CI")
        self.assertEqual(str(tarea), "Configurar CI")

    def test_tarea_nueva_no_esta_completada(self):
        tarea = Tarea.objects.create(titulo="Crear Dockerfile")
        self.assertFalse(tarea.completada)


class TareaViewTests(TestCase):
    def test_lista_muestra_tareas(self):
        Tarea.objects.create(titulo="Escribir docker-compose")
        respuesta = self.client.get(reverse("lista_tareas"))
        self.assertEqual(respuesta.status_code, 200)
        self.assertContains(respuesta, "Escribir docker-compose")

    def test_crear_tarea_por_post(self):
        respuesta = self.client.post(reverse("lista_tareas"), {"titulo": "Simular despliegue"})
        self.assertRedirects(respuesta, reverse("lista_tareas"))
        self.assertTrue(Tarea.objects.filter(titulo="Simular despliegue").exists())

    def test_titulo_vacio_no_crea_tarea(self):
        respuesta = self.client.post(reverse("lista_tareas"), {"titulo": ""})
        self.assertEqual(respuesta.status_code, 200)
        self.assertEqual(Tarea.objects.count(), 0)

    def test_alternar_tarea(self):
        tarea = Tarea.objects.create(titulo="Validar pipeline")
        self.client.post(reverse("alternar_tarea", args=[tarea.pk]))
        tarea.refresh_from_db()
        self.assertTrue(tarea.completada)

    def test_eliminar_tarea(self):
        tarea = Tarea.objects.create(titulo="Temporal")
        self.client.post(reverse("eliminar_tarea", args=[tarea.pk]))
        self.assertFalse(Tarea.objects.filter(pk=tarea.pk).exists())

    def test_health(self):
        respuesta = self.client.get(reverse("health"))
        self.assertEqual(respuesta.status_code, 200)
        self.assertEqual(respuesta.json()["status"], "ok")
