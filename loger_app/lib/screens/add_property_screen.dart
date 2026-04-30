import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import '../services/api_service.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _cityController = TextEditingController();

  String _category = 'RENT';
  String _type = 'APPARTEMENT';
  String _city = 'DAKAR';
  final List<XFile> _images = [];
  bool _isSubmitting = false;

  final List<String> _categories = ['RENT', 'SALE', 'VACATION'];
  List<String> _types = ['APPARTEMENT', 'VILLA', 'STUDIO'];
  List<String> _cities = ['DAKAR', 'THIES', 'MBOUR', 'SAINT_LOUIS'];

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final cities = await ApiService().fetchCities();
      final types = await ApiService().fetchPropertyTypes();
      setState(() {
        _cities = cities.map((c) => c['id']!).toList();
        _types = types.map((t) => t['id']!).toList();
        if (_cities.isNotEmpty) _city = _cities.first;
        if (_types.isNotEmpty) _type = _types.first;
      });
    } catch (e) {
      // Fallback
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _images.addAll(picked));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins une photo')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final propertyData = {
        'title': _titleController.text,
        'price': double.parse(_priceController.text),
        'description': _descController.text,
        'listing_category': _category,
        'property_type': _type,
        'city': _city,
        'neighborhood': _cityController.text, // On utilise le champ texte pour le quartier
        'is_published': true,
      };

      final result = await ApiService().createProperty(propertyData);

      if (result != null && result['id'] != null) {
        final propertyId = result['id'].toString();

        // Upload images
        for (var i = 0; i < _images.length; i++) {
          await ApiService().uploadImage(
            propertyId,
            File(_images[i].path),
            isPrimary: i == 0,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Annonce publiée avec succès !')),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Erreur lors de la création');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Nouvelle Annonce',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF062B1A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0B4629)),
                  SizedBox(height: 20),
                  Text(
                    'Publication en cours...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(
                      child: const Text(
                        'Détails du bien',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B4629),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('Titre de l\'annonce'),
                    _buildTextField(
                      _titleController,
                      'Ex: Bel appartement F4 à Sacré Cœur',
                      Icons.title_rounded,
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Prix (FCFA)'),
                              _buildTextField(
                                _priceController,
                                '250000',
                                Icons.payments_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'Ville',
                            _city,
                            _cities,
                            (val) => setState(() => _city = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Quartier'),
                              _buildTextField(
                                _cityController,
                                'Ex: Almadies',
                                Icons.near_me_rounded,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'Catégorie',
                            _category,
                            _categories,
                            (val) => setState(() => _category = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            'Type de bien',
                            _type,
                            _types,
                            (val) => setState(() => _type = val!),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    _buildLabel('Description'),
                    _buildTextField(
                      _descController,
                      'Décrivez les atouts de votre bien...',
                      Icons.description_rounded,
                      maxLines: 4,
                    ),

                    const SizedBox(height: 32),
                    _buildLabel('Photos du bien (${_images.length})'),
                    const SizedBox(height: 12),
                    _buildImagePicker(),

                    const SizedBox(height: 48),
                    FadeInUp(
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0B4629), Color(0xFF062B1A)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0B4629).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'PUBLIER L\'ANNONCE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (v) => v!.isEmpty ? 'Requis' : null,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF0B4629), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF0B4629).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF0B4629).withValues(alpha: 0.2),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                color: Color(0xFF0B4629),
                size: 32,
              ),
            ),
          ),
          ..._images.map(
            (img) => Container(
              width: 120,
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: FileImage(File(img.path)),
                  fit: BoxFit.cover,
                ),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 12,
                    child: Icon(Icons.close, size: 14, color: Colors.red),
                  ),
                  onPressed: () => setState(() => _images.remove(img)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
