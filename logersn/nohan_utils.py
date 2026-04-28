import requests
import json
import re
from django.conf import settings
from logersn.models import Property
from django.urls import reverse
from django.db.models import Q

def search_matching_properties(query):
    """
    Moteur de recherche Nohan v3 - Détection sémantique avancée.
    """
    query = query.lower()
    search_query = Q(is_published=True, is_active=True)
    
    # 1. Transaction (Louer vs Vendre)
    if any(word in query for word in ["vendre", "achat", "acheter", "vente"]):
        search_query &= Q(listing_category=Property.CategoryEnum.SALE)
    elif any(word in query for word in ["meublé", "nuit", "court séjour"]):
        search_query &= Q(listing_category=Property.CategoryEnum.FURNISHED)
    else:
        # Par défaut on cherche en location si rien n'est précisé
        search_query &= Q(listing_category=Property.CategoryEnum.RENT)

    # 2. Budget
    price_match = re.search(r'(\d+)\s*(?:000|k|fr|fcfa)', query)
    if price_match:
        price_val = int(price_match.group(1))
        if '000' not in price_match.group(0) and 'k' in query:
            price_val = price_val * 1000
        search_query &= Q(price__lte=price_val * 1.25)

    # 3. Chambres / Type
    room_match = re.search(r'f(\d+)|(\d+)\s*chambre', query)
    if room_match:
        rooms = room_match.group(1) or room_match.group(2)
        search_query &= (Q(title__icontains=f"F{rooms}") | Q(bedrooms=rooms))
    elif "studio" in query:
        search_query &= Q(title__icontains="studio")

    # 4. Quartiers (Mapping sémantique pour Dakar)
    neighborhoods = {
        "almadies": "Almadies",
        "plateau": "Dakar Plateau",
        "ngor": "Ngor",
        "ouakam": "Ouakam",
        "mermoz": "Mermoz",
        "sacré coeur": "Sacré-Cœur",
        "vdn": "VDN",
        "guédiawaye": "Guédiawaye",
        "pikine": "Pikine",
        "rufisque": "Rufisque"
    }
    
    geo_query = Q()
    has_geo = False
    for key, val in neighborhoods.items():
        if key in query:
            geo_query |= Q(neighborhood__icontains=val) | Q(neighborhood__icontains=key)
            has_geo = True
    
    if not has_geo:
        # Si pas de quartier connu, on cherche les mots-clés libres
        keywords = query.split()
        for word in keywords:
            if len(word) > 3 and word not in ["louer", "cherche", "appartement", "maison", "chambre", "vendre", "location"]:
                geo_query |= (Q(title__icontains=word) | Q(neighborhood__icontains=word))
                has_geo = True
    
    if has_geo:
        search_query &= geo_query
    
    properties = Property.objects.filter(search_query).order_by('-is_boosted', '-created_at')[:3]
    
    if not properties.exists():
        # Fallback intelligent : derniers biens de la même catégorie
        fallback_query = Q(is_published=True, is_active=True)
        if any(word in query for word in ["vendre", "achat"]): fallback_query &= Q(listing_category=Property.CategoryEnum.SALE)
        properties = Property.objects.filter(fallback_query).order_by('-created_at')[:2]

    results = []
    for p in properties:
        try:
            url = f"https://logersenegal.com{reverse('property_detail_slug', args=[p.slug])}"
            primary_img = p.images.filter(is_primary=True).first() or p.images.first()
            img_url = "https://logersenegal.com/static/images/placeholder-property.jpg"
            if primary_img and primary_img.image_url:
                img_url = primary_img.image_url.url
                if not img_url.startswith('http'): img_url = f"https://logersenegal.com{img_url}"

            card_data = {"title": p.title, "price": f"{p.price:,}".replace(",", " "), "url": url, "image": img_url}
            results.append(f"[PROPERTY_CARD:{json.dumps(card_data).replace('\"', '&quot;')}]")
        except: continue
    
    return results

def call_gemini_api(prompt, history=None):
    api_key = getattr(settings, 'GROQ_API_KEY', None)
    if not api_key: return "Désolé, je suis en pleine mise à jour."

    matches = search_matching_properties(prompt)
    match_context = ""
    if matches:
        match_context = "\nANNONCES RÉELLES : \n" + "\n".join(matches)
    else:
        match_context = "\nAUCUN BIEN TROUVÉ. Sois honnête et demande plus de détails (quartier, budget)."

    system_instruction = (
        "TU ES NOHAN. Expert Immobilier n°1 de Loger Sénégal. "
        "MISSION : Accompagner, conseiller et vendre. "
        "TON : Chaleureux, expert, avec une touche de Teranga (hospitalité sénégalaise). "
        "LANGUE : Français impeccable. Tu peux utiliser quelques mots de Wolof chaleureux comme 'Salaam Aleikum', 'Jerejef', 'Ba beneen yoon'. "
        "INFOS CLÉS : Numéro officiel 76 444 33 13. Pousse le Badge Solvable pour les locataires. "
        "RÈGLES : Ne JAMAIS inventer d'annonces. Utilise uniquement le CONTEXTE. "
        f"{match_context}"
    )

    messages = [{"role": "system", "content": system_instruction}]
    if history:
        for msg in history[-4:]:
            messages.append({"role": "user" if msg['role'] == 'user' else "assistant", "content": msg['content']})
    messages.append({"role": "user", "content": prompt})

    try:
        response = requests.post(
            "https://api.groq.com/openai/v1/chat/completions",
            json={"model": "llama-3.1-8b-instant", "messages": messages, "temperature": 0.1, "max_tokens": 800},
            headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
            timeout=10
        )
        return response.json()['choices'][0]['message']['content'] if response.status_code == 200 else "Comment puis-je vous aider aujourd'hui ?"
    except: return "Je suis à votre écoute. Quelle est votre recherche ?"
