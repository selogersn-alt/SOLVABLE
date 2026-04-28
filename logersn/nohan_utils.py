import requests
import json
from django.conf import settings

def call_gemini_api(prompt, history=None):
    """
    Appelle l'API Google Gemini pour générer une réponse de NOHAN.
    Version v1 stable avec log de debug.
    """
    api_key = getattr(settings, 'GEMINI_API_KEY', None)
    if not api_key:
        return "Désolé, ma connexion au cerveau central est interrompue (Clé API manquante)."

    # Retour à v1beta (requis pour gemini-1.5-flash selon votre erreur 404)
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={api_key}"
    
    system_instruction = (
        "TU ES NOHAN, l'assistant expert Premium de Loger Sénégal. "
        "CONSIGNES : Tu es un expert immobilier poli. Tu connais le site Loger Sénégal, le système NILS et le Badge Solvable. "
        "Ne parle que d'immobilier."
    )

    full_prompt = f"{system_instruction}\n\nQuestion client: {prompt}"

    payload = {
        "contents": [{
            "parts": [{"text": full_prompt}]
        }]
    }

    try:
        response = requests.post(url, json=payload, timeout=15)
        
        # LOG DE DEBUG (Sera visible dans le fichier nohan_debug.log)
        with open('nohan_debug.log', 'a') as f:
            import datetime
            f.write(f"[{datetime.datetime.now()}] Status: {response.status_code} - Response: {response.text[:200]}\n")

        if response.status_code == 200:
            result = response.json()
            return result['candidates'][0]['content']['parts'][0]['text']
        else:
            return "Je suis en train de synchroniser mes données immobilières. Posez-moi votre question à nouveau dans un court instant."
            
    except Exception as e:
        with open('nohan_debug.log', 'a') as f:
            f.write(f"[{datetime.datetime.now()}] EXCEPTION: {str(e)}\n")
        return "Je fais une petite maintenance technique. Je reviens vers vous très vite !"
