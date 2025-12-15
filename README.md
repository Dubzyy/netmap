# NetMap 🗺️

> **⚠️ WORK IN PROGRESS - NOT PRODUCTION READY ⚠️**  
> This is an active development project and should not be used in production environments without significant security hardening, testing, and validation.

A real-time network topology visualizer with live bandwidth monitoring powered by Prometheus and SNMP metrics. Built for network engineers and NOC teams to visualize and monitor their infrastructure.

![NetMap Screenshot](https://via.placeholder.com/800x400/0f172a/ffffff?text=NetMap+Network+Topology+Visualizer)

## 🚀 Features

### Current Capabilities
- ✅ **Real-Time Monitoring** - Live bandwidth metrics from Prometheus/SNMP
- ✅ **Interactive Topology** - Drag-and-drop network diagram with persistent positioning
- ✅ **Custom Device Icons** - Upload PNG/JPG/SVG images for devices
- ✅ **Dummy Node Support** - Add external/ISP equipment without monitoring
- ✅ **CRUD Operations** - Add, edit, and delete devices and links via web UI
- ✅ **Bandwidth Visualization** - Real-time inbound/outbound traffic display
- ✅ **Utilization Monitoring** - Color-coded link utilization indicators
- ✅ **Auto-Refresh** - Updates every 30 seconds automatically
- ✅ **Clean Professional UI** - Modern, responsive design

### Tech Stack
- **Backend**: Django 6.0, Django REST Framework
- **Frontend**: Cytoscape.js, Vanilla JavaScript
- **Database**: SQLite (development) / PostgreSQL (planned for production)
- **Monitoring**: Prometheus, SNMP Exporter
- **Deployment**: systemd service

## 📋 Prerequisites

- Ubuntu 24.04 LTS (or similar)
- Python 3.12+
- Prometheus server with SNMP Exporter
- Network devices with SNMP enabled
- sudo/root access for systemd service

## 🔧 Installation

### 1. Clone Repository
```bash
git clone https://github.com/Dubzyy/netmap.git
cd netmap
```

### 2. Backend Setup
```bash
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Create admin user
python manage.py createsuperuser
```

### 3. Configuration

Edit `backend/netmap/settings.py`:
```python
# Update these settings
ALLOWED_HOSTS = ['your-server-ip', 'localhost', '127.0.0.1']
PROMETHEUS_URL = 'http://your-prometheus-server:9090'
```

### 4. Add Devices

Access Django admin at `http://your-server:8000/admin` and add:
- Devices (firewalls, switches, routers, etc.)
- Links (connections between devices)
- Configure Prometheus instance names to match your metrics

### 5. Run Development Server
```bash
python manage.py runserver 0.0.0.0:8000
```

Visit: `http://your-server:8000`

## 🐳 Production Deployment (Coming Soon)

### Systemd Service

Create `/etc/systemd/system/netmap.service`:
```ini
[Unit]
Description=NetMap Network Topology Visualizer
After=network.target

[Service]
Type=simple
User=netmap
WorkingDirectory=/home/netmap/netmap/backend
Environment="PATH=/home/netmap/netmap/backend/venv/bin"
ExecStart=/home/netmap/netmap/backend/venv/bin/python manage.py runserver 0.0.0.0:8000
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable netmap
sudo systemctl start netmap
```

## 📊 Prometheus Configuration

NetMap expects these SNMP metrics to be available:
```yaml
# Example Prometheus scrape config
scrape_configs:
  - job_name: 'snmp'
    static_configs:
      - targets:
        - 10.10.1.254  # Firewall
        - 10.10.100.1  # Switch
        - 10.10.50.1   # Hypervisor 1
        - 10.10.1.1    # Hypervisor 2
    metrics_path: /snmp
    params:
      module: [if_mib]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter:9116
```

## 🎨 Usage

### Adding Devices
1. Click **"Add Device"** button
2. Fill in device details
3. Upload custom icon (optional)
4. Set Prometheus instance name if monitored
5. Uncheck "Has Prometheus Metrics" for dummy nodes

### Adding Links
1. Click **"Add Link"** button
2. Select source and target devices
3. Enter interface names (e.g., ae0, bond0)
4. Set bandwidth capacity in Mbps

### Viewing Metrics
- Click on any link to see bandwidth details
- Click on devices to see information
- Green links = <50% utilization
- Yellow links = 50-80% utilization
- Red links = >80% utilization

## 🚧 Known Limitations

- **No Authentication** - Currently no user login system
- **No Input Validation** - Form inputs not sanitized
- **SQLite Database** - Not suitable for production scale
- **No Rate Limiting** - API endpoints unprotected
- **No TLS/SSL** - HTTP only (use reverse proxy)
- **Limited Error Handling** - Some edge cases not covered
- **No Backup System** - Database backups not automated
- **Single Server** - No high availability or clustering

## 📝 TODO List

### High Priority
- [ ] Implement user authentication and authorization
- [ ] Add comprehensive input validation and sanitization
- [ ] Migrate to PostgreSQL for production
- [ ] Write unit and integration tests
- [ ] Add proper error handling and logging
- [ ] Implement API rate limiting
- [ ] Add CSRF protection enhancements

### Medium Priority
- [ ] Docker containerization
- [ ] Nginx reverse proxy with SSL/TLS
- [ ] API documentation (Swagger/OpenAPI)
- [ ] Historical bandwidth graphs
- [ ] Export topology as PNG/SVG
- [ ] Bulk device import (CSV)
- [ ] Alerting system for high utilization

### Low Priority
- [ ] Multiple topology views
- [ ] Dark/light theme toggle
- [ ] Mobile-responsive improvements
- [ ] Websocket for real-time updates
- [ ] Multi-tenant support
- [ ] Custom dashboard widgets
- [ ] Scheduled reports

## 🤝 Contributing

This is a personal learning project, but contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

## 👤 Author

**Hunter** - NOC Engineer  
- GitHub: [@Dubzyy](https://github.com/Dubzyy)
- Portfolio: [portfolio.vrhost.org](https://portfolio.vrhost.org)

## 🙏 Acknowledgments

- Built with [Django](https://www.djangoproject.com/)
- Visualization powered by [Cytoscape.js](https://js.cytoscape.org/)
- Metrics from [Prometheus](https://prometheus.io/)
- Inspired by professional network monitoring tools

## ⚠️ Security Notice

**DO NOT USE IN PRODUCTION WITHOUT:**
- Implementing authentication and authorization
- Adding input validation and sanitization
- Configuring SSL/TLS encryption
- Setting up proper firewall rules
- Regular security audits and updates
- Following OWASP security best practices

This project is for educational and development purposes. The author assumes no liability for security vulnerabilities or data loss.

---

**Development Status**: Active Development 🚧  
**Last Updated**: December 15, 2025  
**Version**: 0.1.0-alpha
