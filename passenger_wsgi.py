import os
import sys
import traceback

sys.path.insert(0, os.path.dirname(__file__))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')

try:
    import django
    django.setup()
    from django.core.wsgi import get_wsgi_application
    django_instance = get_wsgi_application()
except Exception:
    django_instance = None

def application(environ, start_response):
    if django_instance is None:
        start_response('500 Internal Server Error', [('Content-Type', 'text/plain')])
        return [b'Django failed to start']
    return django_instance(environ, start_response)
