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
        "Tu es NOHAN, l'assistant virtuel Premium de Loger Sénégal (Solvable). "
        "Ta mission est d'être l'ambassadeur du site et l'expert immobilier pour nos utilisateurs. "
        "CONNAISSANCES DU SITE : "
        "- Nous sommes la plateforme n°1 au Sénégal pour la location sécurisée. "
        "- Nous proposons des appartements, villas, studios (meublés ou vides) et terrains. "
        "- Le système NILS est notre exclusivité : il certifie la fiabilité des locataires et bailleurs. "
        "- Le Badge Solvable est GRATUIT pour les locataires et augmente leurs chances de 80%. "
        "- Nous avons des agences partenaires certifiées à Dakar, Thiès, Saly et Saint-Louis. "
        "RÈGLES D'OR : "
        "1. Ton ton doit être extrêmement poli, élégant et expert (Haut de gamme). "
        "2. Ne parle JAMAIS de sujets en dehors de l'immobilier ou de Loger Sénégal. "
        "3. Si on te pose une question sur un bien précis, explique que tu peux aider à trouver mais invite l'utilisateur à contacter le Pro via le bouton WhatsApp pour les détails finaux. "
        "4. Tu connais les catégories : Location vide, Location meublée, Vente, Terrains. "
        "5. Tu aides les Pros à booster leurs annonces (Top Ads, Pop-up Premium)."
    )

    contents = []
    # Gemini 1.5 Flash gère mieux une structure simple pour les instructions système
    contents.append({
        "role": "user",
        "parts": [{"text": f"SYSTEM INSTRUCTION: {system_instruction}"}]
    })
    contents.append({
        "role": "model",
        "parts": [{"text": "Compris. Je suis NOHAN, l'assistant Premium de Loger Sénégal. Je suis prêt à aider les utilisateurs avec expertise."}]
    })

    # Ajouter l'historique
    if history:
        for msg in history:
            contents.append({
                "role": "user" if msg['role'] == 'user' else "model",
                "parts": [{"text": msg['content']}]
            })
            
    # Ajouter le prompt actuel
    contents.append({
        "role": "user",
        "parts": [{"text": prompt}]
    })

    payload = {
        "contents": contents,
        "generationConfig": {
            "temperature": 0.5, # Plus stable et moins créatif
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 800,
        }
    }

    try:
        response = requests.post(url, json=payload, timeout=15) # Augmentation du timeout
        if response.status_code != 200:
            print(f"Gemini API Error: {response.text}")
            return "Je rencontre une forte affluence en ce moment. Pouvez-vous reformuler votre question ?"
            
        result = response.json()
        return result['candidates'][0]['content']['parts'][0]['text']
    except Exception as e:
        print(f"Gemini API Exception: {e}")
        return "Je suis en train de mettre à jour mes connaissances immobilières. Posez-moi votre question à nouveau dans quelques secondes."
