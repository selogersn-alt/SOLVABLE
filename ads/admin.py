from django.contrib import admin
from .models import Advertisement, AdsConfig

@admin.register(Advertisement)
class AdvertisementAdmin(admin.ModelAdmin):
    list_display = ('title', 'ad_type', 'location', 'is_active', 'created_at')
    list_filter = ('ad_type', 'location', 'is_active')
    search_fields = ('title', 'script_content')
    list_editable = ('is_active',)
    
    fieldsets = (
        ('Général', {
            'fields': ('title', 'ad_type', 'location', 'is_active')
        }),
        ('Contenu Bannière', {
            'fields': ('image', 'target_url'),
            'description': 'Remplir uniquement si le type est "Bannière Image"'
        }),
        ('Contenu Script', {
            'fields': ('script_content',),
            'description': 'Remplir uniquement si le type est "Code Script"'
        }),
    )

@admin.register(AdsConfig)
class AdsConfigAdmin(admin.ModelAdmin):
    list_display = ('__str__',)
    
    def has_add_permission(self, request):
        # On ne veut qu'un seul objet de configuration
        return not AdsConfig.objects.exists()
