from django.urls import path
from . import views

urlpatterns = [
    path('topology/', views.get_topology, name='get_topology'),
    path('devices/', views.list_devices, name='list_devices'),
    path('links/', views.list_links, name='list_links'),
    path('device/<int:device_id>/position/', views.update_device_position, name='update_device_position'),
]
