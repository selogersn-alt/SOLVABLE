import os
import django
import sys
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')
django.setup()
from logersn.models import Property
boosted = Property.objects.filter(boost_status='ACTIVE', is_published=True)
print(f"Total boosted: {boosted.count()}")
for p in boosted:
    print(f"- {p.title} (ID: {p.id})")
