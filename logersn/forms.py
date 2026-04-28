from django import forms
from .models import Property

class MultipleFileInput(forms.FileInput):
    allow_multiple_selected = True

class MultipleFileField(forms.FileField):
    def __init__(self, *args, **kwargs):
        kwargs.setdefault("widget", MultipleFileInput())
        super().__init__(*args, **kwargs)

    def clean(self, data, initial=None):
        single_file_clean = super().clean
        if isinstance(data, (list, tuple)):
            result = [single_file_clean(d, initial) for d in data]
        else:
            result = single_file_clean(data, initial)
        return result

class PropertyForm(forms.ModelForm):
    images = MultipleFileField(
        label="Photos du bien (Sélectionnez une ou plusieurs photos)",
        required=False,
        widget=MultipleFileInput(attrs={'class': 'form-control', 'accept': 'image/*'})
    )
    
    floor_level = forms.IntegerField(required=False, widget=forms.NumberInput(attrs={'class': 'form-control'}))
    
    surface = forms.IntegerField(required=False, widget=forms.NumberInput(attrs={'class': 'form-control', 'placeholder': 'm2'}))
    bedrooms = forms.IntegerField(required=False, widget=forms.NumberInput(attrs={'class': 'form-control'}))
    toilets = forms.IntegerField(required=False, widget=forms.NumberInput(attrs={'class': 'form-control'}))
    total_rooms = forms.IntegerField(required=False, widget=forms.NumberInput(attrs={'class': 'form-control'}))
    salons = forms.IntegerField(required=False, widget=forms.NumberInput(attrs={'class': 'form-control'}))
    kitchens = forms.IntegerField(required=False, widget=forms.NumberInput(attrs={'class': 'form-control'}))
    has_garage = forms.BooleanField(required=False, widget=forms.CheckboxInput(attrs={'class': 'form-check-input'}))
    has_balcony = forms.BooleanField(required=False, widget=forms.CheckboxInput(attrs={'class': 'form-check-input'}))
    has_terrace = forms.BooleanField(required=False, widget=forms.CheckboxInput(attrs={'class': 'form-check-input'}))
    has_courtyard = forms.BooleanField(required=False, widget=forms.CheckboxInput(attrs={'class': 'form-check-input'}))
    has_garden = forms.BooleanField(required=False, widget=forms.CheckboxInput(attrs={'class': 'form-check-input'}))
    
    def clean(self):
        cleaned_data = super().clean()
        
        # NETTOYAGE LASER STRICT ABSOLU : On liste explicitement a-z et 0-9. Le \w est banni car il laissait passer les "sélecteurs de variations" invisibles.
        import re
        safe_chars_regex = r'[^a-zA-Z0-9\s.,;:!?\'"()\-@€$£%+=/\\&*_°ÂÀÄÇÉÈÊËÎÏÔÖÙÛÜâàäçéèêëîïôöùûü\r\n]'
        
        desc = cleaned_data.get('description', '')
        if desc:
            cleaned_data['description'] = re.sub(safe_chars_regex, '', desc)
            
        title = cleaned_data.get('title', '')
        if title:
            cleaned_data['title'] = re.sub(safe_chars_regex, '', title)

        # Remplacer None par 0 pour les champs Integer
        integer_fields = ['surface', 'bedrooms', 'toilets', 'total_rooms', 'floor_level', 'salons', 'kitchens']
        for field in integer_fields:
            if cleaned_data.get(field) is None:
                cleaned_data[field] = 0
                
        return cleaned_data
    
    class Meta:
        model = Property
        fields = [
            'title', 'listing_category', 'property_type', 'document_type', 'city', 'neighborhood', 'price', 
            'promo_price', 'promo_description', 'is_on_promotion',
            'price_per_night', 'surface', 'bedrooms', 'toilets', 'total_rooms', 'floor_level', 'salons', 'kitchens',
            'has_garage', 'has_balcony', 'has_terrace', 'has_courtyard', 'has_garden',
            'description', 'wifi', 'swimming_pool', 'gym', 'air_conditioning',
            'refrigerator', 'washing_machine', 'microwave', 'tv_cable',
            'generator', 'water_tank', 'has_elevator', 'has_security', 'has_concierge',
            'latitude', 'longitude',
            'internal_ref', 'private_contact_info', 'video_url'
        ]
        widgets = {
            'title': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Ex: Superbe appartement F4 vue mer...'}),
            'listing_category': forms.Select(attrs={'class': 'form-select'}),
            'property_type': forms.Select(attrs={'class': 'form-select'}),
            'document_type': forms.Select(attrs={'class': 'form-select'}),
            'city': forms.Select(attrs={'class': 'form-select'}),
            'neighborhood': forms.TextInput(attrs={'class': 'form-control', 'list': 'neighborhood_list', 'placeholder': 'Tapez ou choisissez le quartier...'}),
            'price': forms.NumberInput(attrs={'class': 'form-control', 'placeholder': 'Ex: 350000'}),
            'promo_price': forms.NumberInput(attrs={'class': 'form-control', 'placeholder': 'Ex: 300000'}),
            'promo_description': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Ex: -15% Promo Fin d\'Année'}),
            'is_on_promotion': forms.CheckboxInput(attrs={'class': 'form-check-input'}),

            'price_per_night': forms.NumberInput(attrs={'class': 'form-control', 'placeholder': 'Ex: 45000'}),
            'surface': forms.NumberInput(attrs={'class': 'form-control', 'placeholder': 'm2'}),
            'bedrooms': forms.NumberInput(attrs={'class': 'form-control'}),
            'toilets': forms.NumberInput(attrs={'class': 'form-control'}),
            'total_rooms': forms.NumberInput(attrs={'class': 'form-control'}),
            'floor_level': forms.NumberInput(attrs={'class': 'form-control', 'placeholder': 'Ex: 2'}),
            'has_garage': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'description': forms.Textarea(attrs={'class': 'form-control', 'rows': 5, 'placeholder': 'Décrivez le bien...'}),
            'wifi': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'swimming_pool': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'gym': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'air_conditioning': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'refrigerator': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'washing_machine': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'microwave': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'tv_cable': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'generator': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'water_tank': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'has_elevator': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'has_security': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'has_concierge': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'internal_ref': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Référence interne pour votre agence'}),
            'private_contact_info': forms.Textarea(attrs={'class': 'form-control', 'rows': 2, 'placeholder': 'Contact propriétaire, notes privées (Confidentiel)'}),
            'video_url': forms.URLInput(attrs={'class': 'form-control', 'placeholder': 'Ex: https://www.youtube.com/watch?v=... ou lien TikTok'}),
        }
        labels = {
            'title': 'Titre de l\'annonce',
            'listing_category': 'Nature de l\'annonce',
            'property_type': 'Type de bien',
            'city': 'Ville',
            'neighborhood': 'Quartier',
            'document_type': 'Type de document (Vente uniquement)',
            'price': 'Prix / Loyer mensuel (FCFA)',
            'promo_price': 'Prix Promotionnel (Si applicable)',
            'promo_description': 'Texte de la promotion',
            'is_on_promotion': 'Activer la promotion sur l\'annonce',

            'price_per_night': 'Prix par nuitée (Meublé)',
            'total_rooms': 'Nombre total de pièces',
            'floor_level': 'Niveau d\'étage',
            'has_garage': 'Garage disponible',
            'description': 'Description détaillée',
            'wifi': 'WiFi',
            'swimming_pool': 'Piscine',
            'gym': 'Salle de sport',
            'air_conditioning': 'Climatisation',
            'refrigerator': 'Réfrigérateur',
            'washing_machine': 'Machine à laver',
            'microwave': 'Micro-ondes',
            'tv_cable': 'TV par câble',
            'generator': 'Groupe électrogène',
            'water_tank': 'Réservoir d\'eau',
            'has_elevator': 'Ascenseur',
            'has_security': 'Sécurité 24/7',
            'has_concierge': 'Service de conciergerie',
            'internal_ref': 'REF (Référence interne - Invisible au public)',
            'private_contact_info': 'CONTACT PRIVÉ (Invisible au public & admin)',
            'video_url': 'Lien Vidéo YouTube / TikTok (Optionnel)',
        }
