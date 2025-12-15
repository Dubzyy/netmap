from django.contrib import admin
from .models import Device, Link

@admin.register(Device)
class DeviceAdmin(admin.ModelAdmin):
    list_display = ('name', 'device_type', 'ip_address', 'prometheus_instance')
    list_filter = ('device_type',)
    search_fields = ('name', 'ip_address')

@admin.register(Link)
class LinkAdmin(admin.ModelAdmin):
    list_display = ('source_device', 'source_interface', 'target_device', 'target_interface', 'bandwidth_capacity')
    list_filter = ('source_device', 'target_device')
    search_fields = ('source_interface', 'target_interface')
