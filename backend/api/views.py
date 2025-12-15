from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.conf import settings
from .models import Device, Link
from .serializers import DeviceSerializer, LinkSerializer
from .prometheus_client import PrometheusClient

prom = PrometheusClient(settings.PROMETHEUS_URL)

@api_view(['GET'])
def get_topology(request):
    """Return network topology with real-time metrics"""
    devices = Device.objects.all()
    links = Link.objects.all()
    
    # Build nodes
    nodes = []
    for device in devices:
        nodes.append({
            'id': device.id,
            'label': device.name,
            'type': device.device_type,
            'ip': device.ip_address,
            'position': {'x': device.position_x, 'y': device.position_y}
        })
    
    # Build edges with real-time bandwidth
    edges = []
    for link in links:
        # Get real-time bandwidth from Prometheus
        metrics = prom.get_interface_bandwidth(
            link.source_device.prometheus_instance,
            link.source_interface
        )
        
        # Calculate utilization percentage
        total_bandwidth = metrics['inbound'] + metrics['outbound']
        utilization = (total_bandwidth / (link.bandwidth_capacity * 2)) * 100 if link.bandwidth_capacity > 0 else 0
        
        edges.append({
            'id': link.id,
            'source': link.source_device.id,
            'target': link.target_device.id,
            'source_interface': link.source_interface,
            'target_interface': link.target_interface,
            'bandwidth': {
                'inbound': metrics['inbound'],
                'outbound': metrics['outbound'],
                'capacity': link.bandwidth_capacity,
                'utilization': round(utilization, 1)
            }
        })
    
    return Response({
        'nodes': nodes,
        'edges': edges,
        'timestamp': metrics.get('timestamp') if edges else None
    })

@api_view(['POST'])
def update_device_position(request, device_id):
    """Save device position when dragged"""
    try:
        device = Device.objects.get(id=device_id)
        device.position_x = request.data.get('x', device.position_x)
        device.position_y = request.data.get('y', device.position_y)
        device.save()
        return Response({'status': 'ok'})
    except Device.DoesNotExist:
        return Response({'error': 'Device not found'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['GET'])
def list_devices(request):
    """List all devices"""
    devices = Device.objects.all()
    serializer = DeviceSerializer(devices, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def list_links(request):
    """List all links"""
    links = Link.objects.all()
    serializer = LinkSerializer(links, many=True)
    return Response(serializer.data)
