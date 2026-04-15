from rest_framework import viewsets, permissions, filters
from .models import Property, PropertyImage
from .serializers import PropertySerializer, PropertyImageSerializer

class PropertyViewSet(viewsets.ModelViewSet):
    """
    Guichet API pour visualiser et CREER des annonces.
    """
    queryset = Property.objects.filter(is_published=True).order_by('-is_boosted', '-created_at')
    serializer_class = PropertySerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['title', 'neighborhood', 'description']

    def get_permissions(self):
        if self.action == 'create':
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]

    def perform_create(self, serializer):
        # On définit l'utilisateur connecté comme propriétaire
        serializer.save(owner=self.request.user, is_published=True)

class PropertyImageViewSet(viewsets.ModelViewSet):
    """
    API pour envoyer des images après la création de l'annonce.
    """
    queryset = PropertyImage.objects.all()
    serializer_class = PropertyImageSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save()
