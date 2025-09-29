import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class RFIService {
  static const String _baseUrl = 'http://192.168.29.36:8080';
  static const String _rfiEndpoint = '/api/projects';

  static RFIService? _instance;
  static RFIService get instance => _instance ??= RFIService._();

  RFIService._();

  /// Update project RFI data
  Future<bool> updateProjectRFI(int projectId, List<Map<String, dynamic>> rfiItems) async {
    try {
      print('🔄 Updating RFI for project $projectId');
      
      final headers = await AuthService.instance.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl$_rfiEndpoint/$projectId/rfi'),
        headers: headers,
        body: jsonEncode({
          'rfis': rfiItems,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      );

      print('📡 RFI update response status: ${response.statusCode}');
      print('📄 RFI update response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ RFI updated successfully');
        return true;
      } else {
        print('❌ Failed to update RFI: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('💥 Error updating RFI: $e');
      return false;
    }
  }

  /// Add a new RFI item to a project
  Future<bool> addRFIItem(int projectId, Map<String, dynamic> rfiItem) async {
    try {
      print('➕ Adding RFI item to project $projectId');
      
      final headers = await AuthService.instance.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl$_rfiEndpoint/$projectId/rfi'),
        headers: headers,
        body: jsonEncode({
          'question_text': rfiItem['question_text'],
          'status': rfiItem['status'] ?? 'pending',
        }),
      );

      print('📡 Add RFI response status: ${response.statusCode}');
      print('📄 Add RFI response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ RFI item added successfully');
        return true;
      } else {
        print('❌ Failed to add RFI item: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('💥 Error adding RFI item: $e');
      return false;
    }
  }

  /// Update project status based on RFI completion
  Future<bool> updateProjectStatus(int projectId, String status) async {
    try {
      print('🔄 Updating project $projectId status to $status');
      
      final headers = await AuthService.instance.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl$_rfiEndpoint/$projectId'),
        headers: headers,
        body: jsonEncode({
          'project_status': status,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      );

      print('📡 Status update response: ${response.statusCode}');
      print('📄 Status update response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Project status updated successfully');
        return true;
      } else {
        print('❌ Failed to update project status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('💥 Error updating project status: $e');
      return false;
    }
  }
}
