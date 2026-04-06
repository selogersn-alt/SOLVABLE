from django.http import HttpResponse
from .models import AdsConfig

def ads_txt_view(request):
    """Serve the ads.txt file dynamically from the database."""
    config = AdsConfig.objects.first()
    content = config.ads_txt_content if config else ""
    return HttpResponse(content, content_type="text/plain")
