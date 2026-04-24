import os
import django
from django.core.management import call_command

def run_migrations():
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')
    django.setup()
    
    print("--- Démarrage des migrations articles ---")
    try:
        call_command('makemigrations', 'articles')
        call_command('migrate', 'articles')
        print("--- Migrations terminées avec succès ! ---")
    except Exception as e:
        print(f"--- Erreur lors des migrations : {str(e)} ---")

if __name__ == "__main__":
    run_migrations()
