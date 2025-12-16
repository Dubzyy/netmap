FROM python:3.12-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir gunicorn psycopg2-binary

# Copy project
COPY . .

# Collect static files
RUN python manage.py collectstatic --noinput || true

# Create entrypoint script
RUN echo '#!/bin/bash\n\
set -e\n\
echo "Waiting for postgres..."\n\
while ! nc -z db 5432; do\n\
  sleep 0.1\n\
done\n\
echo "PostgreSQL started"\n\
python manage.py migrate --noinput\n\
exec "$@"' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "netmap.wsgi:application"]
