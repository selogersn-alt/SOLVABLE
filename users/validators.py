import re
from django.core.exceptions import ValidationError
from django.utils.translation import gettext as _

class ComplexPasswordValidator:
    """
    Validates that a password contains at least one uppercase letter, 
    one lowercase letter, one digit, and one special character.
    Minimum length of 8 is usually handled by Django's MinimumLengthValidator.
    """
    def validate(self, password, user=None):
        if not re.findall(r'[A-Z]', password):
            raise ValidationError(
                _("Le mot de passe doit contenir au moins une lettre majuscule."),
                code='password_no_upper',
            )
        if not re.findall(r'[a-z]', password):
            raise ValidationError(
                _("Le mot de passe doit contenir au moins une lettre minuscule."),
                code='password_no_lower',
            )
        if not re.findall(r'\d', password):
            raise ValidationError(
                _("Le mot de passe doit contenir au moins un chiffre."),
                code='password_no_digit',
            )
        if not re.findall(r'[^A-Za-z0-9]', password):
            raise ValidationError(
                _("Le mot de passe doit contenir au moins un caractère spécial."),
                code='password_no_special',
            )

    def get_help_text(self):
        return _(
            "Votre mot de passe doit contenir au moins : une majuscule, "
            "une minuscule, un chiffre et un caractère spécial."
        )
