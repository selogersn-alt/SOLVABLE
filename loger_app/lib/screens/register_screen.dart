import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'TENANT';
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty || _firstNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir les champs obligatoires')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final result = await AuthService().register(
      phoneNumber: _phoneController.text,
      password: _passwordController.text,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      role: _selectedRole,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte créé ! Connectez-vous.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInLeft(
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black54),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeInDown(
                    child: const Text(
                      'Créer un compte',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF062B1A), letterSpacing: -1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rejoignez la plateforme immobilière la plus sécurisée du Sénégal.',
                    style: TextStyle(fontSize: 15, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 40),
                  
                  _buildTextField(controller: _firstNameController, hint: 'Prénom', icon: Icons.person_outline_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _lastNameController, hint: 'Nom', icon: Icons.person_outline_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _phoneController, hint: 'Téléphone', icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _passwordController, hint: 'Mot de passe', icon: Icons.lock_outline_rounded, isPassword: true),
                  
                  const SizedBox(height: 24),
                  const Text('Je suis un :', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildRoleOption('TENANT', 'Locataire', Icons.home_rounded),
                      const SizedBox(width: 12),
                      _buildRoleOption('PROFESSIONAL', 'Pro', Icons.business_center_rounded),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  FadeInUp(
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0B4629), Color(0xFF062B1A)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF0B4629).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('CRÉER MON COMPTE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Déjà un compte ? Se connecter', style: TextStyle(color: Color(0xFF0B4629), fontWeight: FontWeight.bold)),
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

  Widget _buildRoleOption(String role, String label, IconData icon) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0B4629) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? Colors.transparent : Colors.black12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.blueGrey, size: 24),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.blueGrey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF0B4629), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    );
  }
}
