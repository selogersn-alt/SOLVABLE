import os
import sys

# Ajouter le chemin de l'application
path = os.path.dirname(__file__)
if path not in sys.path:
    sys.path.insert(0, path)

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')

# Mode debug forcé pour voir l'erreur avec un code 200 (pour tromper Cloudflare)
try:
    from logersenegal.wsgi import application
except Exception as e:
    import traceback
    def application(environ, start_response):
        status = '200 OK'
        output = f"DEBUG LOGER - ERREUR CRITIQUE DETECTEE :\n\n{str(e)}\n\n{traceback.format_exc()}".encode('utf-8')
        response_headers = [('Content-type', 'text/plain; charset=utf-8'), ('Content-Length', str(len(output)))]
        start_response(status, response_headers)
        return [output]
