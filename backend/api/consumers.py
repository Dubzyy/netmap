import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from .views import get_topology_data


class TopologyConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for real-time topology updates.
    Handles connections, disconnections, and broadcasts topology changes.
    """
    
    async def connect(self):
        """Handle new WebSocket connections"""
        # Add this connection to the topology group
        self.group_name = 'topology_updates'
        
        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )
        
        await self.accept()
        
        # Send initial topology data
        topology_data = await self.get_topology()
        await self.send(text_data=json.dumps({
            'type': 'topology_update',
            'data': topology_data
        }))

    async def disconnect(self, close_code):
        """Handle WebSocket disconnections"""
        # Remove from topology group
        await self.channel_layer.group_discard(
            self.group_name,
            self.channel_name
        )

    async def receive(self, text_data):
        """Handle incoming WebSocket messages"""
        data = json.loads(text_data)
        
        if data.get('action') == 'refresh':
            topology_data = await self.get_topology()
            await self.send(text_data=json.dumps({
                'type': 'topology_update',
                'data': topology_data
            }))

    async def topology_update(self, event):
        """Send topology update to WebSocket (called by channel layer)"""
        await self.send(text_data=json.dumps({
            'type': 'topology_update',
            'data': event['data']
        }))

    @database_sync_to_async
    def get_topology(self):
        """Fetch topology data from database"""
        return get_topology_data()
