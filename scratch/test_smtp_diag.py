import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def test_smtp():
    # Paramètres récupérés de la config (On teste la config actuelle)
    host = 'mail.logersenegal.com'
    port = 465
    user = 'solvable@logersenegal.com'
    password = '-P7GvVHJ2RmjnTG' # Le mot de passe vu dans votre settings.py
    
    print(f"Tentative de connexion à {host}:{port} avec l'utilisateur {user}...")
    
    msg = MIMEMultipart()
    msg['From'] = user
    msg['To'] = user # Envoi à soi-même pour test
    msg['Subject'] = "TEST SMTP LOGERSENEGAL"
    msg.attach(MIMEText("Ceci est un test de diagnostic pour l'envoi d'emails.", 'plain'))
    
    try:
        server = smtplib.SMTP_SSL(host, port, timeout=10)
        print("1. Connexion SSL établie au serveur.")
        
        server.login(user, password)
        print("2. Authentification réussie.")
        
        server.send_message(msg)
        print("3. E-mail de test envoyé avec succès !")
        
        server.quit()
        return True
    except smtplib.SMTPAuthenticationError:
        print("ERREUR : Authentification échouée. Le mot de passe ou l'utilisateur est incorrect.")
    except smtplib.SMTPConnectError:
        print("ERREUR : Impossible de se connecter au serveur (Firewall ou DNS ?).")
    except Exception as e:
        print(f"ERREUR INCONNUE : {type(e).__name__} - {e}")
    
    return False

if __name__ == "__main__":
    test_smtp()
