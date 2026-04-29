import sys
import os

# Ajout du chemin du projet
sys.path.append(os.getcwd())

# TENTATIVE DE RÉPARATION DU DJANGO "TRADUIT"
try:
    import django.template.base
    # Si le dictionnaire des tags existe, on s'assure que 'static' pointe vers ce qu'il faut
    # On va essayer de charger static manuellement si possible
    from django.templatetags.static import do_static
    django.template.base.libraries['django.templatetags.static'] = do_static
except:
    pass

def application(environ, start_response):
    try:
        from logersenegal.wsgi import application as django_app
        return django_app(environ, start_response)
    except Exception as e:
        import traceback
        error_msg = f"ERREUR DJANGO (Diagnostic DigitalH) :\n{str(e)}\n"
        error_msg += f"\nTRACEBACK :\n{traceback.format_exc()}\n"
        start_response('200 OK', [('Content-Type', 'text/plain; charset=utf-8')])
        return [error_msg.encode('utf-8')]
