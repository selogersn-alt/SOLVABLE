import os
import sys
import traceback

def log_debug(msg):
    with open(os.path.join(os.path.dirname(__file__), 'debug_global.log'), 'a') as f:
        f.write(f"--- {msg} ---\n")

def application(environ, start_response):
    log_debug("STEP 6: application() called")
    try:
        log_debug("STEP 7: Importing wsgi application")
        from logersenegal.wsgi import application as django_app
        log_debug("STEP 8: Executing django_app")
        
        # On capture la réponse de Django
        response = django_app(environ, start_response)
        
        # On force l'itération pour attraper les erreurs de template/rendu
        log_debug("STEP 9: Iterating response")
        return [chunk for chunk in response]
        
    except Exception:
        error_info = traceback.format_exc()
        log_debug(f"APPLICATION ERROR: {error_info}")
        start_response('500 Internal Server Error', [('Content-Type', 'text/html; charset=utf-8')])
        return [f"<h1>Erreur lors de l'iteration (Rendu)</h1><pre>{error_info}</pre>".encode('utf-8')]
