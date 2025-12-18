# NetMap 🗺️

> **⚠️ WORK IN PROGRESS - NOT PRODUCTION READY ⚠️**
> This is an active development project and should not be used in production environments without significant security hardening, testing, and validation.

A real-time network topology visualizer with live bandwidth monitoring powered by Prometheus and SNMP metrics. Built for network engineers and NOC teams to visualize and monitor their infrastructure.

![NetMap Screenshot](docs/images/netmap-screenshot.png)

## 🚀 Features

### Current Capabilities
- ✅ **Real-Time Monitoring** - Live bandwidth metrics from Prometheus/SNMP with 30-second auto-refresh
- ✅ **Interactive Topology** - Drag-and-drop network diagram with persistent node positioning
- ✅ **Modern Glassmorphism UI** - Beautiful gradient header, custom fonts (Inter + JetBrains Mono), and professional design
- ✅ **Custom Device Icons** - Upload and edit PNG/JPG/SVG images with transparent backgrounds
- ✅ **Smart Icon Display** - Text labels positioned below custom icons for optimal readability
- ✅ **Dark Mode Optimized** - Professional dark theme designed for NOC environments
- ✅ **Curved/Straight Lines** - Toggle between curved bezier and straight connection lines
- ✅ **Full CRUD Operations** - Create, read, update, and delete devices and links via web UI
- ✅ **Icon Edit Support** - Change device icons anytime through the edit modal
- ✅ **Dummy Node Support** - Add external/ISP equipment without monitoring requirements
- ✅ **Vibrant Link Colors** - Green for normal traffic, yellow for moderate, red for high utilization
- ✅ **Enhanced Edge Connections** - Links properly connect to node boundaries
- ✅ **Bandwidth Visualization** - Real-time inbound/outbound traffic display on each link
- ✅ **Persistent Viewport** - Zoom and pan state preserved across page reloads
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

## 🔧 Installation

### Quick Install (Automated)
```bash
git clone https://github.com/Dubzyy/netmap.git
cd netmap
./install.sh
```

The install script will:
- Install system dependencies (Python, pip, etc.)
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
```

#### 3. Configuration

Create your local settings file:
```bash
cp backend/netmap/settings_local.example.py backend/netmap/settings_local.py
nano backend/netmap/settings_local.py
```

Update with your configuration:
```python
# Local settings - DO NOT COMMIT THIS FILE

SECRET_KEY = 'your-unique-secret-key-here'
ALLOWED_HOSTS = ['your-server-ip', 'your-domain.com', 'localhost', '127.0.0.1']
PROMETHEUS_URL = 'http://your-prometheus-server:9090'
```

**Note**: The `settings_local.py` file is git-ignored and won't be committed to version control.

#### 4. Run Development Server
```bash
python manage.py runserver 0.0.0.0:8000
```

Visit: `http://your-server:8000`

## 🐳 Production Deployment

### Systemd Service

The systemd service is automatically created by `install.sh`. Manual management:
```bash
sudo systemctl start netmap    # Start service
sudo systemctl stop netmap     # Stop service
sudo systemctl restart netmap  # Restart service
sudo systemctl status netmap   # Check status
sudo journalctl -u netmap -f   # View logs
```

Service file location: `/etc/systemd/system/netmap.service`

### Nginx Reverse Proxy with SSL

Example Nginx configuration with HTTPS:
```nginx
server {
    listen 443 ssl http2;
    server_name netmap.yourdomain.com;

    # SSL certificates (use certbot for Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/netmap.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/netmap.yourdomain.com/privkey.pem;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts for long requests
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

server {
    listen 80;
    server_name netmap.yourdomain.com;
    return 301 https://$host$request_uri;
}
```

Get free SSL certificate:
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d netmap.yourdomain.com
```

## 📊 Prometheus Configuration

NetMap requires Prometheus with SNMP Exporter to collect network metrics.

### Example Prometheus Scrape Config
```yaml
scrape_configs:
  - job_name: 'snmp'
    static_configs:
      - targets:
        - 192.168.1.1     # Your firewall
        - 192.168.1.2     # Your switch
        - 192.168.1.3     # Your router
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
- `ifHCInOctets` - High-capacity inbound octets (64-bit counter)
- `ifHCOutOctets` - High-capacity outbound octets (64-bit counter)
- `ifHighSpeed` - Interface speed in Mbps
- `ifOperStatus` - Operational status (up/down)

Make sure your network devices have SNMP enabled and accessible from your Prometheus server.

## 🎨 Usage Guide

