import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../models/user.dart';
import '../utils/http_exception.dart';
import '../providers/issue_provider.dart';
import '../providers/auth_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ProjectProvider with ChangeNotifier {
  final String? token;
  List<Project> _projects = [];

   ProjectProvider(this.token, {List<Project> previousProjects = const []}) 
    : _projects = previousProjects;

  List<Project> get projects => [..._projects];

  Project findById(int id) =>
      _projects.firstWhere((project) => project.id == id);

  bool _isAdminUser() {
    final user = Provider.of<AuthProvider>(
      navigatorKey.currentContext!,
      listen: false,
    ).currentUser;
    return user != null && user.role == 'admin';
  }

  Future<void> fetchProjects() async {
    if (token == null) return;
    final baseUrl = '${dotenv.env['API_URL']}/projects';
    final fetchUrl = Uri.parse(
      '$baseUrl?include_owned=true&include_members=true',
    );

    try {
      final response = await http.get(
        fetchUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 400) {
        throw HttpException('Failed to fetch projects: ${response.body}');
      }

      final responseData = json.decode(response.body) as List<dynamic>;
      final loadedProjects = responseData
          .map((proj) => Project.fromJson(proj as Map<String, dynamic>))
          .toList();

      _projects = loadedProjects;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

Future<Project> createProject(
  String name,
  String key,
  String description,
  int leadId,
  String direction,
) async {
  if (token == null) throw HttpException('Not authenticated');

  if (name.isEmpty) throw HttpException('Project name cannot be empty');
  if (key.isEmpty) throw HttpException('Project key cannot be empty');
  if (leadId <= 0) throw HttpException('Invalid lead user');
  if (direction.isEmpty) throw HttpException('Direction cannot be empty');

  final url = '${dotenv.env['API_URL']}/projects';
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'name': name,
        'key': key,
        'description': description,
        'lead_id': leadId,
        'direction': direction,
      }),
    );

    if (response.statusCode >= 400) {
      throw HttpException('Failed to create project: ${response.body}');
    }

    if (response.body.isEmpty) {
      throw HttpException('Empty response received from server');
    }

    final responseData = json.decode(response.body);

    if (responseData == null || responseData is! Map<String, dynamic>) {
      throw HttpException('Invalid response format');
    }

    final newProject = Project.fromJson(responseData);

    await fetchProjects(); // Refresh the list from server
    notifyListeners();

    return newProject;
  } catch (e) {
    debugPrint('Error in createProject: $e');
    rethrow;
  }
}




  Future<Project> fetchProjectDetails(int projectId) async {
    if (token == null) throw HttpException('Not authenticated');

    final url =
        '${dotenv.env['API_URL']}/projects/$projectId?include_members=true';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.body.isEmpty) {
        throw HttpException('Empty response received from server');
      }
      if (response.statusCode >= 400) {
        throw HttpException('Failed to fetch project details');
      }

      final responseData = json.decode(response.body) as Map<String, dynamic>;
      final updatedProject = Project.fromJson(responseData);

      final index =
          _projects.indexWhere((project) => project.id == updatedProject.id);
      if (index >= 0) {
        _projects[index] = updatedProject;
      } else {
        _projects.add(updatedProject);
      }
      notifyListeners();
      return updatedProject;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateProject(
    int id,
    String name,
    String key,
    String description,
    int leadId,
    String direction,
  ) async {
    if (token == null) throw HttpException('Not authenticated');

    final projectIndex = _projects.indexWhere((project) => project.id == id);
    if (projectIndex < 0) {
      throw HttpException('Project not found');
    }

    final url = '${dotenv.env['API_URL']}/projects/$id';
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'key': key,
          'description': description,
          'lead_id': leadId,
          'direction': direction,
        }),
      );

      if (response.body.isEmpty) {
        throw HttpException('Empty response received from server');
      }

      final responseData = json.decode(response.body);
      if (response.statusCode >= 400) {
        throw HttpException(responseData['message'] ?? 'Failed to update project');
      }

      _projects[projectIndex] = Project.fromJson(responseData);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }


  Future<void> deleteProject(int id) async {
  if (token == null) {
    throw HttpException('Not authenticated');
  }

  try {
    final url = '${dotenv.env['API_URL']}/projects/$id';
    debugPrint('Attempting to delete project at: $url');

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    debugPrint('Delete response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 204) {
      // Remove from local list and notify listeners
      _projects.removeWhere((project) => project.id == id);
      notifyListeners();
    } else if (response.statusCode == 403) {
      throw HttpException('You are not authorized to delete this project');
    } else if (response.statusCode == 404) {
      throw HttpException('Project not found');
    } else {
      final errorData = json.decode(response.body);
      throw HttpException(errorData['message'] ?? 'Failed to delete project');
    }
  } catch (e, stack) {
    debugPrint('Delete project error: $e');
    debugPrint(stack.toString());
    rethrow;
  }
}
Future<void> addProjectMember(int projectId, int userId, String role) async {
  if (token == null) throw HttpException('Not authenticated');

  final url = '${dotenv.env['API_URL']}/projects/$projectId/members';
  try {
    final body = json.encode({
      'user_id': userId,
      'role': role,
    });

    debugPrint('Sending request to: $url');
    debugPrint('Request body: $body');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: body,
    );

    debugPrint('Response status code: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode >= 400) {
      String errorMessage = 'Failed to add member';
      if (response.body.isNotEmpty) {
        try {
          final responseData = json.decode(response.body);
          if (responseData != null && responseData['message'] != null) {
            errorMessage = responseData['message'];
          }
        } catch (e) {
          debugPrint('Failed to parse error response: $e');
        }
      }
      throw HttpException(errorMessage);
    }

    // Refresh project details
    await fetchProjectDetails(projectId);
  } catch (error) {
    debugPrint('Error adding member: $error');
    rethrow;
  }
}
// Add these fields and methods to your ProjectProvider class:

