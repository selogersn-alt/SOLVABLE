import requests
import json
from django.conf import settings
from logersn.models import Property
from django.urls import reverse
from django.db.models import Q

def search_matching_properties(query):
    """
    Recherche des biens immobiliers correspondant à la demande de l'utilisateur.
    """
    # Extraction de mots clés simples (Dakar, F3, etc.)
    keywords = query.split()
    search_query = Q(is_published=True, is_active=True)
    
    # Recherche basique sur le titre et la ville
    for word in keywords:
        if len(word) > 2:
            search_query &= (Q(title__icontains=word) | Q(city__icontains=word) | Q(neighborhood__icontains=word) | Q(description__icontains=word))
    
    properties = Property.objects.filter(search_query).order_by('-is_boosted', '-created_at')[:3]
    
    results = []
    for p in properties:
        url = f"https://logersenegal.com{reverse('property_detail_slug', args=[p.slug])}"
        results.append(f"- {p.title} ({p.city}) : {p.price} FCFA. Lien : {url}")
    
    return results

def call_gemini_api(prompt, history=None):
    """
    Version avec RECHERCHE D'ANNONCES et MÉMOIRE.
    """
    api_key = getattr(settings, 'GROQ_API_KEY', None)
    if not api_key:
        return "Erreur de configuration (Groq)."

    url = "https://api.groq.com/openai/v1/chat/completions"
    
    # 1. Recherche de biens correspondants
    matches = search_matching_properties(prompt)
    match_context = ""
    if matches:
        match_context = "\nVoici des annonces réelles sur notre site qui pourraient l'intéresser (Propose-les lui si c'est pertinent) :\n" + "\n".join(matches)

    system_instruction = (
        "TU ES NOHAN, l'expert de Loger Sénégal. "
        "TON RÔLE : Aider à trouver des biens et conseiller sur la solvabilité (Badge Solvable, NILS). "
        "CONSIGNES : "
        "- Utilise uniquement le FCFA. "
        "- Inscription par NUMÉRO DE TÉLÉPHONE uniquement. "
        "- Propose les liens des annonces si j'en fournis dans le contexte. "
        "- Sois poli, concis et efficace. "
        f"{match_context}"
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
        "temperature": 0.5,
        "max_tokens": 800,
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
            return "Je suis à votre service. Comment puis-je vous aider ?"
    except Exception as e:
        return "Je synchronise mes données immobilières. Un instant !"
