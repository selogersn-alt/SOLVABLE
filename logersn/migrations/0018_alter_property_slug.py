from django.db import migrations, models

class Migration(migrations.Migration):

    dependencies = [
        ('logersn', '0017_alter_favorite_id_alter_pricingconfig_id'),
    ]

    operations = [
        migrations.AddField(
            model_name='property',
            name='slug',
            field=models.SlugField(blank=True, max_length=255, null=True, unique=True),
        ),
    ]
