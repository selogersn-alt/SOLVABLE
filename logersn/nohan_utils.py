import requests
import json
from django.conf import settings

def call_gemini_api(prompt, history=None):
    """
    Version ultra-minimaliste pour Groq/Llama3 afin d'éliminer l'erreur 400.
    """
    api_key = getattr(settings, 'GROQ_API_KEY', None)
    if not api_key:
        return "Erreur : Clé API manquante."

    url = "https://api.groq.com/openai/v1/chat/completions"
    
    # Payload le plus simple possible
    payload = {
        "model": "llama3-8b-8192",
        "messages": [
            {
                "role": "system", 
                "content": "Tu es Nohan, assistant expert de Loger Sénégal. Sois poli et pro."
            },
            {
                "role": "user", 
                "content": prompt
            }
        ]
    }

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=10)
        
        # Log TOUJOURS le résultat pour comprendre
        with open('nohan_debug.log', 'a') as f:
            import datetime
            f.write(f"[{datetime.datetime.now()}] REQUETE GROQ - Status: {response.status_code} - Body: {response.text[:200]}\n")

        if response.status_code == 200:
            result = response.json()
            return result['choices'][0]['message']['content']
        else:
            return f"Désolé, je rencontre une petite difficulté (Erreur {response.status_code})."
    except Exception as e:
        return f"Erreur de connexion : {str(e)}"
