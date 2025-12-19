#!/bin/bash
# NetMap Uninstallation Script
# Supports: Ubuntu 22.04+, AlmaLinux 9+, CentOS 9+, Rocky Linux 9+

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${RED}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║                                                    ║${NC}"
echo -e "${RED}║         NetMap Uninstallation Script              ║${NC}"
echo -e "${RED}║                                                    ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Get username
read -p "Enter username for NetMap (default: netmap): " USERNAME
USERNAME=${USERNAME:-netmap}

if ! id "$USERNAME" &>/dev/null; then
    echo -e "${RED}User $USERNAME does not exist${NC}"
    exit 1
fi

USER_HOME=$(eval echo ~$USERNAME)
NETMAP_DIR="$USER_HOME/netmap"

# Confirmation
echo -e "${YELLOW}This will remove:${NC}"
echo -e "  - NetMap systemd service"
echo -e "  - Service configuration"
echo ""
echo -e "${YELLOW}Optional removals (you'll be asked):${NC}"
echo -e "  - SQLite database (data will be lost)"
echo -e "  - Python virtual environment"
echo -e "  - settings_local.py configuration"
echo ""
read -p "Continue? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Uninstallation cancelled${NC}"
    exit 0
fi

# Stop and disable service
echo -e "${BLUE}Stopping NetMap service...${NC}"
systemctl stop netmap 2>/dev/null || true
systemctl disable netmap 2>/dev/null || true
echo -e "${GREEN}✓ Service stopped${NC}"

# Remove systemd service file
echo -e "${BLUE}Removing systemd service...${NC}"
rm -f /etc/systemd/system/netmap.service
systemctl daemon-reload
echo -e "${GREEN}✓ Systemd service removed${NC}"

# Remove firewall rules
echo -e "${BLUE}Removing firewall rules...${NC}"
if command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
    firewall-cmd --permanent --remove-port=8000/tcp 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
    echo -e "${GREEN}✓ Firewall rules removed (firewalld)${NC}"
elif command -v ufw &> /dev/null; then
    ufw delete allow 8000/tcp 2>/dev/null || true
    echo -e "${GREEN}✓ Firewall rules removed (ufw)${NC}"
fi

# Optional: Remove database
if [ -f "$NETMAP_DIR/backend/db.sqlite3" ]; then
    echo ""
    read -p "Remove SQLite database? All data will be lost! (y/N): " REMOVE_DB
    if [[ "$REMOVE_DB" =~ ^[Yy]$ ]]; then
        rm -f "$NETMAP_DIR/backend/db.sqlite3"
        echo -e "${GREEN}✓ Database removed${NC}"
    else
        echo -e "${YELLOW}Database kept at: $NETMAP_DIR/backend/db.sqlite3${NC}"
    fi
fi

# Optional: Remove virtual environment
if [ -d "$NETMAP_DIR/backend/venv" ]; then
    echo ""
    read -p "Remove Python virtual environment? (y/N): " REMOVE_VENV
    if [[ "$REMOVE_VENV" =~ ^[Yy]$ ]]; then
        rm -rf "$NETMAP_DIR/backend/venv"
        echo -e "${GREEN}✓ Virtual environment removed${NC}"
    else
        echo -e "${YELLOW}Virtual environment kept${NC}"
    fi
fi

# Optional: Remove settings_local.py
if [ -f "$NETMAP_DIR/backend/netmap/settings_local.py" ]; then
    echo ""
    read -p "Remove settings_local.py configuration? (y/N): " REMOVE_SETTINGS
    if [[ "$REMOVE_SETTINGS" =~ ^[Yy]$ ]]; then
        rm -f "$NETMAP_DIR/backend/netmap/settings_local.py"
        echo -e "${GREEN}✓ Configuration removed${NC}"
    else
        echo -e "${YELLOW}Configuration kept${NC}"
    fi
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                    ║${NC}"
echo -e "${GREEN}║     NetMap Uninstallation Complete                ║${NC}"
echo -e "${GREEN}║                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}To completely remove NetMap:${NC}"
echo -e "  ${YELLOW}rm -rf $NETMAP_DIR${NC}"
echo ""
echo -e "${BLUE}To remove the user account:${NC}"
echo -e "  ${YELLOW}userdel -r $USERNAME${NC}"
echo ""
