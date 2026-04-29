import sys
import os

def application(environ, start_response):
    try:
        # Diagnostic du système
        diag = f"PYTHON VERSION: {sys.version}\n"
        diag += f"CWD: {os.getcwd()}\n"
        diag += f"SYS PATH: {sys.path}\n"
        
        # Tentative d'import Django pour voir ce qui bloque
        try:
            import django
            diag += f"DJANGO OK (Version {django.get_version()})\n"
            
            # Tentative de charger l'application réelle
            from logersenegal.wsgi import application as django_app
            return django_app(environ, start_response)
            
        except Exception as e:
            import traceback
            diag += f"\nERREUR DETECTEE :\n{str(e)}\n"
            diag += f"\nTRACEBACK :\n{traceback.format_exc()}\n"

        start_response('200 OK', [('Content-Type', 'text/plain; charset=utf-8')])
        return [diag.encode('utf-8')]
    except Exception as e:
        start_response('200 OK', [('Content-Type', 'text/plain; charset=utf-8')])
        return [f"ERREUR FATALE SYSTEME: {str(e)}".encode('utf-8')]
