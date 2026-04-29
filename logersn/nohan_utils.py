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
    
    properties = Property.objects.filter(search_query).order_by('-created_at')[:3]
    
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

            card_data = {"id": p.id, "title": p.title, "price": f"{p.price:,}".replace(",", " "), "url": url, "image": img_url}
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
        "TON IDENTITÉ & MISSION :\n"
        "Tu es Nohan, l'assistant virtuel de la plateforme Loger Sénégal. Ton rôle est d'assister les utilisateurs pour qu'ils profitent au mieux du site.\n"
        "Tu n'es pas juste un robot, tu es le guide de la plateforme. Sois intelligent, direct et aide concrètement.\n\n"
        
        "CONNAISSANCES DE LA PLATEFORME (À UTILISER POUR RÉPONDRE) :\n"
        "1. NILS : Système de scoring et d'identification pour sécuriser les bailleurs et locataires.\n"
        "2. BADGE SOLVABLE : Certification que le locataire peut payer son loyer. Indispensable pour rassurer les propriétaires.\n"
        "3. PUBLICATION : Pour publier une annonce, l'utilisateur doit cliquer sur 'Publier'. Frais : 2 000 F (Standard) ou 5 000 F (Premium/Boost).\n"
        "4. SÉCURITÉ : Ne donne JAMAIS de numéro de téléphone privé. En cas de doute, oriente vers la 'Liste Noire' du site.\n"
        "5. SUPPORT : Pour une aide humaine, contactez le 76 444 33 13 (WhatsApp).\n\n"

        "RÈGLES D'OR :\n"
        "* RECHERCHE : Si l'utilisateur cherche un bien, sers-toi UNIQUEMENT des annonces fournies ci-dessous. Si la liste est vide, dis : 'Je n'ai pas d'annonce correspondant exactement, mais je peux vous aider sur le fonctionnement du site.'\n"
        "* PAS DE BAVARDAGE INUTILE : Ne réponds pas aux questions hors-sujet (cuisine, météo, etc.).\n"
        "* MÉMOIRE : Utilise l'historique pour ne pas te répéter. Si l'utilisateur a déjà donné son budget, ne lui redemande pas.\n"
        "* STYLE : Réponses courtes. Pas de longs discours. Utilise des emojis 🏠, ✅, 🛡️ pour rendre le chat vivant.\n\n"

        "TON ET LANGAGE :\n"
        "* Professionnel mais complice. Vouvoiement obligatoire.\n"
        "* Comprends le Français, l'Anglais et le Wolof mélangé.\n\n"
        
        f"ANNONCES DISPONIBLES DANS LA BASE DE DONNÉES :\n{match_context}"
    )

    messages = [{"role": "system", "content": system_instruction}]
    if history:
        for msg in history[-6:]:
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
