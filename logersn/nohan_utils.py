import requests
import json
from django.conf import settings

def call_gemini_api(prompt, history=None):
    """
    Appelle l'API Google Gemini pour générer une réponse de NOHAN.
    Version simplifiée pour éviter les erreurs de format et de région.
    """
    api_key = getattr(settings, 'GEMINI_API_KEY', None)
    if not api_key:
        return "Désolé, ma connexion au cerveau central est interrompue (Clé API manquante)."

    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={api_key}"
    
    system_instruction = (
        "TU ES NOHAN, l'assistant expert Premium de Loger Sénégal. "
        "CONSIGNES : "
        "- Tu parles d'immobilier au Sénégal uniquement. "
        "- Tu es poli, expert et serviable. "
        "- Tu connais le système NILS (crédits de fiabilité) et le Badge Solvable (gratuit pour les locataires). "
        "- Si on te demande de créer un compte, explique qu'il suffit de cliquer sur le bouton 'Se connecter' puis 'S'inscrire'. "
        "- Si on cherche un appartement, conseille d'utiliser les filtres de recherche ou de contacter les agents via WhatsApp."
    )

    # On fusionne l'instruction système dans le premier message pour plus de compatibilité
    messages = []
    
    full_prompt = f"{system_instruction}\n\nVoici l'historique récent :\n"
    if history:
        for msg in history[-5:]: # Limiter à l'historique récent
            role = "Utilisateur" if msg['role'] == 'user' else "Nohan"
            full_prompt += f"{role}: {msg['content']}\n"
    
    full_prompt += f"\nNouvelle question de l'utilisateur : {prompt}"

    payload = {
        "contents": [{
            "parts": [{"text": full_prompt}]
        }],
        "generationConfig": {
            "temperature": 0.4,
            "maxOutputTokens": 500,
        }
    }

    try:
        response = requests.post(url, json=payload, timeout=15)
        if response.status_code != 200:
            # Fallback simple si la requête complexe échoue
            print(f"Gemini Error: {response.text}")
            return "Je suis là ! Pouvez-vous répéter votre question ? Je suis prêt à vous aider."
            
        result = response.json()
        return result['candidates'][0]['content']['parts'][0]['text']
    except Exception as e:
        print(f"Gemini Exception: {e}")
        return "Je fais une petite maintenance technique. Je reviens vers vous dans quelques secondes !"
