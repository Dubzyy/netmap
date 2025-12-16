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
sudo systemctl stop netmap
sudo systemctl disable netmap

# Remove service file
echo "🗑️  Removing systemd service..."
sudo rm -f /etc/systemd/system/netmap.service
sudo systemctl daemon-reload

# Optional: Remove PostgreSQL database
read -p "Remove PostgreSQL database? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo -u postgres psql -c "DROP DATABASE IF EXISTS netmap;"
    sudo -u postgres psql -c "DROP USER IF EXISTS netmap;"
fi

echo ""
echo "✅ NetMap service removed!"
echo ""
echo "Note: Source files in $(pwd) were not deleted."
echo "Run 'rm -rf $(pwd)' to remove all files."
echo ""
