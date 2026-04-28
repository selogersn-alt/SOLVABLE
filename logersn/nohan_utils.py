import requests
import json
import re
from django.conf import settings
from logersn.models import Property
from django.urls import reverse
from django.db.models import Q

def search_matching_properties(query):
    """
    Recherche avancée des biens immobiliers.
    Détecte les budgets (ex: 200 000) et les types de biens (ex: F3).
    """
    query = query.lower()
    search_query = Q(is_published=True, is_active=True)
    
    # 1. Détection du budget (ex: "moins de 200 000" ou "budget 300k")
    price_match = re.search(r'(\d+)\s*(?:000|k|fr|fcfa)', query)
    if price_match:
        price_val = int(price_match.group(1))
        if '000' not in price_match.group(0) and 'k' in query:
            price_val = price_val * 1000
        # On cherche des biens jusqu'à 15% au-dessus du budget
        search_query &= Q(price__lte=price_val * 1.15)

    # 2. Détection du type de bien / chambres (ex: F3, 3 chambres, studio)
    room_match = re.search(r'f(\d+)|(\d+)\s*chambre', query)
    if room_match:
        rooms = room_match.group(1) or room_match.group(2)
        search_query &= (Q(title__icontains=f"F{rooms}") | Q(description__icontains=f"F{rooms}") | Q(bedrooms=rooms))
    elif "studio" in query:
        search_query &= (Q(title__icontains="studio") | Q(description__icontains="studio"))

    # 3. Mots-clés généraux (quartiers, ville)
    keywords = query.split()
    for word in keywords:
        if len(word) > 3 and word not in ["louer", "cherche", "appartement", "maison", "chambre"]:
            search_query &= (Q(title__icontains=word) | Q(city__icontains=word) | Q(neighborhood__icontains=word) | Q(description__icontains=word))
    
    properties = Property.objects.filter(search_query).order_by('-is_boosted', '-created_at')[:3]
    
    results = []
    for p in properties:
        url = f"https://logersenegal.com{reverse('property_detail_slug', args=[p.slug])}"
        primary_img = p.images.filter(is_primary=True).first() or p.images.first()
        img_url = "https://logersenegal.com/static/images/placeholder-property.jpg"
        if primary_img and primary_img.image_url:
            img_url = primary_img.image_url.url
            if not img_url.startswith('http'):
                img_url = f"https://logersenegal.com{img_url}"

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
    Version optimisée pour Loger Sénégal avec expertise locale.
    """
    api_key = getattr(settings, 'GROQ_API_KEY', None)
    if not api_key:
        return "Nohan est en maintenance technique. Revenez dans un instant !"

    url = "https://api.groq.com/openai/v1/chat/completions"
    
    matches = search_matching_properties(prompt)
    match_context = ""
    if matches:
        match_context = "\nCONTEXTE : J'ai trouvé ces annonces réelles dans notre base : \n" + "\n".join(matches)

    system_instruction = (
        "NOM : Nohan. RÔLE : Expert Immobilier n°1 chez Loger Sénégal. "
        "TON : Chaleureux (Teranga), professionnel, réactif. "
        "EXPERTISE : Maîtrise parfaite des quartiers de Dakar (Almadies, Plateau, Ngor, Ouakam, Mermoz, VDN) "
        "et de la législation (Badge Solvable, caution, frais d'agence). "
        "RÈGLES : "
        "1. Priorise toujours les biens trouvés dans le CONTEXTE si présents. "
        "2. Si un utilisateur demande un bien, propose les cartes [PROPERTY_CARD:...] et demande son numéro pour une visite. "
        "3. Encourage l'obtention du 'Badge Solvable' pour rassurer les bailleurs. "
        "4. Ne mentionne jamais d'autres sites web. "
        "5. Reste bref et efficace. "
        f"{match_context}"
    )

    messages = [{"role": "system", "content": system_instruction}]
    if history:
        for msg in history[-5:]:
            messages.append({"role": "user" if msg['role'] == 'user' else "assistant", "content": msg['content']})
            
    messages.append({"role": "user", "content": prompt})

    payload = {
        "model": "llama-3.1-8b-instant",
        "messages": messages,
        "temperature": 0.5,
        "max_tokens": 800,
    }

    try:
        response = requests.post(url, json=payload, headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}, timeout=12)
        if response.status_code == 200:
            return response.json()['choices'][0]['message']['content']
        return "Désolé, je rencontre une petite perturbation. Comment puis-je vous aider ?"
    except Exception:
        return "Je suis en train de vérifier nos dernières annonces. Posez votre question à nouveau dans 5 secondes !"
