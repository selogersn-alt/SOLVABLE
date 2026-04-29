"""
URL configuration for core project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.shortcuts import redirect
from django.urls import path, include
from django.views.generic import TemplateView
from django.contrib.sitemaps.views import sitemap
from logersn.sitemaps import StaticViewSitemap, PropertySitemap
from solvable.views import (
    filiation_details_view, report_incident_view, update_incident_status_view,
    record_payment_view, mediation_room_view, download_receipt_view,
    apply_to_property_view, start_filiation_view, approve_filiation_view,
    terminate_filiation_view, update_application_status_view, delete_application_view,
    create_filiation_pro_view
)
from rest_framework.routers import DefaultRouter
# from logersn.api import PropertyViewSet, PropertyImageViewSet, ProfessionalsViewSet
# from chat.api import ConversationViewSet
# from users.api import SolvencyDocumentViewSet

from articles.views import BlogPostViewSet

from solvable.views import ProfessionalFraudReportViewSet

# API Router configuration
router = DefaultRouter()
router.register(r'blog', BlogPostViewSet, basename='api-blog')
router.register(r'blacklist', ProfessionalFraudReportViewSet, basename='api-blacklist')
# router.register(r'properties', PropertyViewSet, basename='api-property')
# router.register(r'property-images', PropertyImageViewSet, basename='api-property-image')
# router.register(r'professionals', ProfessionalsViewSet, basename='api-professional')
# router.register(r'conversations', ConversationViewSet, basename='api-conversation')
# router.register(r'solvency-documents', SolvencyDocumentViewSet, basename='api-solvency-doc')


sitemaps = {
    'static': StaticViewSitemap,
    'properties': PropertySitemap,
}
from .views import (
    home_view, properties_list_view, property_detail_view, 
    dashboard_view, create_property_view, send_message_view,
    initiate_chat_view, start_support_view, verify_phone_view,
    kyc_submit_view, nils_search_view, create_filiation_view,
    contest_item_view, about_view, verified_professionals_view,
    generate_lease_pdf_view,
    public_profile_view, update_profile_view,
    edit_property_view, delete_property_view,  # Gestion pro
    create_booking_view, schedule_visit_view, # Réservations & Visites
    initiate_payment_view, checkout_payment_view, payment_callback_view, payment_success_view, 
    cgu_view, privacy_view, toggle_favorite_view, chat_poll_view, initiate_direct_chat_view,
    report_pro_fraud_view, fraud_list_view, submit_solvency_docs_view,
    guide_locataires_view, guide_bailleurs_view, guide_agences_view, guide_courtiers_view,
    increment_click_view, duplicate_property_view, seo_directory_view,
    switch_to_pro_view, nohan_chat_view
)
from users.views import (
    login_view, register_view, logout_view, 
    password_recovery_view, password_reset_confirm_view, admin_generate_reset_link
)
from logersn.seo_views import seo_search_view
from ads.views import ads_txt_view  # Certification Google
from .admin_views import admin_statistics_view, admin_marketing_email_view
from django.conf.urls import handler404, handler500

handler404 = 'logersenegal.views.custom_404_view'
handler500 = 'logersenegal.views.custom_500_view'

urlpatterns = [
    path('', home_view, name='home'),
    path('a-propos/', about_view, name='about'),
    path('professionnels/', verified_professionals_view, name='professionals_list'),
    path('agences/', lambda r: redirect('professionals_list')), # Aliasing legacy URL from Menu

    path('admin/statistiques/', admin_statistics_view, name='admin_statistics'), # Custom Admin Route
    path('admin/campagne-email/', admin_marketing_email_view, name='admin_marketing_email'),
    
    # API Routes
    path('api/', include(router.urls)),
    
    path('admin/', admin.site.urls),
    path('api/users/', include('users.urls')),
    path('api/logersn/', include('logersn.urls')),
    path('api/solvable/', include('solvable.urls')),
    path('annonces/nouvelle/', create_property_view, name='create_property'),
    path('annonces/', properties_list_view, name='properties_list'),
    path('annonces/<uuid:property_id>/', property_detail_view, name='property_detail'),
    path('annonces/<slug:slug>/', property_detail_view, name='property_detail_slug'),
    path('annonces/<uuid:property_id>/click/', increment_click_view, name='increment_click'),
    path('annonces/<uuid:property_id>/modifier/', edit_property_view, name='edit_property'),
    path('annonces/<uuid:property_id>/dupliquer/', duplicate_property_view, name='duplicate_property'),
    path('annonces/<uuid:property_id>/supprimer/', delete_property_view, name='delete_property'),
    
    # Certification Ads (Google AdSense)
    path('ads.txt', ads_txt_view, name='ads_txt'),
    path('annonces/<uuid:property_id>/postuler/', apply_to_property_view, name='apply_to_property'),
    path('profil/verification-telephonique/', verify_phone_view, name='verify_phone'),
    path('mon-compte/', dashboard_view, name='dashboard'),
    path('chat/start/<uuid:property_id>/', initiate_chat_view, name='initiate-chat'),
    path('chat/support/', start_support_view, name='support-chat'),
    path('chat/send/<uuid:conversation_id>/', send_message_view, name='send-message'),
    path('chat/send/', send_message_view, name='send-message-new'),
    path('profil/kyc/soumettre/', kyc_submit_view, name='kyc_submit'),
    path('bailleur/recherche-nils/', nils_search_view, name='nils_search'),
    path('bailleur/filiation/nouveau/', create_filiation_view, name='create_filiation'),
    path('bailleur/incident/declarer/', report_incident_view, name='report_incident'),
    path('bailleur/paiements/nouveau/', record_payment_view, name='record_payment'),
    path('contrat/<uuid:filiation_id>/', filiation_details_view, name='filiation_details'),
    path('contrat/nouveau-manuel/', create_filiation_pro_view, name='create_filiation_pro'),
    path('contrat/paiement/<uuid:payment_id>/quittance/', download_receipt_view, name='download_receipt'),
    path('contrat/contester/<str:item_type>/<uuid:item_id>/', contest_item_view, name='contest_item'),
    path('contrat/mediation/<str:item_type>/<uuid:item_id>/', mediation_room_view, name='mediation_room'),
    path('audit/mediation/update-status/', update_incident_status_view, name='update_incident_status'),
    path('contrat/demarrer/<uuid:application_id>/', start_filiation_view, name='start_filiation'),
    path('contrat/approuver/<uuid:filiation_id>/', approve_filiation_view, name='approve_filiation'),
    path('contrat/resilier/<uuid:filiation_id>/', terminate_filiation_view, name='terminate_filiation'),
    path('contrat/<uuid:filiation_id>/pdf/', generate_lease_pdf_view, name='generate_lease_pdf'),
    path('connexion/', login_view, name='login'),
    path('inscription/', register_view, name='register'),
    path('deconnexion/', logout_view, name='logout'),
    path('application/<uuid:application_id>/update/', update_application_status_view, name='update_application_status'),
    path('application/<uuid:application_id>/supprimer/', delete_application_view, name='delete_application'),
    path('verifier-telephone/', verify_phone_view, name='verify_phone'),
    path('profile/update/', update_profile_view, name='update_profile'),
    path('profile/switch-pro/', switch_to_pro_view, name='switch_to_pro'),
    path('nohan-chat/', nohan_chat_view, name='nohan_chat'),
    path('profil-public/<uuid:user_id>/', public_profile_view, name='public_profile'),
    path('p/<slug:slug>/', public_profile_view, name='public_profile_slug'),
    path('mon-compte/profil/modifier/', update_profile_view, name='update_profile'),
    path('recuperation-compte/', password_recovery_view, name='password_recovery'),
    path('reinitialiser-mot-de-passe/<uidb64>/<token>/', password_reset_confirm_view, name='password_reset_confirm_public'),
    path('admin/generer-lien-reset/<uuid:user_id>/', admin_generate_reset_link, name='admin_generate_reset_link'),

    # Moteur de Paiement DigitalH
    path('paiement/configurer/<uuid:property_id>/<str:payment_type>/', checkout_payment_view, name='checkout_payment'),
    path('paiement/initier/<uuid:property_id>/<str:payment_type>/', initiate_payment_view, name='initiate_payment'),
    path('paiement/callback/', payment_callback_view, name='payment_callback'),
    path('payments/callback/', payment_callback_view), # Alias international pour éviter les 404
    path('paiement/succes/<uuid:transaction_id>/', payment_success_view, name='payment_success'),
    
    # Nouvelles Routes UX & Légal
    path('cgu/', cgu_view, name='cgu'),
    path('confidentialite/', privacy_view, name='privacy'),
    path('favori/basculer/<uuid:property_id>/', toggle_favorite_view, name='toggle_favorite'),
    path('chat/poll/<uuid:conversation_id>/', chat_poll_view, name='chat-poll'),
    path('chat/direct/<uuid:user_id>/', initiate_direct_chat_view, name='initiate-direct-chat'),
    
    # Nouvelles Routes Signalement & Solvabilité
    path('signalement/professionnel/nouveau/', report_pro_fraud_view, name='report_pro_fraud'),
    path('liste-noire-pros/', fraud_list_view, name='fraud_list'),
    path('locataire/solvabilite/soumettre/', submit_solvency_docs_view, name='submit_solvency_docs'),
    
    # Guides d'utilisation
    path('guide/locataires/', guide_locataires_view, name='guide_locataires'),
    path('guide/bailleurs/', guide_bailleurs_view, name='guide_bailleurs'),
    path('guide/agences/', guide_agences_view, name='guide_agences'),
    path('guide/courtiers/', guide_courtiers_view, name='guide_courtiers'),
    
    # Sitemap & SEO
    path('blog/', include('articles.urls')),
    path('sitemap.xml', sitemap, {'sitemaps': sitemaps}, name='django.contrib.sitemaps.views.sitemap'),
    path('robots.txt', TemplateView.as_view(template_name="robots.txt", content_type="text/plain")),

    # ---- PWA (Progressive Web App) ----
    path('manifest.json', TemplateView.as_view(
        template_name='pwa/manifest.json',
        content_type='application/json'
    ), name='pwa-manifest'),
    path('sw.js', TemplateView.as_view(
        template_name='pwa/sw.js',
        content_type='application/javascript'
    ), name='pwa-sw'),

    path('annonces/<uuid:property_id>/reserver/', create_booking_view, name='create_booking'),
    path('annonces/<uuid:property_id>/visiter/', schedule_visit_view, name='schedule_visit'),

    # --- RECHERCHE SEO DYNAMIQUE ---
    path('recherche/<str:type_slug>/', seo_search_view, name='seo_search'),
    path('seo-directory/', seo_directory_view, name='seo_directory'),
    path('recherche/<slug:type_slug>/<slug:city_slug>/', seo_search_view, name='seo_search_city'),
    path('recherche/<str:type_slug>/<str:city_slug>/<str:neighborhood_slug>/', seo_search_view, name='seo_search_neighborhood'),
]
from django.conf import settings
from django.conf.urls.static import static

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
