# NetMap Docker Deployment

## Quick Start

1. **Install Docker and Docker Compose**
```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install docker.io docker-compose
   sudo usermod -aG docker $USER
   # Log out and back in
```

2. **Configure Environment**
```bash
   cp .env.example .env
   nano .env  # Update passwords and settings
```

3. **Update Network Targets**
   Edit `prometheus.yml` and add your device IPs in the SNMP scrape config.

4. **Start Everything**
```bash
   ./docker-start.sh
```

5. **Access NetMap**
   - NetMap UI: http://localhost
   - Prometheus: http://localhost:9090
   - SNMP Exporter: http://localhost:9116

## Management Commands
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f netmap

# Restart a service
docker-compose restart netmap

# Rebuild after code changes
docker-compose up -d --build

# Enter container shell
docker-compose exec netmap bash

# Run Django management commands
docker-compose exec netmap python manage.py createsuperuser
docker-compose exec netmap python manage.py migrate
```

## Architecture
```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│    Nginx    │ :80
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   NetMap    │ :8000
│   (Django)  │
└──────┬──────┘
       │
       ├──→ ┌──────────────┐
       │    │  PostgreSQL  │ :5432
       │    └──────────────┘
       │
       └──→ ┌──────────────┐
            │  Prometheus  │ :9090
            └───────┬──────┘
                    │
                    └──→ ┌───────────────┐
                         │ SNMP Exporter │ :9116
                         └───────────────┘
```

## Volumes

- `postgres_data` - Database persistence
- `prometheus_data` - Metrics history
- `static_volume` - Static files (CSS/JS)

## Networking

All services are on the `netmap-network` bridge network and can communicate using service names (e.g., `db`, `prometheus`).

## Production Checklist

- [ ] Change `.env` passwords
- [ ] Generate new SECRET_KEY
- [ ] Update ALLOWED_HOSTS
- [ ] Configure SSL/TLS (use Let's Encrypt)
- [ ] Set up backup automation
- [ ] Configure firewall rules
- [ ] Enable Docker logging driver
- [ ] Set resource limits in docker-compose.yml

## Troubleshooting

**Services won't start:**
```bash
docker-compose logs
```

**Database connection errors:**
```bash
docker-compose exec db psql -U netmap -d netmap
```

**Reset everything:**
```bash
docker-compose down -v  # WARNING: Deletes all data
docker-compose up -d --build
```
