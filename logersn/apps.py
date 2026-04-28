from django.apps import AppConfig


class LogersnConfig(AppConfig):
    name = 'logersn'

    def ready(self):
        import logersn.signals
