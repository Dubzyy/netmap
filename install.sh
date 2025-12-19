#!/bin/bash
# NetMap Installation Script
# Supports: Ubuntu 22.04+, AlmaLinux 9+, CentOS 9+, Rocky Linux 9+

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        echo -e "${RED}Cannot detect OS. /etc/os-release not found.${NC}"
        exit 1
    fi

    case $OS in
        ubuntu|debian)
            PKG_MANAGER="apt"
            PKG_UPDATE="apt update"
            PKG_INSTALL="apt install -y"
            PYTHON_PKG="python3 python3-pip python3-venv"
            ;;
        almalinux|centos|rocky|rhel|fedora)
            PKG_MANAGER="dnf"
            PKG_UPDATE="dnf check-update || true"
            PKG_INSTALL="dnf install -y"
            PYTHON_PKG="python3 python3-pip python3-devel gcc"
            
            # Enable EPEL for additional packages on RHEL-based systems
            if [[ "$OS" == "almalinux" || "$OS" == "centos" || "$OS" == "rocky" ]]; then
                echo -e "${BLUE}Enabling EPEL repository...${NC}"
                dnf install -y epel-release || true
            fi
            ;;
        *)
            echo -e "${RED}Unsupported OS: $OS${NC}"
            echo -e "${YELLOW}Supported: Ubuntu, Debian, AlmaLinux, CentOS, Rocky Linux, RHEL, Fedora${NC}"
            exit 1
            ;;
    esac

    echo -e "${GREEN}Detected OS: $OS $VER${NC}"
    echo -e "${GREEN}Package Manager: $PKG_MANAGER${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Detect OS first
detect_os

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                    ║${NC}"
echo -e "${BLUE}║         NetMap Installation Script v0.3.0          ║${NC}"
echo -e "${BLUE}║    Real-Time Network Topology Visualizer          ║${NC}"
echo -e "${BLUE}║                                                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Get username for installation
read -p "Enter username for NetMap installation (default: netmap): " USERNAME
USERNAME=${USERNAME:-netmap}

# Check if user exists
if ! id "$USERNAME" &>/dev/null; then
    echo -e "${YELLOW}User $USERNAME does not exist. Creating...${NC}"
    useradd -m -s /bin/bash "$USERNAME"
    echo -e "${GREEN}✓ User $USERNAME created${NC}"
else
    echo -e "${GREEN}✓ User $USERNAME exists${NC}"
fi

USER_HOME=$(eval echo ~$USERNAME)

# Check if NetMap directory exists
NETMAP_DIR="$USER_HOME/netmap"
if [ ! -d "$NETMAP_DIR" ]; then
    echo -e "${RED}Error: NetMap directory not found at $NETMAP_DIR${NC}"
    echo -e "${YELLOW}Please clone the repository first:${NC}"
    echo -e "  cd $USER_HOME"
    echo -e "  git clone https://github.com/Dubzyy/netmap.git"
    exit 1
fi

echo -e "${BLUE}Installing system dependencies...${NC}"

# Update package lists
$PKG_UPDATE

# Install required packages
$PKG_INSTALL $PYTHON_PKG git

# Additional packages for RHEL-based systems
if [[ "$PKG_MANAGER" == "dnf" ]]; then
    $PKG_INSTALL openssl-devel libffi-devel
fi

echo -e "${GREEN}✓ System dependencies installed${NC}"

# Setup Python virtual environment
echo -e "${BLUE}Setting up Python virtual environment...${NC}"
cd "$NETMAP_DIR/backend"

# Remove old venv if exists
if [ -d "venv" ]; then
    echo -e "${YELLOW}Removing old virtual environment...${NC}"
    rm -rf venv
fi

# Create new venv
sudo -u $USERNAME python3 -m venv venv
echo -e "${GREEN}✓ Virtual environment created${NC}"

# Install Python dependencies
echo -e "${BLUE}Installing Python dependencies...${NC}"
sudo -u $USERNAME bash -c "source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"
echo -e "${GREEN}✓ Python dependencies installed${NC}"

# Run database migrations
echo -e "${BLUE}Running database migrations...${NC}"
sudo -u $USERNAME bash -c "source venv/bin/activate && python manage.py migrate"
echo -e "${GREEN}✓ Database migrations completed${NC}"

# Check if settings_local.py exists
if [ ! -f "$NETMAP_DIR/backend/netmap/settings_local.py" ]; then
    echo -e "${YELLOW}Warning: settings_local.py not found${NC}"
    echo -e "${YELLOW}Please create it from settings_local.example.py and configure:${NC}"
    echo -e "  - SECRET_KEY"
    echo -e "  - ALLOWED_HOSTS"
    echo -e "  - PROMETHEUS_URL"
    echo ""
    read -p "Press Enter to continue..."
