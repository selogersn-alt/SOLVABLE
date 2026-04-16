import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _launchWebLogin() async {
    final Uri url = Uri.parse('https://logersenegal.com/connexion/');
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF198754).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/img/logo.png', 
                width: 140, 
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.home_work, 
                  size: 80, 
                  color: Color(0xFF198754),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Bienvenue sur Loger Sénégal',
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
              'Pour une sécurité maximale et la validation de votre identité (NILS), la connexion et le dépôt d\'annonces se font désormais sur notre plateforme web certifiée.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16, 
                color: Colors.grey, 
                height: 1.5,
              ),
            ),
            const SizedBox(height: 50),
            
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _launchWebLogin,
                icon: const Icon(Icons.shield_outlined, color: Colors.white),
                label: const Text(
                  'SE CONNECTER EN SÉCURITÉ', 
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
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
            
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF198754)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Vous n'avez pas de compte ? S'inscrire", 
                style: TextStyle(
                  color: Color(0xFF198754), 
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Continuer en tant qu'invité", 
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
