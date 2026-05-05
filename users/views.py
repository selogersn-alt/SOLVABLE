
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.urls import reverse
from django.http import JsonResponse

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


def login_view(request):
    if request.method == 'POST':
        phone = request.POST.get('phone', '').strip()
        password = request.POST.get('password')
        
        # Le formatage intelligent (+221, sans +, etc.) est désormais géré
        # globalement par users.backends.EmailOrPhoneModelBackend
        # On utilise username au lieu de phone_number pour que le backend le reçoive correctement
        user = authenticate(request, username=phone, password=password)
        
        if user is not None:
            login(request, user)
            messages.success(request, f"Bienvenue, {user.get_full_name()} !")
            return redirect('dashboard')
        else:
            messages.error(request, "Numéro de téléphone ou mot de passe incorrect.")
            
    return render(request, 'login.html')

def register_view(request):
    ref_username = request.GET.get('ref')
    if request.method == 'POST':
        email = request.POST.get('email')
        phone = request.POST.get('phone')
        password = request.POST.get('password')
        password_confirm = request.POST.get('password_confirm')
        no_email = request.POST.get('no_email')
        role = request.POST.get('role', 'TENANT')
        company_name = request.POST.get('company_name')
        coverage_area = request.POST.get('coverage_area')
        ref_by = request.POST.get('ref_by')
        
        if password != password_confirm:
            messages.error(request, "Les mots de passe ne correspondent pas.")
            return render(request, 'register.html', {'ref': ref_by})
            
        if not no_email and not email:
            messages.error(request, "Veuillez fournir un email ou cocher la case 'Je n'ai pas d'adresse email'.")
            return render(request, 'register.html', {'ref': ref_by})
            
        if email and User.objects.filter(email=email).exists():
            messages.error(request, "Cet email est déjà utilisé.")
            return render(request, 'register.html', {'ref': ref_by})
            
        if User.objects.filter(phone_number=phone).exists():
            messages.error(request, "Ce numéro de téléphone est déjà utilisé.")
            return render(request, 'register.html', {'ref': ref_by})
            
        try:
            # Création de l'utilisateur
            user = User.objects.create_user(phone_number=phone, email=email if email else None, password=password, role=role)
            user.company_name = company_name
            user.coverage_area = coverage_area
            
            # Gestion du parrainage (Correction DigitalH : On cherche par phone_number)
            if ref_by:
                referrer = User.objects.filter(phone_number=ref_by).first()
                if referrer:
                    user.referred_by = referrer
            
            user.save()
            
            # Tentative d'envoi OTP (Silencieux pour éviter 500)
            try:
                user.send_otp()
            except:
                pass
            
            login(request, user)
            messages.success(request, "Votre compte a été créé avec succès !")
            return redirect('dashboard')
        except Exception as e:
            messages.error(request, f"Une erreur est survenue lors de la création du compte : {str(e)}")
            return render(request, 'register.html', {'ref': ref_by})
            
    return render(request, 'register.html', {'ref': ref_username})

def logout_view(request):
    logout(request)
    messages.success(request, "Vous avez été déconnecté.")
    return redirect('home')

def password_recovery_view(request):
    phone = request.GET.get('phone', '').strip()
    if request.headers.get('x-requested-with') == 'XMLHttpRequest' and phone:
        from users.models import User
        user = User.objects.filter(phone_number__icontains=phone).first()
        if user:
            return JsonResponse({
                'exists': True, 
                'has_email': bool(user.email),
                'email_masked': (user.email[:3] + '****' + user.email[user.email.find('@'):]) if user.email else ''
            })
        return JsonResponse({'exists': False})

    if request.method == 'POST':
        phone = request.POST.get('phone', '').strip()
        method = request.POST.get('method', 'whatsapp') 
        
        from users.models import User
        user = User.objects.filter(phone_number__icontains=phone).first()
        
        if user:
            from django.utils.http import urlsafe_base64_encode
            from django.utils.encoding import force_bytes
            from django.contrib.auth.tokens import default_token_generator
            from logersenegal.emails import send_password_reset_email
            
            uid = urlsafe_base64_encode(force_bytes(user.pk))
            token = default_token_generator.make_token(user)
            reset_url = request.build_absolute_uri(
                reverse('password_reset_confirm_public', kwargs={'uidb64': uid, 'token': token})
            )

            if method == 'email' and user.email:
                send_password_reset_email(user, reset_url)
                messages.success(request, f"Un lien de réinitialisation sécurisé a été envoyé à l'adresse {user.email}")
                return redirect('login')
            else:
                # On prépare pour le template
                return render(request, 'recovery.html', {'phone': phone, 'show_wa_link': True, 'reset_url': reset_url})
        else:
            messages.error(request, "Numéro de téléphone inconnu.")
            
    return render(request, 'recovery.html')

def password_reset_confirm_view(request, uidb64, token):
    """Interface Frontend pour définir un nouveau mot de passe."""
    from users.models import User
    from django.utils.encoding import force_str
    from django.utils.http import urlsafe_base64_decode
    from django.contrib.auth.tokens import default_token_generator
    
    try:
        uid = force_str(urlsafe_base64_decode(uidb64))
        user = User.objects.get(pk=uid)
    except (TypeError, ValueError, OverflowError, User.DoesNotExist, Exception):
        messages.error(request, "Lien de réinitialisation invalide.")
        return redirect('password_recovery')

    if default_token_generator.check_token(user, token):
        if request.method == 'POST':
            new_password = request.POST.get('password')
            confirm_password = request.POST.get('confirm_password')
            
            if new_password and new_password == confirm_password:
                user.set_password(new_password)
                user.is_phone_verified = True
                user.save()
                messages.success(request, "Mot de passe réinitialisé ! Vous pouvez vous connecter.")
                return redirect('login')
            else:
                messages.error(request, "Les mots de passe ne correspondent pas.")
        
        return render(request, 'password_reset_confirm_public.html', {
            'uidb64': uidb64, 
            'token': token,
            'reset_user': user
        })
    else:
        messages.error(request, "Lien de réinitialisation expiré ou déjà utilisé.")
        return redirect('password_recovery')

@login_required
def admin_generate_reset_link(request, user_id):
    """Génère un lien de réinitialisation. Option email=1 pour envoi direct."""
    from django.utils.http import urlsafe_base64_encode
    from django.utils.encoding import force_bytes
    from django.contrib.auth.tokens import default_token_generator
    from logersenegal.emails import send_password_reset_email
    
    if not request.user.is_staff:
        return JsonResponse({'error': 'Accès interdit'}, status=403)
        
    from users.models import User
    user = get_object_or_404(User, pk=user_id)
    token = default_token_generator.make_token(user)
    uid = urlsafe_base64_encode(force_bytes(user.pk))
