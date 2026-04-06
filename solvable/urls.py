from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import RentalFiliationViewSet, IncidentReportViewSet, PaymentHistoryViewSet

router = DefaultRouter()
router.register(r'filiations', RentalFiliationViewSet)
router.register(r'incidents', IncidentReportViewSet)
router.register(r'payments', PaymentHistoryViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
