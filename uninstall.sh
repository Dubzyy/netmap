#!/bin/bash

echo "🗑️  NetMap Uninstall Script"
echo "============================"
echo ""

read -p "This will remove NetMap service and files. Continue? (y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Stop and disable service
echo "⏹️  Stopping NetMap service..."
sudo systemctl stop netmap 2>/dev/null || true
sudo systemctl disable netmap 2>/dev/null || true

# Remove service file
echo "🗑️  Removing systemd service..."
sudo rm -f /etc/systemd/system/netmap.service
sudo systemctl daemon-reload

# Optional: Remove PostgreSQL database
read -p "Remove PostgreSQL database? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo -u postgres psql -c "DROP DATABASE IF EXISTS netmap;" 2>/dev/null || echo "   (No PostgreSQL database found)"
    sudo -u postgres psql -c "DROP USER IF EXISTS netmap;" 2>/dev/null || echo "   (No PostgreSQL user found)"
fi

# Optional: Remove SQLite database
read -p "Remove SQLite database (backend/db.sqlite3)? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f $(pwd)/backend/db.sqlite3
    echo "   ✅ Removed SQLite database"
fi

# Optional: Remove virtual environment
read -p "Remove Python virtual environment (backend/venv)? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf $(pwd)/backend/venv
    echo "   ✅ Removed virtual environment"
fi

# Optional: Remove settings_local.py
read -p "Remove local settings (backend/netmap/settings_local.py)? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f $(pwd)/backend/netmap/settings_local.py
    echo "   ✅ Removed local settings"
fi

echo ""
echo "✅ NetMap service removed!"
echo ""
echo "Note: Source files in $(pwd) were not deleted."
echo "Run 'rm -rf $(pwd)' to remove all files."
echo ""
