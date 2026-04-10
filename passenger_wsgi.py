import os
import sys
import traceback

# LOG GLOBAL IMMEDIAT
with open(os.path.join(os.path.dirname(__file__), 'debug_global.log'), 'a') as f:
    f.write(f"\n--- PASSENGER START {os.getcwd()} ---\n")

try:
    sys.path.insert(0, os.path.dirname(__file__))
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')
except Exception as e:
    with open(os.path.join(os.path.dirname(__file__), 'debug_global.log'), 'a') as f:
        f.write(f"ERROR IN GLOBAL SCOPE: {str(e)}\n")

def application(environ, start_response):
    log_file = os.path.join(os.path.dirname(__file__), 'debug_error.log')
    try:
        from logersenegal.wsgi import application as django_app
        return django_app(environ, start_response)
    except Exception:
        error_info = traceback.format_exc()
        with open(log_file, 'a') as f:
            f.write("\n--- NEW ERROR IN APPLICATION ---\n")
            f.write(error_info)
        
        start_response('500 Internal Server Error', [('Content-Type', 'text/html; charset=utf-8')])
        return [f"<h1>Erreur Critique Detectee</h1><pre>{error_info}</pre>".encode('utf-8')]
