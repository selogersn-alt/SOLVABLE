from django.shortcuts import render, get_object_or_404
from .models import BlogPost
from logersn.models import Property

def blog_list(request):
    posts = BlogPost.objects.filter(is_published=True).order_by('-created_at')
    return render(request, 'articles/blog_list.html', {
        'posts': posts,
        'seo_title': "Blog Immobilier Sénégal - Conseils & Actualités",
        'seo_description': "Découvrez nos derniers articles sur le marché immobilier au Sénégal : conseils de location, guides pour bailleurs et actualités du secteur."
    })

def blog_detail(request, slug):
    post = get_object_or_404(BlogPost, slug=slug, is_published=True)
    
    # Récupérer quelques annonces liées au type ou à la ville pour le maillage
    related_ads = Property.objects.filter(is_published=True).order_by('-created_at')[:3]
    
    return render(request, 'articles/blog_detail.html', {
        'post': post,
        'related_ads': related_ads,
        'seo_title': post.title,
        'seo_description': post.meta_description or post.content[:160]
    })
