import os
import sys

# Ajouter le chemin de l'application
sys.path.insert(0, os.path.dirname(__file__))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')

# Initialisation Django UNIQUE au demarrage (Performance)
import django
django.setup()

from django.core.wsgi import get_wsgi_application
django_app = get_wsgi_application()

# Point d'entree Passenger
def application(environ, start_response):
    return django_app(environ, start_response)
