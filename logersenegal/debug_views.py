from django.http import HttpResponse
from solvable.models import IncidentReport
from django.db.models import Sum
from logersn.models import Property

def debug_view(request):
    try:
        log = []
        log.append("STEP 1: Testing stats query")
        total_unpaid = IncidentReport.objects.filter(status=IncidentReport.StatusEnum.IMPACTED, is_validated=True).aggregate(Sum('amount_due'))['amount_due__sum'] or 0
        log.append(f"Stats OK: {total_unpaid}")
        
        log.append("STEP 2: Testing boosted properties query")
        featured = Property.objects.filter(is_boosted=True, is_published=True).count()
        log.append(f"Boosted OK: {featured}")
        
        log.append("STEP 3: Testing regular properties query")
        regular = Property.objects.filter(is_published=True).exclude(is_boosted=True).count()
        log.append(f"Regular OK: {regular}")
        
        return HttpResponse(f"<h1>Debug Mode: OK</h1><p>{'<br>'.join(log)}</p>")
    except Exception as e:
        import traceback
        return HttpResponse(f"<h1>Erreur Requete Complex</h1><pre>{traceback.format_exc()}</pre>")
