import requests
import json
from django.conf import settings

def call_gemini_api(prompt, history=None):
    """
    Appelle l'API Google Gemini pour générer une réponse de NOHAN.
    """
    api_key = getattr(settings, 'GEMINI_API_KEY', None)
    if not api_key:
        return "Désolé, ma connexion au cerveau central est interrompue (Clé API manquante)."

    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={api_key}"
    
    system_instruction = (
        "Tu t'appelles NOHAN. Tu es l'assistant intelligent officiel de la plateforme immobilière 'Loger Sénégal' (aussi appelée Solvable). "
        "Ton but est d'aider les locataires et les professionnels. "
        "Tu es expert sur : "
        "1. Le système de points NILS (récompenses pour la fiabilité). "
        "2. Le badge de solvabilité Solvable (certification des locataires). "
        "3. Le fonctionnement général du site (annonces, contrats de bail numériques). "
        "Ton ton est professionnel, chaleureux, serviable et très poli. Tu réponds principalement en français, "
        "mais tu peux parler Wolof ou Anglais si l'utilisateur le demande. "
        "Si tu ne connais pas une réponse spécifique sur une annonce, invite l'utilisateur à contacter directement le propriétaire via le bouton WhatsApp sur l'annonce."
    )

    contents = []
    # Ajouter l'historique si présent
    if history:
        for msg in history:
            contents.append({
                "role": "user" if msg['role'] == 'user' else "model",
                "parts": [{"text": msg['content']}]
            })
            
    # Ajouter le prompt actuel
    contents.append({
        "role": "user",
        "parts": [{"text": f"Instruction système: {system_instruction}\n\nUtilisateur: {prompt}"}]
    })

    payload = {
        "contents": contents,
        "generationConfig": {
            "temperature": 0.7,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 1024,
        }
    }

    try:
        response = requests.post(url, json=payload, timeout=10)
        response.raise_for_status()
        result = response.json()
        return result['candidates'][0]['content']['parts'][0]['text']
    except Exception as e:
        print(f"Gemini API Error: {e}")
        return "Oups ! J'ai un petit bug technique. Réessayez dans un instant, je vais me rafraîchir les idées."
