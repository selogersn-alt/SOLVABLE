from django import forms
from .models import RentalFiliation, IncidentReport
from logersn.models import Property

class RentalFiliationForm(forms.ModelForm):
    class Meta:
        model = RentalFiliation
        fields = ['property', 'monthly_rent', 'start_date', 'end_date']
        labels = {
            'property': 'Bien concerné',
            'monthly_rent': 'Loyer mensuel (FCFA)',
            'start_date': 'Date de début du bail',
            'end_date': 'Date de fin (Optionnel)'
        }
        widgets = {
            'property': forms.Select(attrs={'class': 'form-select', 'style': 'background-color: var(--bg-body); color: var(--text-main); border-color: var(--border-color);'}),
            'monthly_rent': forms.NumberInput(attrs={'class': 'form-control', 'style': 'background-color: var(--bg-body); color: var(--text-main); border-color: var(--border-color);'}),
            'start_date': forms.DateInput(attrs={'type': 'date', 'class': 'form-control', 'style': 'background-color: var(--bg-body); color: var(--text-main); border-color: var(--border-color);'}),
            'end_date': forms.DateInput(attrs={'type': 'date', 'class': 'form-control', 'style': 'background-color: var(--bg-body); color: var(--text-main); border-color: var(--border-color);'}),
        }
        
    def __init__(self, *args, landlord=None, **kwargs):
        super().__init__(*args, **kwargs)
        if landlord:
            # Only show properties owned by the current landlord
            self.fields['property'].queryset = Property.objects.filter(owner=landlord)

class IncidentReportForm(forms.ModelForm):
    class Meta:
        model = IncidentReport
        fields = ['rental_filiation', 'incident_type', 'amount_due', 'description']
        labels = {
            'rental_filiation': 'Sélectionnez le Contrat (Locataire)',
            'incident_type': "Type d'incident",
            'amount_due': 'Montant dû (si applicable, en FCFA)',
            'description': 'Description détaillée (preuves, dates, etc.)'
        }
        widgets = {
            'rental_filiation': forms.Select(attrs={'class': 'form-select', 'style': 'background-color: var(--bg-body); color: var(--text-main); border-color: var(--border-color);'}),
            'incident_type': forms.Select(attrs={'class': 'form-select', 'style': 'background-color: var(--bg-body); color: var(--text-main); border-color: var(--border-color);'}),
            'amount_due': forms.NumberInput(attrs={'class': 'form-control', 'style': 'background-color: var(--bg-body); color: var(--text-main); border-color: var(--border-color);'}),
            'description': forms.Textarea(attrs={'class': 'form-control', 'rows': 4, 'placeholder': 'Expliquez la situation en détail...', 'style': 'background-color: var(--bg-body); color: var(--text-main); border-color: var(--border-color);'}),
        }

    def __init__(self, *args, landlord=None, **kwargs):
        super().__init__(*args, **kwargs)
        if landlord:
            # Le bailleur ne peut signaler que les locataires de ses contrats actifs
            self.fields['rental_filiation'].queryset = RentalFiliation.objects.filter(landlord=landlord, status=RentalFiliation.StatusEnum.ACTIVE)

class PaymentHistoryForm(forms.ModelForm):
    class Meta:
        from .models import PaymentHistory
        model = PaymentHistory
        fields = ['rental_filiation', 'month_year', 'status', 'payment_proof', 'notes']
        labels = {
            'rental_filiation': 'Contrat Locatif (Sélectionnez le locataire)',
            'month_year': 'Mois concerné (Ex: 01/10/2026 pour Octobre)',
            'status': 'Statut du paiement',
            'payment_proof': 'Preuve du paiement (Photo ou Reçu PDF)',
            'notes': 'Commentaire additionnel'
        }
        widgets = {
            'rental_filiation': forms.Select(attrs={'class': 'form-select', 'style': 'background-color: var(--bg-body); color: var(--text-main); border-color: var(--border-color);'}),
            'month_year': forms.DateInput(attrs={'type': 'month', 'class': 'form-control', 'style': 'background-color: var(--bg-body); color: var(--text-main); border-color: var(--border-color);'}),
            'status': forms.Select(attrs={'class': 'form-select', 'style': 'background-color: var(--bg-body); color: var(--text-main); border-color: var(--border-color);'}),
            'payment_proof': forms.FileInput(attrs={'class': 'form-control', 'style': 'background-color: var(--bg-body); color: var(--text-main); border-color: var(--border-color);'}),
            'notes': forms.Textarea(attrs={'class': 'form-control', 'rows': 3, 'placeholder': 'Ajouter une note facultative...', 'style': 'background-color: var(--bg-body); color: var(--text-main); border-color: var(--border-color);'}),
        }

    def __init__(self, *args, landlord=None, **kwargs):
        super().__init__(*args, **kwargs)
        if landlord:
            self.fields['rental_filiation'].queryset = RentalFiliation.objects.filter(landlord=landlord, status=RentalFiliation.StatusEnum.ACTIVE)
