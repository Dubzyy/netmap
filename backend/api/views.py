from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.conf import settings
from .models import Device, Link
from .serializers import DeviceSerializer, LinkSerializer
from .prometheus_client import PrometheusClient

# WebSocket imports
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

prom = PrometheusClient(settings.PROMETHEUS_URL)


def get_topology_data():
    """
    Helper function to extract topology data.
    Used by both HTTP endpoint and WebSocket consumer.
    """
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
            'prometheus_instance': device.prometheus_instance,
            'icon': device.icon,
            'position': {'x': device.position_x, 'y': device.position_y}
        })

    # Build edges with real-time bandwidth
    edges = []
    metrics_timestamp = None
    
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
            metrics_timestamp = metrics.get('timestamp')
        elif link.target_device.is_monitored and link.target_device.prometheus_instance:
            # Query target device (for dummy source nodes like ISP)
            metrics = prom.get_interface_bandwidth(
                link.target_device.prometheus_instance,
                link.target_interface
            )
            total_bandwidth = metrics['inbound'] + metrics['outbound']
            utilization = (total_bandwidth / (link.bandwidth_capacity * 2)) * 100 if link.bandwidth_capacity > 0 else 0
            metrics_timestamp = metrics.get('timestamp')

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

    return {
        'nodes': nodes,
        'edges': edges,
        'timestamp': metrics_timestamp
    }


def broadcast_topology_update():
    """
    Broadcast topology update to all connected WebSocket clients.
    Call this after any device or link changes.
    """
    channel_layer = get_channel_layer()
    if channel_layer:
        try:
            topology_data = get_topology_data()
            async_to_sync(channel_layer.group_send)(
                'topology_updates',
                {
                    'type': 'topology_update',
                    'data': topology_data
                }
            )
        except Exception as e:
            print(f"Error broadcasting topology update: {e}")


@api_view(['GET'])
def get_topology(request):
    """Return network topology with real-time metrics"""
    data = get_topology_data()
    return Response(data)


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


@csrf_exempt
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

        # Handle icon updates
        if 'icon' in request.data:
            device.icon = request.data.get('icon')

        device.save()
        broadcast_topology_update()
        
        serializer = DeviceSerializer(device)
        return Response(serializer.data)
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
        broadcast_topology_update()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
def create_link(request):
    """Create a new link"""
    serializer = LinkSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        broadcast_topology_update()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['DELETE'])
def delete_device(request, device_id):
    """Delete a device"""
    try:
        device = Device.objects.get(id=device_id)
        device.delete()
        broadcast_topology_update()
        return Response({'status': 'deleted'}, status=status.HTTP_204_NO_CONTENT)
    except Device.DoesNotExist:
        return Response({'error': 'Device not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['DELETE'])
def delete_link(request, link_id):
    """Delete a link"""
    try:
        link = Link.objects.get(id=link_id)
        link.delete()
        broadcast_topology_update()
        return Response({'status': 'deleted'}, status=status.HTTP_204_NO_CONTENT)
    except Link.DoesNotExist:
        return Response({'error': 'Link not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['PUT'])
def update_link(request, link_id):
    """Update a link"""
    try:
        link = Link.objects.get(id=link_id)
        link.source_interface = request.data.get('source_interface', link.source_interface)
        link.target_interface = request.data.get('target_interface', link.target_interface)
        link.bandwidth_capacity = request.data.get('bandwidth_capacity', link.bandwidth_capacity)
        link.save()
        broadcast_topology_update()
        
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
