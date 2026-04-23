import openpyxl
from openpyxl.styles import Font, Alignment
from django.shortcuts import render
from django.contrib.admin.views.decorators import staff_member_required
from django.http import HttpResponse
from django.db.models import Count, Q
from users.models import User, KYCProfile
from solvable.models import RentalFiliation, IncidentReport, PaymentHistory
import datetime
from django.db.models import Sum
from django.utils import timezone
from logersn.models import Property, Transaction

@staff_member_required
@staff_member_required
def admin_statistics_view(request):
    today = timezone.now()
    
    # Récupération des filtres
    city_filter = request.GET.get('city')
    type_filter = request.GET.get('type')
    
    # Base Querysets
    properties_qs = Property.objects.all()
    transactions_qs = Transaction.objects.filter(status='SUCCESS')
    
    if city_filter:
        properties_qs = properties_qs.filter(city=city_filter)
        transactions_qs = transactions_qs.filter(property__city=city_filter)
    if type_filter:
        properties_qs = properties_qs.filter(property_type=type_filter)
        transactions_qs = transactions_qs.filter(property__property_type=type_filter)

    try:
        # 1. User Stats (Non filtrés par ville/type de bien immo car globaux)
        total_users = User.objects.count()
        users_by_role = User.objects.values('role').annotate(count=Count('id'))
        verified_pros = User.objects.filter(is_verified_pro=True).count()
        kyc_pending = KYCProfile.objects.filter(vision_api_status='PENDING').count()

        # 2. Property Stats (Filtrés)
        total_properties = properties_qs.count()
        published_properties = properties_qs.filter(is_published=True).count()
        removed_properties = properties_qs.filter(is_active=False).count()
        
        # 3. Rental Stats (Filtrés)
        filiations_qs = RentalFiliation.objects.all()
        if city_filter: filiations_qs = filiations_qs.filter(property__city=city_filter)
        if type_filter: filiations_qs = filiations_qs.filter(property__property_type=type_filter)
        
        total_filiations = filiations_qs.count()
        active_filiations = filiations_qs.filter(status='ACTIVE').count()
        
        properties_occupied = filiations_qs.filter(status='ACTIVE').values('property').distinct().count()
        occupancy_rate = (properties_occupied / total_properties * 100) if total_properties > 0 else 0

        # 4. Incident Stats (Filtrés)
        incidents_qs = IncidentReport.objects.all()
        if city_filter: incidents_qs = incidents_qs.filter(filiation__property__city=city_filter)
        if type_filter: incidents_qs = incidents_qs.filter(filiation__property__property_type=type_filter)
        
        total_incidents = incidents_qs.count()
        contested_incidents = incidents_qs.filter(is_contested=True).count()
        resolved_incidents = incidents_qs.filter(status='RESOLVED').count()
        
        contestation_rate = (contested_incidents / total_incidents * 100) if total_incidents > 0 else 0
        resolution_rate = (resolved_incidents / total_incidents * 100) if total_incidents > 0 else 0

        # 5. Financial Stats (DigitalH PÉAGE - Filtrés)
        total_revenue = transactions_qs.aggregate(total=Sum('amount'))['total'] or 0
        revenue_publication = transactions_qs.filter(transaction_type='PUBLICATION').aggregate(total=Sum('amount'))['total'] or 0
        revenue_boost = transactions_qs.filter(transaction_type='BOOST').aggregate(total=Sum('amount'))['total'] or 0
        revenue_popup = transactions_qs.filter(transaction_type='POPUP').aggregate(total=Sum('amount'))['total'] or 0
        
        # Accounting Granularities
        start_of_day = today.replace(hour=0, minute=0, second=0, microsecond=0)
        start_of_week = today - datetime.timedelta(days=today.weekday())
        start_of_month = today.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        
        revenue_today = transactions_qs.filter(created_at__gte=start_of_day).aggregate(total=Sum('amount'))['total'] or 0
        revenue_week = transactions_qs.filter(created_at__gte=start_of_week).aggregate(total=Sum('amount'))['total'] or 0
        revenue_month = transactions_qs.filter(created_at__gte=start_of_month).aggregate(total=Sum('amount'))['total'] or 0

        # 6. Time Series (Last 6 months)
        months = []
        user_growth = []
        contract_growth = []
        for i in range(5, -1, -1):
            month_start = (today - datetime.timedelta(days=i*30)).replace(day=1)
            months.append(month_start.strftime('%B'))
            user_growth.append(User.objects.filter(date_joined__lte=month_start + datetime.timedelta(days=30)).count())
            contract_growth.append(filiations_qs.filter(created_at__lte=month_start + datetime.timedelta(days=30)).count())

    except Exception as e:
        import logging
        logging.error(f"Admin Statistics Error: {e}")
        # Fallback values
        total_users = verified_pros = kyc_pending = total_properties = published_properties = removed_properties = 0
        total_filiations = active_filiations = occupancy_rate = 0
        total_incidents = contested_incidents = resolved_incidents = contestation_rate = resolution_rate = 0
        total_revenue = revenue_publication = revenue_boost = revenue_popup = revenue_today = revenue_week = revenue_month = 0
        months = user_growth = contract_growth = []
        users_by_role = []

    # Handle Excel Export
    if request.GET.get('export') == 'excel':
        wb = openpyxl.Workbook()
        ws = wb.active
        ws.title = "Stats LogerSN"
        ws.append(["Rapport Statistiques LogerSN", f"Généré le {today.strftime('%d/%m/%Y %H:%M')}"])
        ws.append(["Filtre Ville:", city_filter or "Toutes", "Filtre Type:", type_filter or "Tous"])
        ws.append([])
        
        # Sections
        ws.append(["COMPTABILITÉ (REVENUS)", "VALEUR (FCFA)"])
        ws.append(["Total Historique", total_revenue])
        ws.append(["Ce Mois", revenue_month])
        ws.append(["Cette Semaine", revenue_week])
        ws.append(["Aujourd'hui", revenue_today])
        ws.append([])
        ws.append(["ACTIVITÉ IMMOBILIÈRE", "NOMBRE"])
        ws.append(["Total Annonces", total_properties])
        ws.append(["En Ligne", published_properties])
        ws.append(["Retirées/Inactives", removed_properties])
        ws.append(["Contrats Actifs", active_filiations])
        ws.append([])
        ws.append(["UTILISATEURS", "NOMBRE"])
        ws.append(["Total Inscrits", total_users])
        ws.append(["Pros Vérifiés", verified_pros])

        response = HttpResponse(content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        response['Content-Disposition'] = f'attachment; filename=stats_logersn_{today.strftime("%Y%m%d")}.xlsx'
        wb.save(response)
        return response

    # 8. User Explorer (Filtré)
    from users.models import User
    role_filter = request.GET.get('role')
    users_qs = User.objects.all().order_by('-date_joined')
    if role_filter:
        users_qs = users_qs.filter(role=role_filter)
    
    users_list = users_qs[:50] # Top 50 recent
    
    context = {
        'total_users': total_users,
        'users_by_role': list(users_by_role),
        'verified_pros': verified_pros,
        'kyc_pending': kyc_pending,
        'total_properties': total_properties,
        'published_properties': published_properties,
        'removed_properties': removed_properties,
        'total_filiations': total_filiations,
        'active_filiations': active_filiations,
        'occupancy_rate': round(occupancy_rate, 1),
        'total_revenue': total_revenue,
        'revenue_publication': revenue_publication,
        'revenue_boost': revenue_boost,
        'revenue_popup': revenue_popup,
        'revenue_today': revenue_today,
        'revenue_week': revenue_week,
        'revenue_month': revenue_month,
        'labels_months': months,
        'data_users': user_growth,
        'data_contracts': contract_growth,
        'city_choices': CITY_CHOICES,
        'type_choices': PROPERTY_TYPE_CHOICES,
        'current_city': city_filter,
        'current_type': type_filter,
        'users_list': users_list,
        'current_role': role_filter,
        'role_choices': User.Role.choices,
    }
    
    return render(request, 'admin/statistics.html', context)

@staff_member_required
def admin_marketing_email_view(request):
    from django.shortcuts import redirect
    from django.contrib import messages
    from django.core.mail import EmailMultiAlternatives
    from django.conf import settings
    from users.models import User

    user_ids = request.session.get('marketing_user_ids', [])
    if not user_ids:
        messages.error(request, "Aucun utilisateur sélectionné pour la campagne.")
        return redirect('admin:users_user_changelist')
    
    users = User.objects.filter(id__in=user_ids)
    
    if request.method == 'POST':
        subject = request.POST.get('subject')
        message_content = request.POST.get('message')
        is_html = request.POST.get('is_html') == 'on'
        
        count = 0
        for user in users:
            if user.email:
                # On remplace les tags [NOM], [PRENOM] si présents
                personalized_message = message_content.replace('[PRENOM]', user.first_name).replace('[NOM]', user.last_name)
                
                msg = EmailMultiAlternatives(
                    subject,
                    personalized_message if not is_html else "Contenu HTML : veuillez utiliser un client mail moderne.",
                    settings.DEFAULT_FROM_EMAIL,
                    [user.email],
                    bcc=['solvable@logersenegal.com']
                )
                if is_html:
                    msg.attach_alternative(personalized_message, "text/html")
                
                try:
                    msg.send()
                    count += 1
                except:
                    pass
        
        messages.success(request, f"🚀 Campagne terminée : {count} e-mails envoyés avec succès.")
        if 'marketing_user_ids' in request.session:
            del request.session['marketing_user_ids']
        return redirect('admin:users_user_changelist')
        
    return render(request, 'admin/marketing_email.html', {
        'users': users,
        'count': users.count()
    })
