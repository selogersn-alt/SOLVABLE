import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final success = await AuthService().login(
      _phoneController.text,
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true); // Return true to indicate successful login
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identifiants invalides ou erreur réseau')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Aesthetic
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF0B4629).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInLeft(
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.black54),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeInDown(
                    child: Center(
                      child: Image.asset('assets/img/logo.png', width: 120),
                    ),
                  ),
                  const SizedBox(height: 48),
                  FadeInUp(
                    child: const Text(
                      'Bon retour !',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF062B1A), letterSpacing: -1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: const Text(
                      'Connectez-vous pour gérer vos biens et votre solvabilité.',
                      style: TextStyle(fontSize: 15, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Form Fields
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _phoneController,
                          hint: 'Téléphone ou Email',
                          icon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          hint: 'Mot de passe',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Mot de passe oublié ?', style: TextStyle(color: Color(0xFF0B4629), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B4629), Color(0xFF062B1A)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF0B4629).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SE CONNECTER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: "Nouveau ici ? ",
                          style: TextStyle(color: Colors.blueGrey, fontSize: 14),
                          children: [
                            TextSpan(
                              text: "Créer un compte",
                              style: TextStyle(color: Color(0xFF0B4629), fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w400),
          prefixIcon: Icon(icon, color: const Color(0xFF0B4629), size: 20),
          suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.blueGrey, size: 20),
                onPressed: onToggleVisibility,
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
