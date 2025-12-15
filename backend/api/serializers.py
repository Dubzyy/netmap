from rest_framework import serializers
from .models import Device, Link

class DeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = '__all__'

class LinkSerializer(serializers.ModelSerializer):
    source_device_name = serializers.CharField(source='source_device.name', read_only=True)
    target_device_name = serializers.CharField(source='target_device.name', read_only=True)
    
    class Meta:
        model = Link
        fields = '__all__'
