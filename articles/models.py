from django.db import models
from django.utils.text import slugify
from django.urls import reverse
from users.models import User

class BlogPost(models.Model):
    title = models.CharField(max_length=200, verbose_name="Titre")
    slug = models.SlugField(max_length=200, unique=True, blank=True)
    author = models.ForeignKey(User, on_delete=models.CASCADE, verbose_name="Auteur")
    image = models.ImageField(upload_to='blog/', verbose_name="Image de couverture")
    content = models.TextField(verbose_name="Contenu")
    
    # SEO Fields
    meta_description = models.CharField(max_length=160, blank=True, verbose_name="Meta Description")
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Status
    is_published = models.BooleanField(default=True, verbose_name="Publié")

    class Meta:
        verbose_name = "Article de Blog"
        verbose_name_plural = "Articles de Blog"
        ordering = ['-created_at']

    def __str__(self):
        return self.title

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.title)
        super().save(*args, **kwargs)

    def get_absolute_url(self):
        return reverse('blog_detail', kwargs={'slug': self.slug})
