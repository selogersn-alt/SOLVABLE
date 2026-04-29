import logging
from django.contrib.auth.backends import ModelBackend
from django.db.models import Q
from django.contrib.auth import get_user_model

User = get_user_model()

logger = logging.getLogger(__name__)

class EmailOrPhoneModelBackend(ModelBackend):
    """
    Custom authentication backend that allows users to log in using either their
    phone number or their email address.
    """
    def authenticate(self, request, username=None, password=None, **kwargs):
        # DRF TokenObtainPairView sends identifier in 'username' field
        # Web login view sends phone in 'phone_number' field via authenticate call
        
        identifier = username or kwargs.get('phone_number')
        
        if identifier is None:
            return None

        identifier = identifier.strip()

        try:
            # 1. Exact match (Phone or Email)
            user = User.objects.filter(Q(phone_number=identifier) | Q(email=identifier)).first()
            
            # 2. Match without '+'
            if not user and identifier.startswith('+'):
                user = User.objects.filter(phone_number=identifier[1:]).first()
                
            # 3. Match without '+221' (Senegal prefix)
            if not user and identifier.startswith('+221'):
                user = User.objects.filter(phone_number=identifier[4:]).first()
                
            if user and user.check_password(password) and self.user_can_authenticate(user):
                return user
        except Exception as e:
            import logging
            logging.error(f"Auth Backend Error: {e}")
            return None
        return None
