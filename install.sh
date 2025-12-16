#!/bin/bash

set -e  # Exit on any error

echo "🗺️  NetMap Installation Script"
echo "================================"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo "❌ Please do not run as root. Run as a regular user with sudo access."
   exit 1
fi

# Get installation directory
INSTALL_DIR=$(pwd)
USER=$(whoami)

echo "📁 Installation directory: $INSTALL_DIR"
echo "👤 Installing for user: $USER"
echo ""

# Update system
echo "📦 Updating system packages..."
sudo apt update

# Install system dependencies
echo "📦 Installing system dependencies..."
sudo apt install -y python3 python3-pip python3-venv postgresql postgresql-contrib nginx git

# Create PostgreSQL database (optional - using SQLite by default)
echo "🗄️  Database setup (using SQLite for now)..."
# Uncomment these lines if you want PostgreSQL:
# sudo -u postgres psql -c "CREATE DATABASE netmap;"
# sudo -u postgres psql -c "CREATE USER netmap WITH PASSWORD 'netmap';"
# sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE netmap TO netmap;"

# Backend setup
echo "🐍 Setting up Python backend..."
cd $INSTALL_DIR/backend

if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Run migrations
echo "🔄 Running database migrations..."
python manage.py migrate

# Create superuser (interactive)
echo "👤 Create Django admin user..."
read -p "Create admin user now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    python manage.py createsuperuser
fi

deactivate

# Update settings with current hostname
echo "⚙️  Updating Django settings..."
CURRENT_IP=$(hostname -I | awk '{print $1}')
echo "Detected IP: $CURRENT_IP"

# Create systemd service
echo "🔧 Creating systemd service..."
sudo tee /etc/systemd/system/netmap.service > /dev/null <<EOF
[Unit]
Description=NetMap Network Topology Visualizer
After=network.target postgresql.service

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$INSTALL_DIR/backend
Environment="PATH=$INSTALL_DIR/backend/venv/bin"
ExecStart=$INSTALL_DIR/backend/venv/bin/python $INSTALL_DIR/backend/manage.py runserver 0.0.0.0:8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
echo "🔄 Enabling and starting NetMap service..."
sudo systemctl daemon-reload
sudo systemctl enable netmap
sudo systemctl start netmap

# Check service status
echo ""
echo "✅ Installation complete!"
echo ""
echo "📊 Service Status:"
sudo systemctl status netmap --no-pager -l

echo ""
echo "🌐 NetMap is now running at:"
echo "   http://$CURRENT_IP:8000"
echo "   http://localhost:8000"
echo ""
echo "📝 Useful commands:"
echo "   sudo systemctl status netmap    - Check service status"
echo "   sudo systemctl restart netmap   - Restart service"
echo "   sudo systemctl stop netmap      - Stop service"
echo "   sudo journalctl -u netmap -f    - View logs"
echo ""
echo "🔐 Django admin available at:"
echo "   http://$CURRENT_IP:8000/admin"
echo ""
echo "📚 Next steps:"
echo "   1. Configure Prometheus URL in backend/netmap/settings.py"
echo "   2. Add your devices via the web interface or Django admin"
echo "   3. Set up your network monitoring (Prometheus + SNMP Exporter)"
echo ""
