import sys
import os

# Ajout du chemin du projet au PYTHONPATH
sys.path.append(os.getcwd())

# Import de l'application Django standard
from logersenegal.wsgi import application
