import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import 'solvency_docs_screen.dart';
import 'legal_screen.dart';
import 'help_screen.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'add_property_screen.dart';
import 'blog_screen.dart';
import 'nohan_chat_screen.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifyNewAnnonce = true;
  bool _autoUpdateContent = true;
  bool _useBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notifyNewAnnonce = prefs.getBool('notify_new_annonce') ?? true;
        _autoUpdateContent = prefs.getBool('auto_update_content') ?? true;
        _useBiometrics = prefs.getBool('use_biometrics') ?? false;
      });
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == 'notify_new_annonce') _notifyNewAnnonce = value;
      if (key == 'auto_update_content') _autoUpdateContent = value;
      if (key == 'use_biometrics') _useBiometrics = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF062B1A))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          if (user != null) ...[
            FadeInDown(child: _buildProfile(user)),
            const SizedBox(height: 24),
            FadeInDown(delay: const Duration(milliseconds: 200), child: _buildNILSCard(user)),
          ] else ...[
             FadeInDown(child: _buildAuthPrompt()),
          ],
          
          const SizedBox(height: 32),
          _buildSectionHeader('Mon Compte'),
          _buildNativeButton('Modifier mon Profil', Icons.person_outline_rounded, () {
            if (user != null) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(user: user)));
            }
          }),
          _buildNativeButton('Vérification NILS', Icons.verified_user_rounded, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SolvencyDocsScreen()));
          }),
          _buildNativeButton('Ajouter un bien', Icons.add_business_rounded, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPropertyScreen()));
          }),

          const SizedBox(height: 32),
          _buildSectionHeader('Sécurité'),
          _buildToggle(
            'Authentification Biométrique',
            'Utiliser Fingerprint/FaceID au démarrage',
            _useBiometrics,
            Icons.fingerprint_rounded,
            (val) => _updateSetting('use_biometrics', val),
          ),
          
          const SizedBox(height: 32),
          _buildSectionHeader('Notifications & Flux'),
          _buildToggle(
            'Alertes Nouvelles Annonces',
            'Savoir quand un bien est validé',
            _notifyNewAnnonce,
            Icons.notifications_active_rounded,
            (val) => _updateSetting('notify_new_annonce', val),
          ),
          const SizedBox(height: 12),
          _buildToggle(
            'Mise à jour Automatique',
            'Actualiser le contenu toutes les 45s',
            _autoUpdateContent,
            Icons.sync_rounded,
            (val) => _updateSetting('auto_update_content', val),
          ),
          
          const SizedBox(height: 32),
          _buildSectionHeader('Apparence'),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, mode, _) {
              return _buildToggle(
                'Mode Sombre',
                'Activer le thème Mystic & Green',
                mode == ThemeMode.dark,
                Icons.dark_mode_rounded,
                (val) {
                  themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                },
              );
            },
          ),
          
          const SizedBox(height: 32),
          _buildSectionHeader('Support & Légal'),
          Container(
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.psychology_outlined, color: Color(0xFFF5C42F)),
                  title: const Text('Assistant Nohan AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Discutez avec notre IA immobilière', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NohanChatScreen())),
                ),
                const Divider(height: 1, indent: 60),
                ListTile(
                  leading: const Icon(Icons.article_outlined, color: Color(0xFF0B4629)),
                  title: const Text('Guides & Articles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Conseils immobiliers au Sénégal', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BlogScreen())),
                ),
                const Divider(height: 1, indent: 60),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF0B4629)),
                  title: const Text('Centre d\'aide & FAQ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Comprendre le fonctionnement et la sécurité', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen())),
                ),
                const Divider(height: 1, indent: 60),
                ListTile(
                  leading: const Icon(Icons.gavel_rounded, color: Colors.blueGrey),
                  title: const Text('Mentions Légales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Conditions d’utilisation de Loger Sénégal', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LegalScreen())),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                Image.asset('assets/img/logo.png', height: 30, color: Colors.blueGrey.withValues(alpha: 0.2)),
                const SizedBox(height: 12),
                const Text("LOGER SÉNÉGAL ™", style: TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                const Text("Version 2.12", style: TextStyle(color: Colors.blueGrey, fontSize: 10)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('https://digitalh.net')),
                  child: const Text(
                    "Conçu par Digitalh",
                    style: TextStyle(color: Color(0xFF0B4629), fontSize: 11, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
          if (user != null) ...[
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: ElevatedButton(
                onPressed: () async {
                  await AuthService().logout();
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B4629),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: const Color(0xFF0B4629).withValues(alpha: 0.3),
                ),
                child: const Text('DÉCONNEXION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ),
            ),
          ],
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildProfile(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: const Color(0xFF0B4629).withValues(alpha: 0.1),
            child: Text(user.firstName[0], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0B4629))),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user.firstName} ${user.lastName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text(user.phoneNumber, style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthPrompt() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF062B1A), borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          const Icon(Icons.lock_rounded, color: Colors.amber, size: 40),
          const SizedBox(height: 16),
          const Text('Accès Sécurisé Requis', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Connectez-vous pour profiter de toutes les fonctionnalités.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const LoginScreen())
              );
              if (result == true) {
                setState(() {}); // Refresh to show profile
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B4629), 
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('SE CONNECTER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildNILSCard(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0B4629), Color(0xFF062B1A)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, color: Colors.amber, size: 30),
          const SizedBox(width: 16),
          Expanded(child: Text(user.isVerified ? 'STATUT NILS : VÉRIFIÉ' : 'STATUT NILS : EN ATTENTE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          if (!user.isVerified)
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SolvencyDocsScreen())), 
              child: const Text('SÉCURISER', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 1.5));
  }

  Widget _buildToggle(String title, String sub, bool val, IconData icon, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0B4629)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11)),
        trailing: Switch.adaptive(value: val, activeTrackColor: const Color(0xFF0B4629), onChanged: onChanged),
      ),
    );
  }

  Widget _buildNativeButton(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0B4629)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
