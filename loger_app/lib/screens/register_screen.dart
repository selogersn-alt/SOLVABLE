import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  Future<void> _launchWebRegister() async {
    final Uri url = Uri.parse('https://logersenegal.com/inscription/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF198754).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_outlined, size: 60, color: Color(0xFF198754)),
              ),
              const SizedBox(height: 40),
              const Text(
                'Créer un compte certifié',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF198754),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Pour garantir la sécurité de vos données et la validation de votre identité (Pass NILS), la création de compte se fait désormais exclusivement sur notre plateforme web sécurisée.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16, 
                  color: Colors.grey, 
                  height: 1.5
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _launchWebRegister,
                  icon: const Icon(Icons.verified_user_outlined, color: Colors.white),
                  label: const Text(
                    'S\'INSCRIRE SUR LE WEB', 
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF198754),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 4,
                    shadowColor: const Color(0xFF198754).withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Retour à la page de connexion', 
                  style: TextStyle(
                    color: Colors.grey, 
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
