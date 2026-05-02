import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import '../models/property_model.dart';

class ApiService {
  static const String baseUrl = 'https://logersenegal.com/api';
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> fetchProperties({String? city, String? propertyType, String? listingCategory, String? neighborhood, String? search, int page = 1}) async {
    final queryParameters = <String, String>{};
    if (city != null && city != 'TOUT') queryParameters['city'] = city;
    if (propertyType != null && propertyType != 'TOUT') queryParameters['property_type'] = propertyType;
    if (listingCategory != null && listingCategory != 'TOUT') queryParameters['listing_category'] = listingCategory;
    if (neighborhood != null && neighborhood != 'TOUT') {
      queryParameters['neighborhood'] = _normalizeNeighborhood(neighborhood);
    }
    if (search != null && search.isNotEmpty) queryParameters['search'] = search;
    queryParameters['page'] = page.toString();
    queryParameters['ordering'] = '-created_at';

    final uri = Uri.parse('$baseUrl/properties/').replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 15), // Réduit pour basculer plus vite sur le cache
        onTimeout: () => throw Exception('Timeout'),
      );
      
      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final dynamic decodedData = json.decode(decodedBody);
        
        List<dynamic> list;
        bool hasNext = false;

        if (decodedData is Map<String, dynamic>) {
          list = decodedData['results'] ?? [];
          hasNext = decodedData['next'] != null;
          
          // Mise en cache agressive pour la page 1 (accueil)
          if (page == 1 && city == null && propertyType == null && (search == null || search.isEmpty)) {
            final box = Hive.box('properties_cache');
            box.put('home_properties', list);
          }
        } else {
          list = decodedData is List ? decodedData : [];
        }

        final properties = list.map((json) => Property.fromJson(Map<String, dynamic>.from(json))).toList();

        return {'properties': properties, 'next': hasNext};
      } else {
        throw Exception('Server Error');
      }
    } catch (e) {
      debugPrint('ApiService Offline Mode: loading cache for $uri');
      // En cas d'erreur (hors-ligne), on tente de charger le cache
      if (page == 1) {
        final cached = getCachedProperties();
        if (cached.isNotEmpty) {
          return {'properties': cached, 'next': false};
        }
      }
      throw Exception('Impossible de se connecter au serveur');
    }
  }

  String _normalizeNeighborhood(String name) {
    return name.trim().toUpperCase().replaceAll(' ', '_').replaceAll("'", "_").replaceAll("-", "_");
  }

  List<Property> getCachedProperties() {
    try {
      final box = Hive.box('properties_cache');
      final List<dynamic>? cached = box.get('home_properties');
      if (cached != null) {
        return cached.map((json) => Property.fromJson(Map<String, dynamic>.from(json))).toList();
      }
    } catch (e) {
      debugPrint('Cache Load Error: $e');
    }
    return [];
  }

  void cachePropertyDetails(Property p) {
    try {
      final box = Hive.box('properties_cache');
      Map<String, dynamic> recently = box.get('recently_viewed', defaultValue: <String, dynamic>{});
      recently[p.id] = p.toJson(); // Assurez-vous d'avoir toJson() dans votre modèle
      
      // Limiter à 20 annonces récentes
      if (recently.length > 20) {
        recently.remove(recently.keys.first);
      }
      
      box.put('recently_viewed', recently);
    } catch (e) {
      debugPrint('Cache Detail Error: $e');
    }
  }

  List<Property> getRecentlyViewed() {
    try {
      final box = Hive.box('properties_cache');
      final Map<dynamic, dynamic>? recently = box.get('recently_viewed');
      if (recently != null) {
        return recently.values.map((v) => Property.fromJson(Map<String, dynamic>.from(v))).toList();
      }
    } catch (e) {
      debugPrint('Load Recently Viewed Error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> createProperty(Map<String, dynamic> data) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/properties/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> uploadImage(String propertyId, File imageFile, {bool isPrimary = false}) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return false;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/property-images/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['property'] = propertyId;
      request.fields['is_primary'] = isPrimary.toString();
      
      request.files.add(await http.MultipartFile.fromPath(
        'image_url',
        imageFile.path,
      ));

      final response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchProfessionals() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/professionals/'));
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- Favorites ---

  Future<bool> toggleFavorite(String propertyId) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/properties/$propertyId/toggle-favorite/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Property>> fetchFavorites() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties/favorites/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
        final box = Hive.box('properties_cache');
        box.put('favorites_cache', list);
        return list.map((json) => Property.fromJson(json)).toList();
      }
      throw Exception('Server Error');
    } catch (e) {
      // Retourne le cache si hors-ligne
      final box = Hive.box('properties_cache');
      final List<dynamic>? cached = box.get('favorites_cache');
      if (cached != null) {
        return cached.map((json) => Property.fromJson(json)).toList();
      }
      return [];
    }
  }

  // --- Conversations & Chat ---

  Future<List<dynamic>> fetchConversations() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conversations/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> fetchMessages(String conversationId) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conversations/$conversationId/messages/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> sendMessage(String conversationId, String content) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/conversations/$conversationId/send_message/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'content': content}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // --- Solvency Documents ---

  Future<List<dynamic>> fetchSolvencyDocuments() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/solvency-documents/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> uploadSolvencyDocument(String docType, File file) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return false;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/solvency-documents/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['doc_type'] = docType;
      
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
      ));

      final response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // --- Dashboard & My Items ---

  Future<List<Property>> fetchMyProperties() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties/my-properties/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
        return list.map((json) => Property.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> fetchMyBookings() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> fetchMyVisits() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/visits/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- Nohan AI ---

  Future<Map<String, dynamic>?> chatWithNohan(String message, List<dynamic> history) async {
    try {
      // Note: On utilise le domaine de base car nohan-chat est à la racine sur ce repo
      final response = await http.post(
        Uri.parse('https://logersenegal.com/nohan-chat/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message, 'history': history}),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- Blog & Articles ---

  Future<List<dynamic>> fetchBlogPosts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/blog/'));
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
        return list;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- Sécurité & Liste Noire ---

  Future<List<dynamic>> fetchBlacklist() async {
    try {
      final response = await http.get(Uri.parse('https://logersenegal.com/api/blacklist/'));
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- Utilitaires ---

  Future<Property?> fetchProperty(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/properties/$id/'));
      if (response.statusCode == 200) {
        return Property.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, String>>> fetchCities() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/properties/cities/'));
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
        debugPrint('Fetched ${list.length} cities');
        return list.map((c) => {'id': c['id'].toString(), 'name': c['name'].toString()}).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Fetch Cities Error: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> fetchPropertyTypes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/properties/types/'));
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
        debugPrint('Fetched ${list.length} property types');
        return list.map((t) => {'id': t['id'].toString(), 'name': t['name'].toString()}).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Fetch Types Error: $e');
      return [];
    }
  }
}
