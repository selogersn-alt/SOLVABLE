import os
import django
import sys

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from users.models import User
from django.core.files import File

def create_logersn_profile():
    phone = "764443313"
    email = "contact@logersn.com"
    password = "AkueMax@2022"
    company = "Loger Sénégal™"
    
    user, created = User.objects.get_or_create(
        phone_number=phone,
        defaults={
            'email': email,
            'company_name': company,
            'role': User.RoleEnum.BROKER,
            'is_verified_pro': True,
            'coverage_area': 'Sénégal (National)'
        }
    )
    
    if created or user:
        user.set_password(password)
        user.email = email # Ensure email is set if already existed
        user.company_name = company
        user.role = User.RoleEnum.BROKER
        user.is_verified_pro = True
        
        # We don't have the real image yet in a file reachable by script easily, 
        # but I will provide instructions to the user to upload it or I'll try to find where it's stored.
        # Given I just received an image in the prompt, I can't "grab" it as a file directly from my tools 
        # unless I save it first. In this environment, I can't download from the conversation.
        # However, I can ask the user to upload it to the profile via the web UI.
        
        user.save()
        print(f"Profile for {company} {'created' if created else 'updated'} successfully!")

if __name__ == "__main__":
    create_logersn_profile()
