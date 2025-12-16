#!/bin/bash

echo "🐳 Starting NetMap Docker Stack..."
docker-compose up -d

echo ""
echo "✅ NetMap is starting up!"
echo ""
echo "Services:"
echo "  📊 NetMap UI:        http://localhost"
echo "  🔍 Prometheus:       http://localhost:9090"
echo "  📡 SNMP Exporter:    http://localhost:9116"
echo ""
echo "View logs: docker-compose logs -f"
echo "Stop:      docker-compose down"
