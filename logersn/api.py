from django.db.models import Q
from rest_framework import viewsets, permissions, filters
from .models import Property, PropertyImage, Favorite, NohanMessage
from users.models import User
from .serializers import PropertySerializer, PropertyImageSerializer, ProfessionalSerializer, NohanMessageSerializer
from solvable.models import PropertyBooking, PropertyVisitRequest
from solvable.serializers import PropertyBookingSerializer, PropertyVisitRequestSerializer
from articles.models import BlogPost
from articles.serializers import BlogPostSerializer
from rest_framework.decorators import action
from rest_framework.response import Response

from .constants import PROPERTY_TYPE_CHOICES, CITY_CHOICES

class ProfessionalsViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Répertoire des agences et courtiers vérifiés.
    """
    queryset = User.objects.filter(
        Q(role='AGENCY') | Q(role='BROKER') | Q(role='AGENT')
    ).filter(is_active=True).order_by('-is_verified_pro', 'company_name')
    serializer_class = ProfessionalSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['company_name', 'first_name', 'last_name', 'coverage_area']

class PropertyViewSet(viewsets.ModelViewSet):
    """
    Guichet API pour visualiser et CREER des annonces.
    """
    serializer_class = PropertySerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['title', 'neighborhood', 'description']

    def get_queryset(self):
        queryset = Property.objects.filter(is_published=True).order_by('-is_boosted', '-created_at')
        
        city = self.request.query_params.get('city')
        if city:
            queryset = queryset.filter(city=city)
            
        property_type = self.request.query_params.get('property_type')
        if property_type:
            queryset = queryset.filter(property_type=property_type)

        listing_category = self.request.query_params.get('listing_category')
        if listing_category:
            queryset = queryset.filter(listing_category=listing_category)
            
        neighborhood = self.request.query_params.get('neighborhood')
        if neighborhood:
            queryset = queryset.filter(neighborhood__iexact=neighborhood)
            
        return queryset

    def get_permissions(self):
        if self.action in ['create', 'toggle_favorite', 'my_favorites']:
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]

    def perform_create(self, serializer):
        # On définit l'utilisateur connecté comme propriétaire
        serializer.save(owner=self.request.user, is_published=True)

    @action(detail=True, methods=['post'], url_path='toggle-favorite')
    def toggle_favorite(self, request, pk=None):
        property_obj = self.get_object()
        favorite, created = Favorite.objects.get_or_create(user=request.user, property=property_obj)
        if not created:
            favorite.delete()
            return Response({'status': 'removed'})
        return Response({'status': 'added'})

    @action(detail=False, methods=['get'], url_path='favorites')
    def my_favorites(self, request):
        favorites = Property.objects.filter(favorited_by__user=request.user)
        serializer = self.get_serializer(favorites, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='my-properties')
    def my_properties(self, request):
        properties = Property.objects.filter(owner=request.user).order_by('-created_at')
        serializer = self.get_serializer(properties, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def cities(self, request):
        return Response([{'id': c[0], 'name': c[1]} for c in CITY_CHOICES])

    @action(detail=False, methods=['get'], url_path='types')
    def property_types(self, request):
        return Response([{'id': t[0], 'name': t[1]} for t in PROPERTY_TYPE_CHOICES])

class BookingViewSet(viewsets.ModelViewSet):
    serializer_class = PropertyBookingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # On voit les réservations faites ET reçues
        return PropertyBooking.objects.filter(
            Q(user=self.request.user) | Q(property__owner=self.request.user)
        ).order_by('-created_at')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class VisitViewSet(viewsets.ModelViewSet):
    serializer_class = PropertyVisitRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return PropertyVisitRequest.objects.filter(
            Q(user=self.request.user) | Q(property__owner=self.request.user)
        ).order_by('-created_at')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class NohanViewSet(viewsets.ViewSet):
    """
    API pour discuter avec NOHAN.
    """
    permission_classes = [permissions.AllowAny]

    @action(detail=False, methods=['post'])
    def chat(self, request):
        from .nohan_utils import call_gemini_api
        
        user_message = request.data.get('message', '')
        history = request.data.get('history', [])
        
        if not user_message:
            return Response({'error': 'Message vide'}, status=400)
            
        # 1. Enregistrer le message de l'utilisateur
        NohanMessage.objects.create(
            user=request.user if request.user.is_authenticated else None,
            session_key=request.session.session_key,
            role='user',
            content=user_message
        )

        # 2. Appel à l'IA
        try:
            ai_response = call_gemini_api(user_message, history)
            
            # 3. Enregistrer la réponse de l'IA
            NohanMessage.objects.create(
                user=request.user if request.user.is_authenticated else None,
                session_key=request.session.session_key,
                role='assistant',
                content=ai_response
            )

            return Response({
                'response': ai_response,
                'role': 'model'
            })
        except Exception as e:
            return Response({'error': str(e)}, status=500)

class BlogPostViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API pour lire les guides et articles de blog.
    """
    queryset = BlogPost.objects.filter(is_published=True).order_by('-created_at')
    serializer_class = BlogPostSerializer
    permission_classes = [permissions.AllowAny]

class PropertyImageViewSet(viewsets.ModelViewSet):
    """
    API pour envoyer des images après la création de l'annonce.
    """
    queryset = PropertyImage.objects.all()
    serializer_class = PropertyImageSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save()
