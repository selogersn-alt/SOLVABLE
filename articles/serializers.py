from rest_framework import serializers
from .models import BlogPost

class BlogPostSerializer(serializers.ModelSerializer):
    author_name = serializers.ReadOnlyField(source='author.get_full_name')
    
    class Meta:
        model = BlogPost
        fields = ['id', 'title', 'slug', 'content', 'image', 'author_name', 'created_at']
