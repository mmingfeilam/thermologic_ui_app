import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://209.38.117.86/thermologic';

  // Health check endpoint
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return {
        'success': response.statusCode == 200,
        'data': json.decode(response.body),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Upload document
  static Future<Map<String, dynamic>> uploadDocument(
      File file, String userId) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/api/v1/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      request.fields['user_id'] = userId;

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      return {
        'success': response.statusCode == 200,
        'data': json.decode(responseBody),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Search documents
  static Future<Map<String, dynamic>> searchDocuments(String query,
      {int limit = 10}) async {
    try {
      // Build URL with query parameters (as your backend expects)
      final uri = Uri.parse('$baseUrl/api/v1/search').replace(
        queryParameters: {
          'query': query,
          'limit': limit.toString(),
        },
      );

      final response = await http.post(uri);

      return {
        'success': response.statusCode == 200,
        'data': json.decode(response.body),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get all documents
  static Future<Map<String, dynamic>> getDocuments() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/v1/documents'));
      return {
        'success': response.statusCode == 200,
        'data': json.decode(response.body),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get system statistics
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/v1/stats'));
      return {
        'success': response.statusCode == 200,
        'data': json.decode(response.body),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get document details
  static Future<Map<String, dynamic>> getDocumentById(int documentId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/v1/documents/$documentId'));
      return {
        'success': response.statusCode == 200,
        'data': json.decode(response.body),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Reprocess document
  static Future<Map<String, dynamic>> reprocessDocument(int documentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/documents/$documentId/reprocess'),
      );
      return {
        'success': response.statusCode == 200,
        'data': response.statusCode == 200 ? json.decode(response.body) : null,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Delete document
  static Future<Map<String, dynamic>> deleteDocument(int documentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/documents/$documentId'),
      );
      return {
        'success': response.statusCode == 200,
        'data': response.statusCode == 200 ? json.decode(response.body) : null,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
