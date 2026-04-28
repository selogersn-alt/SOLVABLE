import requests
import json
from django.conf import settings
from logersn.models import Property
from django.urls import reverse
from django.db.models import Q

def search_matching_properties(query):
    """
    Recherche des biens immobiliers correspondant à la demande de l'utilisateur.
    Retourne des tags [PROPERTY_CARD:...] pour le frontend.
    """
    keywords = query.split()
    search_query = Q(is_published=True, is_active=True)
    
    # Recherche basique sur le titre, ville, quartier, description
    has_keywords = False
    for word in keywords:
        if len(word) > 2:
            search_query &= (Q(title__icontains=word) | Q(city__icontains=word) | Q(neighborhood__icontains=word) | Q(description__icontains=word))
            has_keywords = True
    
    if not has_keywords:
        return []

    properties = Property.objects.filter(search_query).order_by('-is_boosted', '-created_at')[:3]
    
    results = []
    for p in properties:
        url = f"https://logersenegal.com{reverse('property_detail_slug', args=[p.slug])}"
        # Récupération de l'image principale
        primary_img = p.images.filter(is_primary=True).first() or p.images.first()
        img_url = "https://logersenegal.com/static/images/placeholder-property.jpg"
        if primary_img and primary_img.image_url:
            img_url = primary_img.image_url.url
            if not img_url.startswith('http'):
                img_url = f"https://logersenegal.com{img_url}"

        # Création du tag JSON pour le frontend
        card_data = {
            "title": p.title,
            "price": f"{p.price:,}".replace(",", " "),
            "url": url,
            "image": img_url
        }
        json_data = json.dumps(card_data).replace('"', '&quot;')
        results.append(f"[PROPERTY_CARD:{json_data}]")
    
    return results

def call_gemini_api(prompt, history=None):
    """
    Version avec CAPTURE DE LEAD et CARTES VISUELLES.
    """
    api_key = getattr(settings, 'GROQ_API_KEY', None)
    if not api_key:
        return "Erreur de configuration (Groq)."

    url = "https://api.groq.com/openai/v1/chat/completions"
    
    # 1. Recherche de biens correspondants
    matches = search_matching_properties(prompt)
    match_context = ""
    if matches:
        match_context = "\nVoici des cartes d'annonces réelles sur notre site. Affiche-les à l'utilisateur :\n" + "\n".join(matches)

    system_instruction = (
        "TU ES NOHAN, l'agent commercial expert de Loger Sénégal. "
        "OBJECTIF : Vendre des biens et capturer des leads. "
        "CONSIGNES : "
        "- Utilise exclusivement le FCFA. "
        "- Si l'utilisateur est intéressé par un bien, dis-lui : 'Je peux transmettre votre dossier au propriétaire pour une visite prioritaire. Quel est votre numéro de téléphone ?'. "
        "- Si des tags [PROPERTY_CARD:...] sont fournis dans le contexte, inclus-les TEL QUELS dans ta réponse. "
        "- Ton ton doit être premium, accueillant et pro-actif. "
        f"{match_context}"
    )

    messages = [{"role": "system", "content": system_instruction}]

    if history:
        for msg in history[-6:]:
            role = "user" if msg['role'] == 'user' else "assistant"
            messages.append({"role": role, "content": msg['content']})
            
    messages.append({"role": "user", "content": prompt})

    payload = {
        "model": "llama-3.1-8b-instant",
        "messages": messages,
        "temperature": 0.6,
        "max_tokens": 1000,
    }

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=15)
        if response.status_code == 200:
            result = response.json()
            return result['choices'][0]['message']['content']
        else:
            return "Je suis Nohan, à votre service. Comment puis-je vous aider dans votre recherche immobilière aujourd'hui ?"
    except Exception as e:
        return "Je mets à jour mes catalogues de biens. Un instant !"
