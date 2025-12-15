from django.db import models

class Device(models.Model):
    """Network device (firewall, switch, router, server, etc.)"""
    DEVICE_TYPES = [
        ('firewall', 'Firewall'),
        ('switch', 'Switch'),
        ('router', 'Router'),
        ('hypervisor', 'Hypervisor'),
        ('server', 'Server'),
    ]
    
    name = models.CharField(max_length=100, unique=True)
    device_type = models.CharField(max_length=20, choices=DEVICE_TYPES)
    ip_address = models.GenericIPAddressField()
    prometheus_instance = models.CharField(max_length=100, help_text="Instance label in Prometheus (e.g., '10.10.1.254')")
    position_x = models.IntegerField(default=0)
    position_y = models.IntegerField(default=0)
    icon = models.CharField(max_length=50, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.name} ({self.device_type})"

    class Meta:
        ordering = ['name']


class Link(models.Model):
    """Network link between two devices"""
    source_device = models.ForeignKey(Device, on_delete=models.CASCADE, related_name='outgoing_links')
    target_device = models.ForeignKey(Device, on_delete=models.CASCADE, related_name='incoming_links')
    source_interface = models.CharField(max_length=50, help_text="e.g., 'ae0', 'ge-0/0/0'")
    target_interface = models.CharField(max_length=50)
    bandwidth_capacity = models.IntegerField(help_text="Capacity in Mbps")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.source_device.name}:{self.source_interface} -> {self.target_device.name}:{self.target_interface}"
    
    class Meta:
        ordering = ['source_device', 'target_device']
        unique_together = ['source_device', 'source_interface', 'target_device', 'target_interface']
