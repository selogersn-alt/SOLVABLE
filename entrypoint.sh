#!/bin/sh
# exit on error
set -e

echo "Running collectstatic..."
python manage.py collectstatic --no-input

echo "Starting application..."
exec "$@"
