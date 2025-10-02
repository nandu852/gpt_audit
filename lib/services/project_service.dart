import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project.dart';
import 'auth_service.dart';

class ProjectService {
  static const String _baseUrl = 'http://192.168.1.105:8080';
  static const String _projectsEndpoint = '/api/projects';
  
  static ProjectService? _instance;
  static ProjectService get instance => _instance ??= ProjectService._();
  
  ProjectService._();

  Future<List<Project>> getAllProjects() async {
    try {
      final headers = await AuthService.instance.getAuthHeaders();
      print('🔍 Fetching projects from: $_baseUrl$_projectsEndpoint');
      print('🔑 Auth headers: $headers');
      print('🎫 Full token: ${headers['Authorization']}');
      
      final response = await http.get(
        Uri.parse('$_baseUrl$_projectsEndpoint'),
        headers: headers,
      );
      
      print('📡 Response status: ${response.statusCode}');
      print('📄 Response headers: ${response.headers}');
      print('📄 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('📊 Response data type: ${responseData.runtimeType}');
        print('📊 Response data keys: ${responseData is Map ? responseData.keys.toList() : 'Not a Map'}');
        
        // Handle the response format: {"projects": [...]}
        List<dynamic> projectsJson;
        if (responseData is Map<String, dynamic> && responseData.containsKey('projects')) {
          projectsJson = responseData['projects'] as List<dynamic>;
        } else if (responseData is List) {
          projectsJson = responseData;
        } else {
          print('❌ Unexpected response format');
          return [];
        }
        
        print('📊 Found ${projectsJson.length} projects');
        print('📊 Raw projects JSON: $projectsJson');
        final projects = projectsJson.map((json) {
          print('📋 Project JSON: $json');
          final project = Project.fromJson(json);
          print('📋 Parsed project ID: ${project.id}');
          return project;
        }).toList();
        print('✅ Successfully parsed ${projects.length} projects');
        print('📊 Final project IDs: ${projects.map((p) => p.id).toList()}');
        return projects;
      } else {
        print('❌ Failed to load projects: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('💥 Error loading projects: $e');
      return [];
    }
  }

  Future<Project?> createProject(Project project) async {
    try {
      print('🚀 Creating project: ${project.projectName}');
      print('📤 Sending to: $_baseUrl$_projectsEndpoint');
      print('📋 Project data: ${project.toJson()}');
      
      final headers = await AuthService.instance.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl$_projectsEndpoint'),
        headers: headers,
        body: jsonEncode(project.toJson()),
      );
      
      print('📡 Create response status: ${response.statusCode}');
      print('📄 Create response body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final createdProject = Project.fromJson(jsonDecode(response.body));
        print('✅ Project created successfully: ${createdProject.projectName}');
        return createdProject;
      } else {
        print('❌ Failed to create project: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('💥 Error creating project: $e');
      return null;
    }
  }

  Future<Project?> getProjectById(int projectId) async {
    try {
      final headers = await AuthService.instance.getAuthHeaders();
      print('🔍 Fetching project $projectId from: $_baseUrl$_projectsEndpoint/$projectId');
      print('🔑 Auth headers: $headers');
      
      final response = await http.get(
        Uri.parse('$_baseUrl$_projectsEndpoint/$projectId'),
        headers: headers,
      );
      
      print('📡 Project response status: ${response.statusCode}');
      print('📄 Project response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('📊 Project response data: $responseData');
        
        // Handle the nested project object from API response
        if (responseData is Map<String, dynamic> && responseData.containsKey('project')) {
          final projectData = responseData['project'] as Map<String, dynamic>;
          print('📊 Found project data: $projectData');
          return Project.fromJson(projectData);
        } else {
          print('❌ Unexpected project response format - no "project" key found');
          print('📊 Available keys: ${responseData is Map ? responseData.keys.toList() : 'Not a Map'}');
          return null;
        }
      } else if (response.statusCode == 404) {
        print('❌ Project not found (404): Project ID $projectId does not exist');
        return null;
      } else {
        print('❌ Failed to load project: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('💥 Error loading project: $e');
      return null;
    }
  }

  Future<bool> updateProject(int projectId, Project project) async {
    try {
      final headers = await AuthService.instance.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl$_projectsEndpoint/$projectId'),
        headers: headers,
        body: jsonEncode(project.toJson()),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating project: $e');
      return false;
    }
  }

  Future<bool> updateProjectStatus(int projectId, String status) async {
    try {
      print('🔄 Updating project $projectId status to: $status');
      
      final headers = await AuthService.instance.getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl$_projectsEndpoint/$projectId/status'),
        headers: headers,
        body: jsonEncode({
          'status': status,
        }),
      );

      print('📡 Status update response status: ${response.statusCode}');
      print('📄 Status update response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Project status updated successfully');
        return true;
      } else {
        print('❌ Failed to update project status: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('💥 Error updating project status: $e');
      return false;
    }
  }

  Future<List<Specification>> getProjectSpecifications(int projectId) async {
    try {
      print('🔍 Fetching specifications for project $projectId from: $_baseUrl$_projectsEndpoint/$projectId/specifications');
      
      final headers = await AuthService.instance.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl$_projectsEndpoint/$projectId/specifications'),
        headers: headers,
      );

      print('📡 Specifications response status: ${response.statusCode}');
      print('📄 Specifications response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('📊 Specifications response data: $responseData');
        
        // Handle the response format - could be a list or wrapped in an object
        List<dynamic> specificationsJson;
        if (responseData is List) {
          specificationsJson = responseData;
        } else if (responseData is Map<String, dynamic> && responseData.containsKey('specifications')) {
          specificationsJson = responseData['specifications'] as List<dynamic>;
        } else {
          print('❌ Unexpected specifications response format');
          return [];
        }
        
        print('📊 Found ${specificationsJson.length} specifications');
        final specifications = specificationsJson.map((json) {
          print('📋 Specification JSON: $json');
          final specification = Specification.fromJson(json);
          print('📋 Parsed specification ID: ${specification.id}');
          return specification;
        }).toList();
        
        // Sort specifications by version number (latest to oldest)
        specifications.sort((a, b) => b.versionNo.compareTo(a.versionNo));
        
        print('✅ Successfully parsed ${specifications.length} specifications (sorted by version)');
        return specifications;
      } else {
        print('❌ Failed to load specifications: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('💥 Error loading specifications: $e');
      return [];
    }
  }

  // Test method to debug API calls
  Future<void> testApiCall() async {
    try {
      print('🧪 Testing API call...');
      
      // Test 1: Without any headers
      print('\n📋 Test 1: No headers');
      final response1 = await http.get(Uri.parse('$_baseUrl$_projectsEndpoint'));
      print('Status: ${response1.statusCode}');
      print('Body: ${response1.body}');
      
      // Test 2: With just Content-Type
      print('\n📋 Test 2: Content-Type only');
      final response2 = await http.get(
        Uri.parse('$_baseUrl$_projectsEndpoint'),
        headers: {'Content-Type': 'application/json'},
      );
      print('Status: ${response2.statusCode}');
      print('Body: ${response2.body}');
      
      // Test 3: With full auth headers
      print('\n📋 Test 3: Full auth headers');
      final headers = await AuthService.instance.getAuthHeaders();
      print('Headers: $headers');
      final response3 = await http.get(
        Uri.parse('$_baseUrl$_projectsEndpoint'),
        headers: headers,
      );
      print('Status: ${response3.statusCode}');
      print('Body: ${response3.body}');
      
    } catch (e) {
      print('💥 Test error: $e');
    }
  }
}
