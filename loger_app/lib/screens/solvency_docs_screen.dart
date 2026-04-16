import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SolvencyDocsScreen extends StatelessWidget {
  const SolvencyDocsScreen({super.key});

  Future<void> _launchWebSolvencyDocs() async {
    final Uri url = Uri.parse('https://logersenegal.com/locataire/solvabilite/soumettre/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Documents de Solvabilité',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
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
                child: const Icon(Icons.security_rounded, size: 60, color: Color(0xFF198754)),
              ),
              const SizedBox(height: 40),
              const Text(
                'Certification de Solvabilité',
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
                'Pour garantir la confidentialité de vos données sensibles et obtenir votre certification NILS, le dépôt de documents se fait sur notre serveur sécurisé web.',
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
                  onPressed: _launchWebSolvencyDocs,
                  icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
                  label: const Text(
                    'DÉPOSER MES DOCUMENTS SUR LE WEB', 
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 14,
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
                  'Retour à l\'application', 
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
