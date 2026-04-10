import os
import sys
from django.core.wsgi import get_wsgi_application

# Ajouter le chemin du projet
sys.path.insert(0, os.path.dirname(__file__))

# Définir les réglages Django
os.environ['DJANGO_SETTINGS_MODULE'] = 'logersenegal.settings'

# Initialiser l'application (Une seule fois au démarrage)
application = get_wsgi_application()
