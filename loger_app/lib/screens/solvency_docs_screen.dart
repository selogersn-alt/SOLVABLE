import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:animate_do/animate_do.dart';
import '../services/api_service.dart';

class SolvencyDocsScreen extends StatefulWidget {
  const SolvencyDocsScreen({super.key});

  @override
  State<SolvencyDocsScreen> createState() => _SolvencyDocsScreenState();
}

class _SolvencyDocsScreenState extends State<SolvencyDocsScreen> {
  final Map<String, File?> _selectedFiles = {
    'CNI': null,
    'PAY_STUB': null,
    'TAX_RETURN': null,
    'UTILITY_BILL': null,
  };
  
  final Map<String, bool> _isUploading = {
    'CNI': false,
    'PAY_STUB': false,
    'TAX_RETURN': false,
    'UTILITY_BILL': false,
  };

  Future<void> _pickFile(String type) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'pdf', 'png'],
      );
      if (result != null) {
        setState(() => _selectedFiles[type] = File(result.files.single.path!));
      }
        } catch (e) {
      debugPrint('File picker error: $e');
    }
  }

  Future<void> _upload(String type) async {
    if (_selectedFiles[type] == null) return;

    setState(() => _isUploading[type] = true);
    
    try {
      final apiService = ApiService();
      final success = await apiService.uploadSolvencyDocument(type, _selectedFiles[type]!);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Document $type envoyé avec succès !')));
          setState(() => _selectedFiles[type] = null);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'envoi.')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _isUploading[type] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Certification NILS', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF062B1A))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0B4629), Color(0xFF062B1A)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security_rounded, color: Colors.white, size: 40),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dossier de Solvabilité', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          SizedBox(height: 4),
                          Text('Optimisez vos chances d\'obtenir un logement en certifiant vos documents.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Documents requis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B4629))),
            const SizedBox(height: 16),
            
            _buildDocItem('CNI', 'Carte d\'Identité Nationale ou Passeport', Icons.badge_rounded),
            _buildDocItem('PAY_STUB', 'Dernier bulletin de salaire', Icons.request_quote_rounded),
            _buildDocItem('TAX_RETURN', 'Avis d\'imposition ou attestation', Icons.description_rounded),
            _buildDocItem('UTILITY_BILL', 'Justificatif de domicile (Senelec/Sen\'Eau)', Icons.home_work_rounded),
            
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Vos documents sont chiffrés et stockés de manière sécurisée.',
                style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocItem(String type, String label, IconData icon) {
    File? file = _selectedFiles[type];
    bool uploading = _isUploading[type] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF0B4629).withValues(alpha: 0.1),
                child: Icon(icon, color: const Color(0xFF0B4629), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (file != null) 
                      Text(file.path.split('/').last, style: const TextStyle(color: Colors.blueGrey, fontSize: 12), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: uploading ? null : () => _pickFile(type),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('CHOISIR FICHIER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              if (file != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: uploading ? null : () => _upload(type),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B4629),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: uploading 
                      ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('ENVOYER', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
