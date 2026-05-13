import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PlaceApiService {
  String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    return 'http://10.0.2.2:8000';
  }

  Future<List<Map<String, dynamic>>> autocompletePlaces({
    required String query,
    required String cityName,
    required String country,
    required String sessionToken,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final uri = Uri.parse(
      '$baseUrl/places/autocomplete'
      '?q=${Uri.encodeQueryComponent(query)}'
      '&cityName=${Uri.encodeQueryComponent(cityName)}'
      '&country=${Uri.encodeQueryComponent(country)}'
      '&sessionToken=${Uri.encodeQueryComponent(sessionToken)}',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to autocomplete places: ${response.statusCode} ${response.body}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> getPlaceDetails({
    required String placeId,
    String? sessionToken,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/places/details'
      '?placeId=${Uri.encodeQueryComponent(placeId)}'
      '${sessionToken == null ? '' : '&sessionToken=${Uri.encodeQueryComponent(sessionToken)}'}',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get place details: ${response.statusCode} ${response.body}',
      );
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<Map<String, dynamic>> getPlaceFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/places/from-coordinates'
      '?latitude=$latitude'
      '&longitude=$longitude',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to resolve place from coordinates: ${response.statusCode} ${response.body}',
      );
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }
}