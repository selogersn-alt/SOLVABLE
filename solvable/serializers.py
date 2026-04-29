from rest_framework import serializers
from .models import RentalFiliation, IncidentReport, PaymentHistory

class RentalFiliationSerializer(serializers.ModelSerializer):
    class Meta:
        model = RentalFiliation
        fields = '__all__'

class IncidentReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = IncidentReport
        fields = '__all__'

class PaymentHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentHistory
        fields = '__all__'

from .models import PropertyBooking, PropertyVisitRequest

class PropertyBookingSerializer(serializers.ModelSerializer):
    class Meta:
        model = PropertyBooking
        fields = '__all__'

class PropertyVisitRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = PropertyVisitRequest
        fields = '__all__'

from .models import ProfessionalFraudReport

class ProfessionalFraudReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProfessionalFraudReport
        fields = ['id', 'reported_pro_name', 'reported_pro_phone', 'fraud_description', 'is_critical_alert', 'created_at']
