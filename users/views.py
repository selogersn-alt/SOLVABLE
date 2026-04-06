from rest_framework import viewsets
from .models import User, KYCProfile, NILS_Profile
from .serializers import UserSerializer, KYCProfileSerializer, NILS_ProfileSerializer

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

class KYCProfileViewSet(viewsets.ModelViewSet):
    queryset = KYCProfile.objects.all()
    serializer_class = KYCProfileSerializer

class NILS_ProfileViewSet(viewsets.ModelViewSet):
    queryset = NILS_Profile.objects.all()
    serializer_class = NILS_ProfileSerializer
