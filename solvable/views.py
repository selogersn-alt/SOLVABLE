from rest_framework import viewsets
from .models import RentalFiliation, IncidentReport, PaymentHistory
from .serializers import RentalFiliationSerializer, IncidentReportSerializer, PaymentHistorySerializer

class RentalFiliationViewSet(viewsets.ModelViewSet):
    queryset = RentalFiliation.objects.all()
    serializer_class = RentalFiliationSerializer

class IncidentReportViewSet(viewsets.ModelViewSet):
    queryset = IncidentReport.objects.all()
    serializer_class = IncidentReportSerializer

class PaymentHistoryViewSet(viewsets.ModelViewSet):
    queryset = PaymentHistory.objects.all()
    serializer_class = PaymentHistorySerializer
