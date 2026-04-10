import os
import sys
import traceback

# Env: O2switch gaak4328 / loger_app
sys.path.insert(0, os.path.dirname(__file__))
os.chdir(os.path.dirname(__file__))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')

def application(environ, start_response):
    with open('debug_passenger.log', 'a') as f:
        f.write(f"--- Application started ---\n")
    try:
        with open('debug_passenger.log', 'a') as f: f.write("Importing Django wsgi...\n")
        from logersenegal.wsgi import application as django_app
        
        with open('debug_passenger.log', 'a') as f: f.write("Calling Django application...\n")
        response = django_app(environ, start_response)
        
        with open('debug_passenger.log', 'a') as f: f.write("Iterating response...\n")
        result = list(response)
        
        with open('debug_passenger.log', 'a') as f: f.write(f"Done. Result size: {len(result)}\n")
        return result
    except Exception as e:
        import traceback
        error_info = traceback.format_exc()
        with open('debug_passenger.log', 'a') as f:
            f.write(f"CRITICAL ERROR: {error_info}\n")
        start_response('500 Internal Server Error', [('Content-Type', 'text/html')])
        return [f"<h1>Traceback d'Erreur (Interne)</h1><pre>{error_info}</pre>".encode('utf-8')]