// Add this field to the class
Map<String, int>? _lastRemovedMember;

// Add this getter
Map<String, int>? get lastRemovedMember => _lastRemovedMember;

// Add this method to clear the last removed member
void clearLastRemovedMember() {
  _lastRemovedMember = null;
}

// Update your removeProjectMember method to set the _lastRemovedMember field:
Future<void> removeProjectMember(int projectId, int userId) async {
  if (token == null) throw HttpException('Not authenticated');
  
  final url = '${dotenv.env['API_URL']}/projects/$projectId/members';
  try {
    // Log the request for debugging
    debugPrint('Removing member: Project ID: $projectId, User ID: $userId');
    
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'user_id': userId,
      }),
    );

    // Debug the response
    debugPrint('Remove member response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');
    
    if (response.statusCode >= 400) {
      final responseData = json.decode(response.body);
      throw HttpException(responseData['message'] ?? 'Failed to remove member');
    }

    // Set the lastRemovedMember field to notify the IssueProvider
    _lastRemovedMember = {'projectId': projectId, 'userId': userId};
    notifyListeners();

    // Refresh project details after successful removal
    await fetchProjectDetails(projectId);
    
  } catch (error) {
    debugPrint('Error removing member: $error');
    rethrow;
  }
}



  Future<List<User>> searchUsers(String query) async {
    if (token == null) throw HttpException('Not authenticated');

    final url = '${dotenv.env['API_URL']}/users/search?query=$query';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.body.isEmpty) {
        throw HttpException('Empty response received from server');
      }

      final responseData = json.decode(response.body) as List<dynamic>;
      if (response.statusCode >= 400) {
        throw HttpException('Failed to search users');
      }

      return responseData
          .map((userData) => User.fromJson(userData as Map<String, dynamic>))
          .toList();
    } catch (error) {
      rethrow;
    }
  }
}