fi

# Handle SELinux for RHEL-based systems
if [[ "$PKG_MANAGER" == "dnf" ]]; then
    if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
        echo -e "${YELLOW}SELinux is enabled. Configuring permissions...${NC}"
        
        # Set SELinux context for systemd service
        semanage fcontext -a -t bin_t "$NETMAP_DIR/backend/venv/bin/daphne" 2>/dev/null || true
        restorecon -v "$NETMAP_DIR/backend/venv/bin/daphne" 2>/dev/null || true
        
        # Allow network connections
        setsebool -P httpd_can_network_connect 1 2>/dev/null || true
        
        echo -e "${GREEN}✓ SELinux permissions configured${NC}"
    fi
fi

# Create systemd service
echo -e "${BLUE}Creating systemd service...${NC}"

cat > /etc/systemd/system/netmap.service << EOF
[Unit]
Description=NetMap Network Topology Visualizer with WebSocket Support
After=network.target

[Service]
Type=simple
User=$USERNAME
Group=$USERNAME
WorkingDirectory=$NETMAP_DIR/backend
Environment="PATH=$NETMAP_DIR/backend/venv/bin"
Environment="DJANGO_SETTINGS_MODULE=netmap.settings"
ExecStart=$NETMAP_DIR/backend/venv/bin/daphne -b 0.0.0.0 -p 8000 netmap.asgi:application
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}✓ Systemd service created${NC}"

# Reload systemd
systemctl daemon-reload

# Enable and start service
echo -e "${BLUE}Starting NetMap service...${NC}"
systemctl enable netmap
systemctl start netmap

# Check service status
sleep 2
if systemctl is-active --quiet netmap; then
    echo -e "${GREEN}✓ NetMap service started successfully${NC}"
else
    echo -e "${RED}✗ NetMap service failed to start${NC}"
    echo -e "${YELLOW}Check logs: sudo journalctl -u netmap -n 50${NC}"
    exit 1
fi

# Configure firewall
if command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
    echo -e "${BLUE}Configuring firewall (firewalld)...${NC}"
    firewall-cmd --permanent --add-port=8000/tcp
    firewall-cmd --reload
    echo -e "${GREEN}✓ Firewall configured (port 8000 opened)${NC}"
elif command -v ufw &> /dev/null && systemctl is-active --quiet ufw; then
    echo -e "${BLUE}Configuring firewall (ufw)...${NC}"
    ufw allow 8000/tcp
    echo -e "${GREEN}✓ Firewall configured (port 8000 opened)${NC}"
else
    echo -e "${YELLOW}No active firewall detected (firewalld/ufw)${NC}"
    echo -e "${YELLOW}Please manually open port 8000 if needed${NC}"
fi

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                    ║${NC}"
echo -e "${GREEN}║     NetMap Installation Complete! 🎉              ║${NC}"
echo -e "${GREEN}║                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Access NetMap at:${NC}"
echo -e "  ${GREEN}http://$SERVER_IP:8000${NC}"
echo ""
echo -e "${BLUE}Service Management:${NC}"
echo -e "  Start:   ${YELLOW}sudo systemctl start netmap${NC}"
echo -e "  Stop:    ${YELLOW}sudo systemctl stop netmap${NC}"
echo -e "  Restart: ${YELLOW}sudo systemctl restart netmap${NC}"
echo -e "  Status:  ${YELLOW}sudo systemctl status netmap${NC}"
echo -e "  Logs:    ${YELLOW}sudo journalctl -u netmap -f${NC}"
echo ""
echo -e "${BLUE}Features Enabled:${NC}"
echo -e "  ✓ Real-time WebSocket updates (<100ms latency)"
echo -e "  ✓ Daphne ASGI server (WebSocket + HTTP)"
echo -e "  ✓ Auto-reconnect on connection loss"
echo -e "  ✓ Professional grid background"
echo -e "  ✓ Custom device icons"
echo -e "  ✓ Live bandwidth monitoring"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo -e "  1. Configure settings_local.py with your Prometheus URL"
echo -e "  2. Set up Nginx reverse proxy with SSL (recommended)"
echo -e "  3. Add your network devices via the web interface"
echo ""
echo -e "${YELLOW}For production deployment with Nginx + SSL:${NC}"
echo -e "  See: https://github.com/Dubzyy/netmap#nginx-reverse-proxy-with-ssl${NC}"
echo ""
echo -e "${YELLOW}Important: Configure WebSocket proxy headers in Nginx!${NC}"
echo -e "  Without these headers, real-time updates won't work.${NC}"
echo ""
