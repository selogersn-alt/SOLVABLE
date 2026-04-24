from django.db import migrations, models

class Migration(migrations.Migration):
    initial = True
    dependencies = [
        ('users', '0001_initial'),
    ]
    operations = [
        migrations.CreateModel(
            name='BlogPost',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=200, verbose_name='Titre')),
                ('slug', models.SlugField(max_length=200, unique=True)),
                ('content', models.TextField(verbose_name='Contenu')),
                ('image', models.ImageField(upload_to='blog/', verbose_name='Image de couverture')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('is_published', models.BooleanField(default=True, verbose_name='Publié')),
                ('meta_description', models.CharField(blank=True, max_length=160, verbose_name='Meta Description')),
                ('author', models.ForeignKey(on_delete=models.deletion.CASCADE, to='users.user', verbose_name='Auteur')),
            ],
            options={
                'verbose_name': 'Article de Blog',
                'verbose_name_plural': 'Articles de Blog',
                'ordering': ['-created_at'],
            },
        ),
    ]
