import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/property_model.dart';

class ApiService {
  static const String baseUrl = 'https://logersenegal.com/api';

  Future<List<Property>> fetchProperties({String? city, String? propertyType}) async {
    final queryParameters = <String, String>{};
    if (city != null && city != 'ALL') queryParameters['city'] = city;
    if (propertyType != null && propertyType != 'ALL') queryParameters['property_type'] = propertyType;

    final uri = Uri.parse('$baseUrl/properties/').replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // DRF returns a 'results' key if pagination is enabled, otherwise a list
        final dynamic data = json.decode(utf8.decode(response.bodyBytes));
        
        List<dynamic> list;
        if (data is Map && data.containsKey('results')) {
          list = data['results'];
        } else {
          list = data;
        }

        return list.map((json) => Property.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors du chargement des annonces (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erreur de connexion : $e');
    }
  }
}
