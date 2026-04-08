from .models import ProfessionalFraudReport

def fraud_alerts_processor(request):
    """Injecte les alertes critiques de fraude dans le bandeau défilant."""
    alerts = ProfessionalFraudReport.objects.filter(is_validated=True, is_critical_alert=True).order_by('-created_at')[:5]
    return {
        'critical_fraud_alerts': alerts
    }
