from rest_framework import viewsets
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import SolvencyDocument
from .serializers import UserMeSerializer, SolvencyDocumentSerializer

class UserMeView(APIView):
    """
    Renvoie les informations de l'utilisateur actuellement connecté via JWT.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserMeSerializer(request.user)
        return Response(serializer.data)

class SolvencyDocumentViewSet(viewsets.ModelViewSet):
    serializer_class = SolvencyDocumentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return self.request.user.solvency_docs.all()

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
