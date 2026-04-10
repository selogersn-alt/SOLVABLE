import os
import sys
import traceback

def log_debug(msg):
    with open(os.path.join(os.path.dirname(__file__), 'debug_global.log'), 'a') as f:
        f.write(f"--- {msg} ---\n")

log_debug("STEP 1: Global scope start")

try:
    log_debug("STEP 2: Setting up sys.path")
    sys.path.insert(0, os.path.dirname(__file__))
    
    log_debug("STEP 3: Setting up DJANGO_SETTINGS_MODULE")
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')
    
    log_debug("STEP 4: Testing Django import")
    import django
    log_debug(f"STEP 5: Django version {django.get_version()}")
except Exception as e:
    log_debug(f"GLOBAL ERROR: {traceback.format_exc()}")

def application(environ, start_response):
    log_debug("STEP 6: application() called")
    try:
        log_debug("STEP 7: Importing wsgi application")
        from logersenegal.wsgi import application as django_app
        log_debug("STEP 8: Ready to call django_app")
        return django_app(environ, start_response)
    except Exception:
        error_info = traceback.format_exc()
        log_debug(f"APPLICATION ERROR: {error_info}")
        start_response('500 Internal Server Error', [('Content-Type', 'text/html; charset=utf-8')])
        return [f"<h1>Erreur Critique</h1><pre>{error_info}</pre>".encode('utf-8')]
