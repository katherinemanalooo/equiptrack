import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/equipment.dart';

class ApiService {
  String? _serverIp;

  String? get serverIp => _serverIp;

  void setServerIp(String ip) {
    _serverIp = ip.trim();
  }

  String get baseUrl {
    if (_serverIp == null || _serverIp!.isEmpty) {
      throw Exception(
        'Server IP has not been configured.',
      );
    }

    return 'http://$_serverIp';
  }

  String get apiUrl {
    return '$baseUrl/equiptrack/api.php';
  }

  Future<bool> checkConnection() async {
    if (_serverIp == null || _serverIp!.isEmpty) {
      return false;
    }

    try {
      final response = await http
          .get(
        Uri.parse(
          '$apiUrl?action=health',
        ),
      )
          .timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode != 200) {
        return false;
      }

      final dynamic decoded =
      jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded['success'] == true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<List<Equipment>> getEquipment() async {
    final response = await http
        .get(
      Uri.parse(apiUrl),
    )
        .timeout(
      const Duration(seconds: 10),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load equipment.',
      );
    }

    final dynamic decoded =
    jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid API response.',
      );
    }

    if (decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ??
            'Failed to load equipment.',
      );
    }

    final dynamic data = decoded['data'];

    if (data is! List) {
      throw Exception(
        'Invalid equipment data.',
      );
    }

    return data
        .map(
          (item) => Equipment.fromJson(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  Future<http.Response> get(
      String endpoint,
      ) async {
    return http
        .get(
      Uri.parse('$baseUrl/$endpoint'),
    )
        .timeout(
      const Duration(seconds: 10),
    );
  }

  Future<http.Response> post(
      String endpoint,
      Map<String, dynamic> body,
      ) async {
    return http
        .post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type':
        'application/json',
      },
      body: jsonEncode(body),
    )
        .timeout(
      const Duration(seconds: 10),
    );
  }

  Future<http.Response> put(
      String endpoint,
      Map<String, dynamic> body,
      ) async {
    return http
        .put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type':
        'application/json',
      },
      body: jsonEncode(body),
    )
        .timeout(
      const Duration(seconds: 10),
    );
  }

  Future<http.Response> delete(
      String endpoint,
      ) async {
    return http
        .delete(
      Uri.parse('$baseUrl/$endpoint'),
    )
        .timeout(
      const Duration(seconds: 10),
    );
  }
}