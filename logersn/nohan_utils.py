import requests
import json
from django.conf import settings

def call_gemini_api(prompt, history=None):
    """
    NOTE: Cette fonction s'appelle encore 'call_gemini_api' pour ne pas casser 
    le reste du code, mais elle utilise désormais GROQ (Llama 3) pour la performance.
    """
    api_key = getattr(settings, 'GROQ_API_KEY', None)
    if not api_key:
        return "Désolé, ma connexion au cerveau central est interrompue (Clé Groq manquante)."

    url = "https://api.groq.com/openai/v1/chat/completions"
    
    system_instruction = (
        "Tu es NOHAN, l'assistant expert Premium de Loger Sénégal (Solvable). "
        "Ta mission est d'être l'ambassadeur du site et l'expert immobilier pour nos utilisateurs. "
        "CONNAISSANCES : "
        "- Loger Sénégal est la plateforme n°1 pour la location sécurisée au Sénégal. "
        "- Système NILS : récompense la fiabilité des locataires et bailleurs. "
        "- Badge Solvable : gratuit pour les locataires, certifie leur dossier. "
        "- On propose : appartements, villas, studios, meublés, terrains. "
        "RÈGLES : "
        "1. Sois poli, expert et utilise un ton 'Haut de gamme'. "
        "2. Reste STRICTEMENT dans l'immobilier et Loger Sénégal. "
        "3. Aide les utilisateurs à créer leur compte ou trouver des biens."
    )

    messages = [
        {"role": "system", "content": system_instruction}
    ]

    # Ajouter l'historique
    if history:
        for msg in history[-5:]:
            messages.append({"role": msg['role'] if msg['role'] == 'user' else 'assistant', "content": msg['content']})
            
    # Ajouter le prompt actuel
    messages.append({"role": "user", "content": prompt})

    payload = {
        "model": "llama3-8b-8192",
        "messages": messages,
        "temperature": 0.5,
        "max_tokens": 800,
    }

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=15)
        
        # Log de debug rapide
        with open('nohan_debug.log', 'a') as f:
            import datetime
            f.write(f"[{datetime.datetime.now()}] GROQ Status: {response.status_code}\n")

        if response.status_code == 200:
            result = response.json()
            return result['choices'][0]['message']['content']
        else:
            return "Je suis en train de synchroniser mes données. Posez-moi votre question à nouveau dans 5 secondes !"
    except Exception as e:
        return "Petit souci de connexion, je reviens vers vous immédiatement !"
