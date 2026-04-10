import sys, os

# Setup paths
PROJECT_ROOT = os.path.dirname(__file__)
sys.path.insert(0, PROJECT_ROOT)

# Setup DJANGO
os.environ['DJANGO_SETTINGS_MODULE'] = 'logersenegal.settings'

from django.core.wsgi import get_wsgi_application
application = get_wsgi_application()