### Adding Devices
1. Click **"➕ Add Device"** in the toolbar
2. Enter device details:
   - **Name**: Display name (e.g., "Core Switch")
   - **Type**: Device category (Firewall, Switch, Router, Hypervisor, Server, ISP)
   - **IP Address**: Management IP address
   - **Prometheus Instance**: Must match your Prometheus target exactly (e.g., "192.168.1.1:161")
   - **Has Prometheus Metrics**: Uncheck for dummy nodes (ISP equipment, external devices)
3. Optionally upload a custom icon (PNG/JPG/SVG)
4. Click **"Create Device"**

**Note**: For dummy nodes (external/ISP equipment), uncheck "Has Prometheus Metrics" - these will appear without bandwidth data.

### Adding Links
1. Click **"🔗 Add Link"** in the toolbar
2. Select source and target devices from dropdowns
3. Enter interface names exactly as they appear in your devices:
   - Juniper: `ae0`, `ge-0/0/0`, `xe-0/0/0`
   - Cisco: `GigabitEthernet0/1`, `TenGigabitEthernet1/0/1`
   - Linux: `eth0`, `bond0`, `ens192`
4. Set bandwidth capacity in Mbps (e.g., `1000` for 1 Gbps, `10000` for 10 Gbps)
5. Click **"Create Link"**

### Editing Devices and Links
1. Click on any device or link to view details in the info panel
2. Click the **"✏️ Edit"** button
3. Modify any fields (except device type cannot change after creation)
4. Click **"Save Changes"**

### Deleting Resources
1. Click on the device or link to select it
2. Click **"🗑️ Delete"** button in the info panel
3. Confirm deletion in the dialog
4. All connected links will be removed if you delete a device

### Viewing Real-Time Metrics

**Link Metrics**: Click any link to see:
- ↓ Inbound bandwidth (Mbps)
- ↑ Outbound bandwidth (Mbps)  
- Total capacity (Mbps)
- Utilization percentage with color coding:
  - 🟢 **Green** (<50%): Normal operation
  - 🟡 **Yellow** (50-80%): Moderate load
  - 🔴 **Red** (>80%): High utilization, potential bottleneck

**Device Info**: Click any device to see:
- Device type and custom icon (if uploaded)
- IP address
- Monitoring status (monitored or dummy)

### UI Controls
- **🔄 Refresh**: Manually refresh topology and metrics
- **➕ Add Device**: Open device creation modal
- **🔗 Add Link**: Open link creation modal
- **🎯 Fit View**: Center and fit all nodes in viewport
- **🔍 Zoom In/Out**: Adjust zoom level
- **📐 Curved/Straight Lines**: Toggle between curved bezier and straight lines
- **🌙/☀️ Dark Mode**: Switch between dark and light themes

### Keyboard & Mouse Controls
- **Drag nodes**: Click and drag to reposition (saves automatically)
- **Mouse wheel**: Zoom in/out
- **Click + Drag canvas**: Pan around the topology
- **Click node/link**: View details in info panel
- **Escape**: Deselect all

### Tips & Best Practices
- Arrange your topology logically (top-to-bottom or left-to-right flow)
- Use custom icons for important devices to make them stand out
- Name interfaces consistently for easier troubleshooting
- Set realistic bandwidth capacities for accurate utilization percentages
- Check link colors regularly - red links may indicate bottlenecks
- Use dummy nodes for ISP connections and external networks

## 🚧 Known Limitations

- **No Authentication** - Currently no user login system (use network-level security or reverse proxy auth)
- **Limited Input Validation** - Form inputs not fully sanitized
- **No Rate Limiting** - API endpoints unprotected from abuse
- **No TLS/SSL Built-in** - HTTP only (must use reverse proxy with SSL for HTTPS)
- **SQLite Default** - Works fine for small deployments, PostgreSQL recommended for production scale
- **No Backup System** - Database backups not automated
- **Single Server** - No clustering, load balancing, or high availability
- **No Historical Data** - Only current metrics displayed, no time-series graphs
- **No Alerting** - No notifications for high utilization or down links

## 📝 Roadmap

### High Priority
- [ ] User authentication and authorization system
- [ ] Comprehensive input validation and sanitization
- [ ] Unit and integration test coverage
- [ ] Enhanced error handling and logging
- [ ] API rate limiting and throttling
- [ ] API documentation (Swagger/OpenAPI)

### Medium Priority
- [ ] Docker containerization with docker-compose
- [ ] Historical bandwidth graphs (time-series visualization)
- [ ] Export topology as PNG/SVG image
- [ ] Bulk device import (CSV/JSON)
- [ ] Alerting system (email/Slack/webhook) for threshold violations
- [ ] Multiple topology views (save different network diagrams)
- [ ] Device grouping and hierarchical views

