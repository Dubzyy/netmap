# NetMap 🗺️

> **⚠️ WORK IN PROGRESS - NOT PRODUCTION READY ⚠️**
> This is an active development project and should not be used in production environments without significant security hardening, testing, and validation.

A real-time network topology visualizer with live bandwidth monitoring powered by Prometheus and SNMP metrics. Built for network engineers and NOC teams to visualize and monitor their infrastructure.

![NetMap Screenshot](https://via.placeholder.com/800x400/0f172a/ffffff?text=NetMap+Network+Topology+Visualizer)

## 🚀 Features

### Current Capabilities
- ✅ **Real-Time Monitoring** - Live bandwidth metrics from Prometheus/SNMP with 30-second auto-refresh
- ✅ **Interactive Topology** - Drag-and-drop network diagram with persistent node positioning
- ✅ **Dark Mode** - Beautiful dark theme with smooth transitions and theme persistence
- ✅ **Curved/Straight Lines** - Toggle between curved bezier and straight connection lines
- ✅ **Full CRUD Operations** - Create, read, update, and delete devices and links via web UI
- ✅ **Custom Device Icons** - Upload PNG/JPG/SVG images for custom device representations
- ✅ **Dummy Node Support** - Add external/ISP equipment without monitoring requirements
- ✅ **Color-Coded Utilization** - Green (<50%), Yellow (50-80%), Red (>80%) link indicators
- ✅ **Bandwidth Visualization** - Real-time inbound/outbound traffic display on each link
- ✅ **Persistent Viewport** - Zoom and pan state preserved across page reloads
- ✅ **Professional UI** - Modern, responsive design with modal forms
- ✅ **Systemd Service** - Production-ready service management
- ✅ **One-Command Install** - Automated installation script for easy deployment

### Tech Stack
- **Backend**: Django 5.0, Django REST Framework
- **Frontend**: Cytoscape.js, Vanilla JavaScript
- **Database**: SQLite (development) / PostgreSQL (production ready)
- **Monitoring**: Prometheus, SNMP Exporter
- **Deployment**: systemd service
- **Network Protocols**: SNMP v2c/v3

## 📋 Prerequisites

- Ubuntu 24.04 LTS (or similar Debian-based distro)
- Python 3.12+
- Prometheus server with SNMP Exporter
- Network devices with SNMP enabled
- sudo/root access for systemd service installation

## 🔧 Quick Installation

### Automated Install (Recommended)
```bash
git clone https://github.com/Dubzyy/netmap.git
cd netmap
./install.sh
```

The install script will:
- Install system dependencies (Python, PostgreSQL, etc.)
- Create Python virtual environment
- Install Python packages
- Run database migrations
- Create systemd service
- Start NetMap automatically

After installation, access NetMap at: `http://your-server-ip:8000`

### Manual Installation

#### 1. Clone Repository
```bash
git clone https://github.com/Dubzyy/netmap.git
cd netmap
```

#### 2. Backend Setup
```bash
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Create admin user (optional - for Django admin)
python manage.py createsuperuser
```

#### 3. Configuration

Edit `backend/netmap/settings.py`:
```python
# Update these settings for your environment
ALLOWED_HOSTS = ['your-server-ip', 'localhost', '127.0.0.1']
PROMETHEUS_URL = 'http://your-prometheus-server:9090'
```

#### 4. Run Development Server
```bash
python manage.py runserver 0.0.0.0:8000
```

Visit: `http://your-server:8000`

## 🐳 Production Deployment

### Systemd Service (Included)

The systemd service is automatically created by `install.sh`. Manual setup:
```bash
sudo systemctl start netmap    # Start service
sudo systemctl stop netmap     # Stop service
sudo systemctl restart netmap  # Restart service
sudo systemctl status netmap   # Check status
sudo journalctl -u netmap -f   # View logs
```

Service file location: `/etc/systemd/system/netmap.service`

### Nginx Reverse Proxy (Recommended)

Example Nginx configuration:
```nginx
server {
    listen 80;
    server_name netmap.yourdomain.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## 📊 Prometheus Configuration

NetMap requires Prometheus with SNMP Exporter to collect network metrics.

### Example Prometheus Scrape Config
```yaml
scrape_configs:
  - job_name: 'snmp'
    static_configs:
      - targets:
        - 10.10.1.254    # Juniper SRX340
        - 10.10.100.1    # Cisco 3750x
        - 10.10.50.1     # R730-KVM-1
        - 10.10.1.1      # R320-KVM-2
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

### SNMP Exporter Configuration
NetMap uses standard IF-MIB metrics:
- `ifHCInOctets` - High-capacity inbound octets (counter)
- `ifHCOutOctets` - High-capacity outbound octets (counter)
- `ifHighSpeed` - Interface speed in Mbps
- `ifOperStatus` - Operational status

## 🎨 Usage Guide

### Adding Devices
1. Click **"➕ Add Device"** in the toolbar
2. Enter device details:
   - **Name**: Display name (e.g., "Juniper SRX340")
   - **Type**: Device category (Firewall, Switch, Router, etc.)
   - **IP Address**: Management IP
   - **Prometheus Instance**: Must match Prometheus target (e.g., "10.10.1.254:161")
   - **Has Prometheus Metrics**: Uncheck for dummy/external nodes
3. Optionally upload a custom icon (PNG/JPG/SVG)
4. Click **"Create Device"**

### Adding Links
1. Click **"🔗 Add Link"** in the toolbar
2. Select source and target devices from dropdowns
3. Enter interface names (e.g., `ae0`, `bond0`, `GigabitEthernet0/1`)
4. Set bandwidth capacity in Mbps (e.g., `1000` for 1 Gbps)
5. Click **"Create Link"**

### Editing Devices and Links
1. Click on any device or link to view details
2. Click the **"✏️ Edit"** button in the info panel
3. Modify any fields
4. Click **"Save Changes"**

### Deleting Resources
1. Click on the device or link
2. Click **"🗑️ Delete"** button
3. Confirm deletion

### Viewing Real-Time Metrics
- **Link Metrics**: Click any link to see:
  - Inbound/Outbound bandwidth (Mbps)
  - Link capacity
  - Utilization percentage
  - Color indicator: 🟢 Green (<50%), 🟡 Yellow (50-80%), 🔴 Red (>80%)

- **Device Info**: Click any device to see:
  - Device type
  - IP address
  - Monitoring status

### UI Controls
- **🔄 Refresh**: Manually refresh topology
- **🎯 Fit View**: Center and fit all nodes on screen
- **🔍 Zoom In/Out**: Adjust zoom level
- **📐 Curved/Straight Lines**: Toggle line style
- **🌙/☀️ Dark Mode**: Switch between themes

### Keyboard Shortcuts
- **Drag nodes**: Reposition devices (positions are saved automatically)
- **Scroll**: Zoom in/out
- **Click + Drag**: Pan the canvas

## 🚧 Known Limitations

- **No Authentication** - Currently no user login system (use network-level security)
- **No Input Validation** - Form inputs not fully sanitized
- **No Rate Limiting** - API endpoints unprotected
- **No TLS/SSL Built-in** - HTTP only (use reverse proxy with SSL)
- **SQLite Default** - Works fine for small deployments, PostgreSQL recommended for production
- **No Backup System** - Database backups not automated
- **Single Server** - No clustering or high availability

## 📝 TODO List

### High Priority
- [ ] Implement user authentication and authorization
- [ ] Add comprehensive input validation and sanitization
- [ ] Write unit and integration tests
- [ ] Add proper error handling and logging
- [ ] Implement API rate limiting
- [ ] API documentation (Swagger/OpenAPI)

### Medium Priority
- [ ] Docker containerization with docker-compose
- [ ] Historical bandwidth graphs (time-series visualization)
- [ ] Export topology as PNG/SVG
- [ ] Bulk device import (CSV/JSON)
- [ ] Alerting system (email/Slack) for high utilization
- [ ] Multi-topology support (save different views)

### Low Priority
- [ ] WebSocket for real-time updates (no refresh needed)
- [ ] Multi-tenant support
- [ ] Custom dashboard widgets
- [ ] Scheduled reports (PDF/email)
- [ ] Mobile app (React Native)

### Completed ✅
- [x] Dark/light theme toggle
- [x] Edit functionality for devices and links
- [x] Curved/straight line toggle
- [x] Viewport persistence
- [x] Node position saving
- [x] Systemd service
- [x] Color-coded link utilization
- [x] One-command installation script

## 🤝 Contributing

Contributions are welcome! This project follows standard Git workflow:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure your code follows:
- PEP 8 style guide for Python
- ESLint standards for JavaScript
- Include descriptive commit messages

## 🐛 Bug Reports

Found a bug? Please open an issue with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if applicable)
- Environment details (OS, Python version, browser)

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

