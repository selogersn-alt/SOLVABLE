import os
import sys

# Set the path to the project's root directory
sys.path.insert(0, os.path.dirname(__file__))

# Point to the settings file
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')

# Import the application from the core/wsgi.py file
from logersenegal.wsgi import application