### Low Priority
- [ ] WebSocket for true real-time updates (eliminate 30s polling)
- [ ] Multi-tenant support for MSPs
- [ ] Custom dashboard widgets
- [ ] Scheduled reports (PDF/email)
- [ ] Mobile app (React Native)
- [ ] Integration with other monitoring tools (LibreNMS, Zabbix)

### Completed ✅
- [x] Modern glassmorphism UI with gradient effects and custom typography
- [x] Custom device icon upload and edit functionality
- [x] Transparent icon backgrounds for clean visualization
- [x] Smart text positioning below custom icons
- [x] Vibrant green links for low/normal traffic visualization
- [x] Dark/light theme toggle with persistence
- [x] Edit functionality for devices and links (including icon updates)
- [x] Curved/straight line toggle
- [x] Viewport persistence across sessions
- [x] Node position saving on drag
- [x] Systemd service for production
- [x] Color-coded link utilization
- [x] One-command installation script
- [x] Dummy node support
- [x] Full REST API with CRUD operations
- [x] Edge connections aligned to node boundaries

## 🤝 Contributing

Contributions are welcome! This project follows standard Git workflow:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes with clear, descriptive commits
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request with a detailed description

**Please ensure your code follows:**
- PEP 8 style guide for Python
- Consistent JavaScript formatting
- Include docstrings for functions
- Update README if adding features
- Test your changes before submitting

## 🐛 Bug Reports

Found a bug? Please [open an issue](https://github.com/Dubzyy/netmap/issues) with:

- **Clear description** of the problem
- **Steps to reproduce** the issue
- **Expected behavior** vs **actual behavior**
- **Screenshots** (if applicable)
- **Environment details**:
  - OS and version
  - Python version
  - Browser and version
  - NetMap version/commit

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

This project is free and open-source. You are free to use, modify, and distribute it as you see fit.

## 👤 Author

**Hunter** - NOC Engineer @ NetActuate  
Network automation enthusiast and homelab operator

- 🌐 Portfolio: [portfolio.vrhost.org](https://portfolio.vrhost.org)
- 💼 GitHub: [@Dubzyy](https://github.com/Dubzyy)
- 🔗 LinkedIn: [Connect with me](https://www.linkedin.com/in/hunter-network-engineer/)

*Building tools to make network operations easier, one commit at a time.*

## 🙏 Acknowledgments

Built with these amazing open-source tools:

- **[Django](https://www.djangoproject.com/)** - High-level Python web framework
- **[Django REST Framework](https://www.django-rest-framework.org/)** - Powerful REST API toolkit
- **[Cytoscape.js](https://js.cytoscape.org/)** - Graph theory visualization library
- **[Prometheus](https://prometheus.io/)** - Monitoring and alerting toolkit
- **[SNMP Exporter](https://github.com/prometheus/snmp_exporter)** - SNMP to Prometheus metrics

Inspired by enterprise monitoring tools like SolarWinds NPM, PRTG Network Monitor, and LibreNMS.

## 🔒 Security Notice

**⚠️ IMPORTANT: DO NOT USE IN PRODUCTION WITHOUT:**

- ✅ Implementing authentication and authorization
- ✅ Adding comprehensive input validation and sanitization
- ✅ Configuring SSL/TLS encryption (via reverse proxy)
- ✅ Setting up proper firewall rules (restrict to management network)
- ✅ Regular security audits and dependency updates
- ✅ Following OWASP security best practices
- ✅ Restricting network access to trusted IPs only
- ✅ Reviewing and securing the Django secret key
- ✅ Disabling DEBUG mode in production

**This project is intended for internal use within trusted networks.** The author assumes no liability for security vulnerabilities, data loss, network outages, or any other issues arising from use of this software.

If you discover a security vulnerability, please email the details privately rather than opening a public issue.

## 📞 Support

Need help? Here's how to get support:

- 📖 **Documentation**: Read this README thoroughly
- 🐛 **Bug Reports**: [Open an issue](https://github.com/Dubzyy/netmap/issues)
- 💡 **Feature Requests**: [Submit an enhancement request](https://github.com/Dubzyy/netmap/issues)
- 💬 **Questions**: Check [existing issues](https://github.com/Dubzyy/netmap/issues) first
- 📧 **Direct Contact**: Available for collaboration or questions

**Response Time**: This is a personal project maintained in spare time. Response times may vary, but all issues are appreciated and will be addressed as time permits.

---

<div align="center">

**Development Status**: 🚧 Active Development  
**Version**: 0.3.0-alpha  
**Stability**: Pre-release (Not Production Ready)  
**Last Updated**: December 18, 2025

Made with ❤️ for the network engineering community

⭐ **Star this repo** if you find it useful!

</div>
