import os
import sys

# Ajouter le chemin de l'application
path = os.path.dirname(__file__)
if path not in sys.path:
    sys.path.insert(0, path)

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')

from logersenegal.wsgi import application
