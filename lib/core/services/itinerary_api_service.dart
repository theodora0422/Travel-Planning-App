import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ItineraryApiService {
  String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    return 'http://10.0.2.2:8000';
  }

  Future<Map<String, dynamic>> generateItinerary({
    required Map<String, dynamic> selectedCity,
    required int numberOfDays,
    required String tripStyle,
  }) async {
    final uri = Uri.parse('$baseUrl/itinerary/generate');

    final body = {
      'cityName': selectedCity['name'],
      'country': selectedCity['country'],
      'numberOfDays': numberOfDays,
      'tripStyle': tripStyle,
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to generate itinerary: ${response.statusCode} ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}