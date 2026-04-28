import requests
import json
from django.conf import settings

def call_gemini_api(prompt, history=None):
    """
    Version FINALE et INTELLIGENTE de NOHAN via Groq/Llama3.
    """
    api_key = getattr(settings, 'GROQ_API_KEY', None)
    if not api_key:
        return "Erreur de configuration."

    url = "https://api.groq.com/openai/v1/chat/completions"
    
    system_instruction = (
        "TU ES NOHAN, l'assistant expert de Loger Sénégal. "
        "TON DOMAINE : Immobilier au Sénégal exclusivement. "
        "CONSIGNES STRICTES : "
        "- Tu parles d'APPARTEMENTS, VILLAS, TERRAINS. Jamais de voitures, d'hôtels ou de voyages. "
        "- Tu es sur Loger Sénégal, le site n°1 de location sécurisée. "
        "- Tu connais le Badge Solvable (gratuit pour les locataires) et les Points NILS (fiabilité). "
        "- Ton ton est Premium, poli et professionnel. "
        "- Si un utilisateur cherche un bien (ex: un F4), demande-lui sa zone préférée (Dakar, Saly, etc.) et son budget."
    )

    messages = [
        {"role": "system", "content": system_instruction}
    ]

    # Restaurer la mémoire (historique)
    if history:
        for msg in history[-6:]: # Se souvient des 6 derniers messages
            role = "user" if msg['role'] == 'user' else "assistant"
            messages.append({"role": role, "content": msg['content']})
            
    # Ajouter la question actuelle
    messages.append({"role": "user", "content": prompt})

    payload = {
        "model": "llama-3.1-8b-instant",
        "messages": messages,
        "temperature": 0.6,
        "max_tokens": 500,
    }

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=12)
        if response.status_code == 200:
            result = response.json()
            return result['choices'][0]['message']['content']
        else:
            return "Je suis là ! Pouvez-vous reformuler votre question immobilière ?"
    except Exception as e:
        return "Je fais une petite maintenance technique. Un instant !"
