import os
import sys
import traceback

# Env: O2switch gaak4328 / loger_app
sys.path.insert(0, os.path.dirname(__file__))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')

def application(environ, start_response):
    try:
        from logersenegal.wsgi import application as django_app
        return django_app(environ, start_response)
    except Exception:
        start_response('500 Internal Server Error', [('Content-Type', 'text/plain')])
        return [traceback.format_exc().encode('utf-8')]
