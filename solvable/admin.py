from django.contrib import admin
from django.utils import timezone
from .models import RentalFiliation, IncidentReport, PaymentHistory, PropertyApplication

@admin.register(RentalFiliation)
class RentalFiliationAdmin(admin.ModelAdmin):
    list_display = ('landlord', 'tenant', 'property', 'monthly_rent', 'status', 'start_date')
    list_filter = ('status',)
    search_fields = ('landlord__email', 'landlord__phone_number', 'tenant__email', 'tenant__phone_number')
    actions = ['terminate_filiation']

    @admin.action(description="Résilier les contrats sélectionnés")
    def terminate_filiation(self, request, queryset):
        # Mettre à jour le statut en TERMINATED et libérer la propriété si nécessaire
        for filiation in queryset:
            filiation.status = RentalFiliation.StatusEnum.TERMINATED
            filiation.end_date = timezone.now().date()
            filiation.save()
        self.message_user(request, "Contrats résiliés avec succès.")

@admin.register(IncidentReport)
class IncidentReportAdmin(admin.ModelAdmin):
    list_display = ('reporter', 'reported_tenant', 'amount_due', 'status', 'is_contested', 'created_at')
    list_filter = ('status', 'is_contested')
    search_fields = ('reporter__email', 'reported_tenant__email', 'contestation_reason')
    actions = ['mark_as_impacted', 'mark_as_resolved', 'reject_incident_after_dispute']

    @admin.action(description="Définit le litige comme IMPACTED (Pénalise le score NILS)")
    def mark_as_impacted(self, request, queryset):
        for incident in queryset:
            incident.status = IncidentReport.StatusEnum.IMPACTED
            incident.save()

    @admin.action(description="Marquer comme RESOLVED (Fin de médiation)")
    def mark_as_resolved(self, request, queryset):
        for incident in queryset:
            incident.status = IncidentReport.StatusEnum.RESOLVED
            incident.save()

    @admin.action(description="REJETER l'incident (Médiation : preuve du locataire valide)")
    def reject_incident_after_dispute(self, request, queryset):
        for incident in queryset:
            incident.status = IncidentReport.StatusEnum.RESOLVED
            # Logique pour redonner les points NILS si nécessaire (le signal NILS fait le calcul)
            incident.save()
            self.message_user(request, "Incident rejeté, le locataire n'est plus pénalisé.")

@admin.register(PaymentHistory)
class PaymentHistoryAdmin(admin.ModelAdmin):
    list_display = ('rental_filiation', 'month_year', 'status', 'is_contested', 'payment_date')
    list_filter = ('status', 'is_contested')
    search_fields = ('rental_filiation__tenant__email', 'contestation_reason')
    actions = ['mark_as_paid', 'reject_payment_after_dispute']

    @admin.action(description="Marquer comme PAYÉ (Bonus au score NILS)")
    def mark_as_paid(self, request, queryset):
        for payment in queryset:
            payment.status = PaymentHistory.StatusEnum.PAID
            payment.payment_date = timezone.now()
            payment.is_contested = False
            payment.save()

    @admin.action(description="DECLARER IMPAYÉ (Médiation : paiement invalide)")
    def reject_payment_after_dispute(self, request, queryset):
        for payment in queryset:
            payment.status = PaymentHistory.StatusEnum.UNPAID
            payment.is_contested = False
            payment.save()
            self.message_user(request, "Paiement invalidé après médiation.")

    def has_delete_permission(self, request, obj=None):
        # Sécurité financière et intégrité NILS : On ne supprime pas une trace de paiement.
        return False

@admin.register(PropertyApplication)
class PropertyApplicationAdmin(admin.ModelAdmin):
    list_display = ('applicant', 'property', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('applicant__phone_number', 'applicant__email', 'property__title')
