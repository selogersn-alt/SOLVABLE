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
        # On cherche des biens jusqu'à 20% au-dessus du budget pour plus de flexibilité
        search_query &= Q(price__lte=price_val * 1.20)

    # 2. Détection du type de bien / chambres (ex: F3, 3 chambres, studio)
    room_match = re.search(r'f(\d+)|(\d+)\s*chambre', query)
    if room_match:
        rooms = room_match.group(1) or room_match.group(2)
        search_query &= (Q(title__icontains=f"F{rooms}") | Q(description__icontains=f"F{rooms}") | Q(bedrooms=rooms))
    elif "studio" in query:
        search_query &= (Q(title__icontains="studio") | Q(description__icontains="studio"))

    # 3. Mots-clés généraux (quartiers, ville) - Recherche OR plus souple pour les quartiers
    keywords = query.split()
    geo_query = Q()
    has_geo = False
    for word in keywords:
        if len(word) > 3 and word not in ["louer", "cherche", "appartement", "maison", "chambre", "vendre", "location"]:
            geo_query |= (Q(title__icontains=word) | Q(city__icontains=word) | Q(neighborhood__icontains=word) | Q(description__icontains=word))
            has_geo = True
    
    if has_geo:
        search_query &= geo_query
    
    properties = Property.objects.filter(search_query).order_by('-is_boosted', '-created_at')[:3]
    
    # Si aucun résultat avec les critères stricts, on prend les derniers biens publiés du même type
    if not properties.exists():
        fallback_query = Q(is_published=True, is_active=True)
        if "studio" in query:
            fallback_query &= Q(title__icontains="studio")
        properties = Property.objects.filter(fallback_query).order_by('-created_at')[:2]

    results = []
    for p in properties:
        try:
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
        except:
            continue
    
    return results

def call_gemini_api(prompt, history=None):
    """
    Version optimisée pour éviter les hallucinations et garantir des liens réels.
    """
    api_key = getattr(settings, 'GROQ_API_KEY', None)
    if not api_key:
        return "Nohan est en maintenance technique."

    url = "https://api.groq.com/openai/v1/chat/completions"
    
    matches = search_matching_properties(prompt)
    match_context = ""
    if matches:
        match_context = "\nANNONCES RÉELLES DISPONIBLES (Utilise uniquement celles-ci) : \n" + "\n".join(matches)
    else:
        match_context = "\nAUCUNE ANNONCE CORRESPONDANTE TROUVÉE. Ne propose pas de liens ou de prix fictifs. Demande plus de précisions ou suggère de regarder nos nouveautés."

    system_instruction = (
        "NOM : Nohan. RÔLE : Expert Immobilier n°1 chez Loger Sénégal. "
        "TON : Chaleureux (Teranga), professionnel, réactif. "
        "EXPERTISE : Maîtrise parfaite des quartiers de Dakar (Almadies, Plateau, Ngor, Ouakam, Mermoz, VDN). "
        "LÉGISLATION : Maîtrise du Badge Solvable, caution, frais d'agence. "
        "CONTACT OFFICIEL : Indique toujours le 76 444 33 13 pour toute assistance. "
        "RÈGLES ABSOLUES : "
        "1. Ne jamais inventer d'annonces, de prix ou de liens. "
        "2. Si le contexte contient des annonces, présente-les avec les tags [PROPERTY_CARD:...]. "
        "3. Encourage l'obtention du 'Badge Solvable'. "
        "4. Capture le numéro de téléphone de l'utilisateur pour les visites. "
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
        "temperature": 0.2, 
        "max_tokens": 800,
    }

    try:
        response = requests.post(url, json=payload, headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}, timeout=12)
        if response.status_code == 200:
            return response.json()['choices'][0]['message']['content']
        return "Désolé, je rencontre une petite perturbation technique."
    except Exception:
        return "Un instant, je synchronise mes données immobilières..."
