from rest_framework import viewsets, permissions, filters
from .models import Property
from .serializers import PropertySerializer

class PropertyViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Guichet API pour visualiser les annonces.
    Supporte la recherche native.
    """
    queryset = Property.objects.filter(is_published=True).order_by('-is_boosted', '-created_at')
    serializer_class = PropertySerializer
    permission_classes = [permissions.AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ['title', 'neighborhood', 'description']

    def get_queryset(self):
        queryset = super().get_queryset()
        # On peut ajouter des filtres personnalisés ici plus tard
        return queryset
