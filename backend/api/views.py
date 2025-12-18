from django.views.decorators.csrf import csrf_exempt
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
            'is_monitored': device.is_monitored,
            'icon': device.icon,
            'position': {'x': device.position_x, 'y': device.position_y}
        })

    # Build edges with real-time bandwidth
    edges = []
    for link in links:
        # Get metrics from whichever device is monitored
        metrics = {'inbound': 0, 'outbound': 0, 'timestamp': None}
        utilization = 0
        
        if link.source_device.is_monitored and link.source_device.prometheus_instance:
            # Query source device
            metrics = prom.get_interface_bandwidth(
                link.source_device.prometheus_instance,
                link.source_interface
            )
            total_bandwidth = metrics['inbound'] + metrics['outbound']
            utilization = (total_bandwidth / (link.bandwidth_capacity * 2)) * 100 if link.bandwidth_capacity > 0 else 0
        elif link.target_device.is_monitored and link.target_device.prometheus_instance:
            # Query target device (for dummy source nodes like ISP)
            metrics = prom.get_interface_bandwidth(
                link.target_device.prometheus_instance,
                link.target_interface
            )
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

@csrf_exempt
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

@api_view(['POST'])
def create_device(request):
    """Create a new device"""
    serializer = DeviceSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def create_link(request):
    """Create a new link"""
    serializer = LinkSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def delete_device(request, device_id):
    """Delete a device"""
    try:
        device = Device.objects.get(id=device_id)
        device.delete()
        return Response({'status': 'deleted'}, status=status.HTTP_204_NO_CONTENT)
    except Device.DoesNotExist:
        return Response({'error': 'Device not found'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['DELETE'])
def delete_link(request, link_id):
    """Delete a link"""
    try:
        link = Link.objects.get(id=link_id)
        link.delete()
        return Response({'status': 'deleted'}, status=status.HTTP_204_NO_CONTENT)
    except Link.DoesNotExist:
        return Response({'error': 'Link not found'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['PUT'])
def update_device(request, device_id):
    """Update a device"""
    try:
        device = Device.objects.get(id=device_id)
        device.name = request.data.get('name', device.name)
        device.device_type = request.data.get('device_type', device.device_type)
        device.ip_address = request.data.get('ip_address', device.ip_address)
        device.prometheus_instance = request.data.get('prometheus_instance', device.prometheus_instance)
        device.is_monitored = request.data.get('is_monitored', device.is_monitored)
        device.save()
        serializer = DeviceSerializer(device)
        return Response(serializer.data)
    except Device.DoesNotExist:
        return Response({'error': 'Device not found'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['PUT'])
def update_link(request, link_id):
    """Update a link"""
    try:
        link = Link.objects.get(id=link_id)
        link.source_interface = request.data.get('source_interface', link.source_interface)
        link.target_interface = request.data.get('target_interface', link.target_interface)
        link.bandwidth_capacity = request.data.get('bandwidth_capacity', link.bandwidth_capacity)
        link.save()
        serializer = LinkSerializer(link)
        return Response(serializer.data)
    except Link.DoesNotExist:
        return Response({'error': 'Link not found'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['GET'])
def get_link(request, link_id):
    """Get a single link"""
    try:
        link = Link.objects.get(id=link_id)
        serializer = LinkSerializer(link)
        return Response(serializer.data)
    except Link.DoesNotExist:
        return Response({'error': 'Link not found'}, status=status.HTTP_404_NOT_FOUND)
