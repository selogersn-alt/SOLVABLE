from django.http import HttpResponse

def debug_view(request):
    return HttpResponse("<h1>Debug Mode: OK</h1><p>Si vous voyez ceci, Django fonctionne. Le probleme est dans la vue Home ou la base de données.</p>")
