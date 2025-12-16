from django.urls import path
from . import views

urlpatterns = [
    path('topology/', views.get_topology, name='get_topology'),
    path('devices/', views.list_devices, name='list_devices'),
    path('devices/create/', views.create_device, name='create_device'),
    path('devices/<int:device_id>/delete/', views.delete_device, name='delete_device'),
    path('links/', views.list_links, name='list_links'),
    path('links/create/', views.create_link, name='create_link'),
    path('links/<int:link_id>/delete/', views.delete_link, name='delete_link'),
    path('device/<int:device_id>/position/', views.update_device_position, name='update_device_position'),
    path('devices/<int:device_id>/update/', views.update_device, name='update_device'),
    path('links/<int:link_id>/update/', views.update_link, name='update_link'),
    path('links/<int:link_id>/', views.get_link, name='get_link'),
]
