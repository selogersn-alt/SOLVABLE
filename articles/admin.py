from django.contrib import admin
from .models import BlogPost

@admin.register(BlogPost)
class BlogPostAdmin(admin.ModelAdmin):
    list_display = ('title', 'author', 'created_at', 'is_published')
    list_filter = ('is_published', 'created_at', 'author')
    search_fields = ('title', 'content')
    prepopulated_fields = {'slug': ('title',)}
    
    fieldsets = (
        ('Contenu', {
            'fields': ('title', 'slug', 'author', 'image', 'content')
        }),
        ('SEO', {
            'fields': ('meta_description',),
            'description': 'Ces champs aident à améliorer le référencement sur Google.'
        }),
        ('Statut', {
            'fields': ('is_published',)
        }),
    )
