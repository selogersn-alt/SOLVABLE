import requests
import json
from django.conf import settings

def send_sms_termii(phone_number, message):
    """
    Envoie un SMS via l'API Termii.
    """
    api_key = getattr(settings, 'TERMII_API_KEY', None)
    sender_id = getattr(settings, 'TERMII_SENDER_ID', 'LogerSN')
    
    if not api_key:
        print("Erreur: TERMII_API_KEY non configurée dans settings.py")
        return False

    # Formatage du numéro (Termii préfère le format international sans +)
    clean_phone = phone_number.replace('+', '').replace(' ', '')
    
    url = "https://api.ng.termii.com/api/sms/send"
    
    payload = {
        "to": clean_phone,
        "from": sender_id,
        "sms": message,
        "type": "plain",
        "channel": "generic", # Utiliser "dnd" ou "generic" selon votre compte Termii
        "api_key": api_key
    }
    
    headers = {
        'Content-Type': 'application/json',
    }
    
    try:
        response = requests.post(url, headers=headers, data=json.dumps(payload), timeout=10)
        result = response.json()
        if response.status_code == 200:
            print(f"SMS envoyé avec succès à {clean_phone} via Termii")
            return True
        else:
            print(f"Erreur Termii ({response.status_code}): {result}")
            return False
    except Exception as e:
        print(f"Exception lors de l'envoi SMS Termii : {str(e)}")
        return False

def send_otp_termii(user):
    """
    Envoie le code OTP de l'utilisateur par SMS via Termii.
    """
    if not user.phone_otp:
        return False
        
    message = f"Votre code de vérification Loger Sénégal est : {user.phone_otp}. Ne le partagez pas."
    return send_sms_termii(user.phone_number, message)
