import os
import sys

# Ajouter le chemin de l'application
path = os.path.dirname(__file__)
if path not in sys.path:
    sys.path.insert(0, path)

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')

# Mode debug forcé pour voir l'erreur
try:
    from logersenegal.wsgi import application
except Exception as e:
    import traceback
    def application(environ, start_response):
        status = '500 Internal Server Error'
        output = f"ERREUR DE DEMARRAGE DJANGO :\n\n{str(e)}\n\n{traceback.format_exc()}".encode('utf-8')
        response_headers = [('Content-type', 'text/plain; charset=utf-8'), ('Content-Length', str(len(output)))]
        start_response(status, response_headers)
        return [output]
