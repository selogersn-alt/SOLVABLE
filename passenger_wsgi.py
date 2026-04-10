import os
import sys
import traceback

# Chemin absolu du projet
PROJECT_ROOT = os.path.dirname(__file__)
sys.path.insert(0, PROJECT_ROOT)

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')

def application(environ, start_response):
    try:
        import django
        django.setup()
        from django.core.wsgi import get_wsgi_application
        _application = get_wsgi_application()
        return _application(environ, start_response)
    except Exception:
        # Log de l'erreur dans un fichier pour nous
        with open(os.path.join(PROJECT_ROOT, "debug_wsgi.log"), "a") as f:
            f.write("\n--- ERREUR DJANGO ---\n")
            f.write(traceback.format_exc())
        
        # Affichage propre pour le navigateur
        start_response('500 Internal Server Error', [('Content-Type', 'text/plain')])
        return [b"Erreur critique lors du chargement de Django. Consultez debug_wsgi.log."]