## 👤 Author

**Hunter** - NOC Engineer @ NetActuate  
Network automation enthusiast and homelab operator

- GitHub: [@Dubzyy](https://github.com/Dubzyy)
- Portfolio: [portfolio.vrhost.org](https://portfolio.vrhost.org)
- LinkedIn: [linkedin.com/in/hunter-your-profile](https://linkedin.com/in/hunter-your-profile)

## 🙏 Acknowledgments

- **[Django](https://www.djangoproject.com/)** - High-level Python web framework
- **[Django REST Framework](https://www.django-rest-framework.org/)** - Powerful REST API toolkit
- **[Cytoscape.js](https://js.cytoscape.org/)** - Graph theory visualization library
- **[Prometheus](https://prometheus.io/)** - Monitoring and alerting toolkit
- **[SNMP Exporter](https://github.com/prometheus/snmp_exporter)** - SNMP metrics for Prometheus
- Inspired by enterprise tools like SolarWinds NPM, PRTG, and LibreNMS

## 📸 Screenshots

*Coming Soon - Screenshots of the interface will be added here*

## 🔒 Security Notice

**DO NOT USE IN PRODUCTION WITHOUT:**
- ✅ Implementing authentication and authorization
- ✅ Adding input validation and sanitization  
- ✅ Configuring SSL/TLS encryption (via reverse proxy)
- ✅ Setting up proper firewall rules
- ✅ Regular security audits and updates
- ✅ Following OWASP security best practices
- ✅ Restricting network access to trusted IPs

This project is intended for internal use within trusted networks. The author assumes no liability for security vulnerabilities, data loss, or network issues arising from use of this software.

## 📞 Support

For questions or support:
- Open an issue on GitHub
- Check existing issues for solutions
- Review the code and inline documentation

---

**Development Status**: Active Development 🚧  
**Last Updated**: December 16, 2025  
**Version**: 0.2.0-alpha  
**Stability**: Pre-release (Not Production Ready)
