import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/property_model.dart';
import '../services/api_service.dart';
import 'property_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ApiService _apiService = ApiService();
  List<Property> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('favorite_ids') ?? [];
    
    if (ids.isEmpty) {
      setState(() {
        _favorites = [];
        _isLoading = false;
      });
      return;
    }

    try {
      // Pour faire simple et éviter trop d'appels API, on pourrait aussi stocker les objets JSON
      // Mais ici on va les charger un par un ou via une future version de l'API.
      // Pour l'instant, on simule le chargement.
      final result = await _apiService.fetchProperties();
      final all = result['properties'] as List<Property>;
      setState(() {
        _favorites = all.where((p) => ids.contains(p.id)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? const Center(child: Text('Aucun favori pour le moment'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final p = _favorites[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: p.images.isNotEmpty ? p.images.first.imageUrl : '',
                            width: 60, height: 60, fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${NumberFormat('#,###').format(p.price)} FCFA', style: const TextStyle(color: Color(0xFF27C66E), fontWeight: FontWeight.bold)),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: p))),
                      ),
                    );
                  },
                ),
    );
  }
}
