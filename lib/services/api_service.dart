import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // static const String baseUrl = 'http://209.38.117.86/thermologic';
  static const String baseUrl = 'http://192.168.1.22:8000';

  // Default company ID - can be changed by user
  static int currentCompanyId = 1;

  // Company management
  static void setCompany(int companyId) {
    currentCompanyId = companyId;
  }

  static int getCurrentCompany() {
    return currentCompanyId;
  }

  // Health check endpoint (no company needed)
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

  // Upload document (company-aware)
  static Future<Map<String, dynamic>> uploadDocument(
      File file, String userId) async {
    try {
      var request = http.MultipartRequest(
          'POST',
          Uri.parse(
              '$baseUrl/api/v1/companies/$currentCompanyId/documents/upload'));
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

  // Search documents (company-aware)
  static Future<Map<String, dynamic>> searchDocuments(String query,
      {int limit = 10}) async {
    try {
      // Use company-aware search endpoint
      final uri = Uri.parse(
              '$baseUrl/api/v1/companies/$currentCompanyId/documents/search')
          .replace(
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

  // Get all documents (company-aware)
  static Future<Map<String, dynamic>> getDocuments() async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/api/v1/companies/$currentCompanyId/documents'));
      return {
        'success': response.statusCode == 200,
        'data': json.decode(response.body),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get system statistics (company-aware)
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/companies/$currentCompanyId/stats'));
      return {
        'success': response.statusCode == 200,
        'data': json.decode(response.body),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get document details (keeping original endpoint for now)
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

  // Reprocess document (keeping original endpoint for now)
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

  // Delete document (keeping original endpoint for now)
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

  // Get available companies (for dropdown)
  static Future<Map<String, dynamic>> getCompanies() async {
    try {
      // For now, return hardcoded companies
      // Later you could add a backend endpoint for this
      return {
        'success': true,
        'data': [
          {'id': 1, 'name': 'Test Company'},
          {'id': 2, 'name': 'Second Company'},
          {'id': 3, 'name': 'Demo Company'},
        ],
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
