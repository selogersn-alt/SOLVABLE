import os
import sys
import traceback

# Forcer le chemin de l'application
sys.path.insert(0, os.path.dirname(__file__))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')

def application(environ, start_response):
    try:
        import django
        django.setup()
        from django.core.wsgi import get_wsgi_application
        django_app = get_wsgi_application()
        return django_app(environ, start_response)
    except Exception:
        # En cas d'erreur de démarrage de Django, on affiche le détail
        error_info = traceback.format_exc()
        start_response('500 Internal Server Error', [('Content-Type', 'text/plain')])
        return [f"ERREUR AU DEMARRAGE DE DJANGO :\n\n{error_info}".encode('utf-8')]
