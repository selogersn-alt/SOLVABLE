import sys
import os

# Ajout du chemin du projet
sys.path.append(os.getcwd())

def application(environ, start_response):
    try:
        # Tentative de chargement de l'application Django réelle
        from logersenegal.wsgi import application as django_app
        return django_app(environ, start_response)
    except Exception as e:
        import traceback
        # Capture de l'erreur pour affichage direct
        error_msg = f"ERREUR FATALE LORS DU CHARGEMENT DE DJANGO :\n{str(e)}\n"
        error_msg += f"\nTRACEBACK COMPLET :\n{traceback.format_exc()}\n"
        
        start_response('200 OK', [('Content-Type', 'text/plain; charset=utf-8')])
        return [error_msg.encode('utf-8')]
