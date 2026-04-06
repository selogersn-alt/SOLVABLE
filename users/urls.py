from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import UserViewSet, KYCProfileViewSet, NILS_ProfileViewSet

router = DefaultRouter()
router.register(r'', UserViewSet)
router.register(r'kyc', KYCProfileViewSet, basename='kyc')
router.register(r'nils', NILS_ProfileViewSet, basename='nils')

urlpatterns = [
    path('', include(router.urls)),
]
