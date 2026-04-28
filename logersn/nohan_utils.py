import requests
import json
from django.conf import settings

def call_gemini_api(prompt, history=None):
    """
    Version OPTIMISÉE SÉNÉGAL de NOHAN.
    """
    api_key = getattr(settings, 'GROQ_API_KEY', None)
    if not api_key:
        return "Erreur de configuration."

    url = "https://api.groq.com/openai/v1/chat/completions"
    
    system_instruction = (
        "TU ES NOHAN, l'expert immobilier n°1 de Loger Sénégal. "
        "CONSIGNES DE RÉPONSE : "
        "- Monnaie : Utilise uniquement le FCFA (XOF). Jamais de DA ou d'Euro. "
        "- Inscription : Sur Loger Sénégal, on s'inscrit avec son NUMÉRO DE TÉLÉPHONE. "
        "- Style : Sois concis. Ne fais pas de longs textes historiques sur les villes. Va droit au but. "
        "- Ton : Professionnel, chaleureux et Premium. "
        "- Services clés : Badge Solvable (gratuit, rassure les proprios) et Points NILS (indice de confiance). "
        "- Objectif : Aider l'utilisateur à trouver un bien et l'inciter à contacter l'agent via WhatsApp."
    )

    messages = [
        {"role": "system", "content": system_instruction}
    ]

    if history:
        for msg in history[-6:]:
            role = "user" if msg['role'] == 'user' else "assistant"
            messages.append({"role": role, "content": msg['content']})
            
    messages.append({"role": "user", "content": prompt})

    payload = {
        "model": "llama-3.1-8b-instant",
        "messages": messages,
        "temperature": 0.5, # Plus précis, moins créatif
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
            return "Je suis à votre service. Comment puis-je vous aider pour votre recherche immobilière ?"
    except Exception as e:
        return "Je synchronise mes données. Un instant !"
