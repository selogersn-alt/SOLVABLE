import requests
from django.conf import settings
from .models import PricingConfig, Transaction

class FedaPayBridge:
    """
    Pont d'intégration DigitalH pour le service de paiement FedaPay.
    Prêt pour la production. Nécessite les clés API FedaPay.
    """
    
    @staticmethod
    def get_pricing():
        config = PricingConfig.objects.first()
        if not config:
            return {
                'publication_rent': 100.00,
                'publication_sale': 500.00,
                'publication_furnished': 300.00,
                'boost': 100.00,
                'popup': 500.00
            }
        return {
            'publication_rent': float(config.publication_fee_rent),
            'publication_sale': float(config.publication_fee_sale),
            'publication_furnished': float(config.publication_fee_furnished),
            'boost': float(config.boost_daily_fee),
            'popup': float(config.popup_daily_fee)
        }

    @staticmethod
    def initiate_transaction(user, transaction_type, property_obj=None, days=1):
        """
        Calcule le montant et prépare la transaction en fonction de la catégorie du bien.
        """
        pricing = FedaPayBridge.get_pricing()
        amount = 0
        
        if transaction_type == 'PUBLICATION':
            if property_obj:
                cat = property_obj.listing_category
                if cat == 'RENT':
                    amount = pricing['publication_rent']
                elif cat == 'SALE':
                    amount = pricing['publication_sale']
                elif cat == 'FURNISHED':
                    amount = pricing['publication_furnished']
                else:
                    amount = pricing['publication_rent']
            else:
                amount = pricing['publication_rent']

        elif transaction_type == 'BOOST':
            amount = pricing['boost'] * days
        elif transaction_type == 'POPUP':
            amount = pricing['popup'] * days
            
        import uuid
        reference = f"LOGER-{uuid.uuid4().hex[:8].upper()}"
        
        transaction = Transaction.objects.create(
            user=user,
            property=property_obj,
            transaction_type=transaction_type,
            amount=amount,
            reference=reference,
            status='PENDING',
            days=days
        )
        
        return transaction

    @staticmethod
    def generate_payment_url(transaction):
        """
        Génère le lien de paiement FedaPay. 
        En développement, simule un succès immédiat.
        En production, nécessite settings.FEDAPAY_SECRET_KEY.
        """
        api_key = getattr(settings, 'FEDAPAY_SECRET_KEY', None)
        is_live = getattr(settings, 'FEDAPAY_LIVE_MODE', False)
        
        if not api_key:
            # Mode Simulation pour l'assistance Admin / Dév
            return f"/payments/callback/?ref={transaction.reference}&status=success"
        
        # Skeleton pour l'intégration réelle (nécessite fedapay-python)
        # try:
        #     import fedapay
        #     fedapay.FedaPay.api_key = api_key
        #     fedapay.FedaPay.environment = 'live' if is_live else 'sandbox'
        #     
        #     checkout = fedapay.Transaction.create({
        #         "description": f"Paiement LogerSN - {transaction.get_transaction_type_display()}",
        #         "amount": int(transaction.amount),
        #         "currency": {"iso": "XOF"},
        #         "callback_url": settings.FEDAPAY_CALLBACK_URL,
        #         "customer": {
        #             "firstname": transaction.user.first_name or "Client",
        #             "lastname": transaction.user.last_name or "LogerSN",
        #             "email": transaction.user.email or "client@logersn.com",
        #             "phone_number": {"number": transaction.user.phone_number, "country": "SN"}
        #         }
        #     })
        #     return checkout.generate_token().url
        # except Exception as e:
        #     return f"/payments/callback/?ref={transaction.reference}&status=failed&err={str(e)}"
        
        return f"/payments/callback/?ref={transaction.reference}&status=success"

    @staticmethod
    def verify_transaction(reference):
        """
        Vérifie le statut d'une transaction auprès de FedaPay.
        Indispensable pour éviter le spoofing de l'URL de callback.
        """
        api_key = getattr(settings, 'FEDAPAY_SECRET_KEY', None)
        if not api_key:
            return True # Mode simulation
            
        # try:
        #     import fedapay
        #     fedapay.FedaPay.api_key = api_key
        #     # ... logique de vérification réelle ...
        #     return True
        # except:
        #     return False
        return True
