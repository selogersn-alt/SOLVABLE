from django.apps import AppConfig


class SolvableConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'solvable'

    def ready(self):
        import solvable.signals
