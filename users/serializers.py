from rest_framework import serializers
from .models import User, KYCProfile, NILS_Profile

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'phone_number', 'is_active', 'is_staff', 'date_joined']

class KYCProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = KYCProfile
        fields = '__all__'

class NILS_ProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = NILS_Profile
        fields = '__all__'
