from rest_framework import serializers
from .models import User, KYCProfile, NILS_Profile, SolvencyDocument

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'id', 'email', 'phone_number', 'first_name', 'last_name', 
            'company_name', 'role', 'is_verified_pro',
            'is_active', 'is_staff', 'date_joined'
        ]

class UserMeSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'id', 'email', 'first_name', 'last_name', 'phone_number', 
            'company_name', 'role', 'is_verified_pro'
        ]

class KYCProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = KYCProfile
        fields = '__all__'

class NILS_ProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = NILS_Profile
        fields = '__all__'

class SolvencyDocumentSerializer(serializers.ModelSerializer):
    doc_type_display = serializers.CharField(source='get_doc_type_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = SolvencyDocument
        fields = ['id', 'doc_type', 'doc_type_display', 'file', 'status', 'status_display', 'rejection_reason', 'uploaded_at']
        read_only_fields = ['status', 'rejection_reason']

class UserMiniSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'first_name', 'last_name', 'company_name', 'profile_picture']
