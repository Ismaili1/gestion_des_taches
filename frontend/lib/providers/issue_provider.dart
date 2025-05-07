



import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/issue.dart';
import '../models/user.dart';
import '../models/comment.dart';
import '../utils/http_exception.dart';
import '../providers/project_provider.dart';

class IssueProvider with ChangeNotifier {
  final String? token;
  final ProjectProvider? projectProvider;
  List<Issue> _issues = [];
  List<Issue> _filteredIssues = [];
  Map<int, List<Issue>> _projectIssuesCache = {};
  bool _disposed = false;
  bool _isFetching = false;

Future<void> reloadProjectIssues(int projectId) async {
  _projectIssuesCache.remove(projectId);
  await fetchProjectIssues(projectId);
}
  
  IssueProvider(this.token, {this.projectProvider, List<Issue> previousIssues = const []}) {
    _issues = previousIssues;
    _filteredIssues = previousIssues;
    
    
    projectProvider?.addListener(_handleProjectChanges);
  }
  
  @override
  void dispose() {
    _disposed = true;
    projectProvider?.removeListener(_handleProjectChanges);
    super.dispose();
  }
  
  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
  List<Issue> get issues {
    return [..._issues];
  }

  List<Issue> get filteredIssues {
    return [..._filteredIssues];
  }

  List<Issue> getIssuesByProject(int projectId) {
    return _issues.where((issue) => issue.projectId == projectId).toList();
  }

  Issue? findById(int id) {
    final foundIssue = _issues.firstWhere((issue) => issue.id == id, 
      orElse: () => Issue(
        id: -1,
        projectId: -1, 
        key: '', 
        title: '', 
        description: '', 
        status: '',
        type: '',
        priority: '',
        reporter: User.empty(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )
    );
    return foundIssue.id == -1 ? null : foundIssue;
  }
  
  void _handleProjectChanges() {
    if (_disposed) return;
    
    final removedMember = projectProvider?.lastRemovedMember;
    if (removedMember != null) {
      
      removeUserIssues(removedMember['projectId']!, removedMember['userId']!);
      projectProvider?.clearLastRemovedMember();
    }
  }
  
  void removeUserIssues(int projectId, int userId) {
    if (_disposed) return;
    
    debugPrint('Removing issues for user $userId in project $projectId');
    
    
    _issues.removeWhere((issue) => 
      issue.projectId == projectId && 
      issue.assignee?.id == userId
    );
    
    
    _filteredIssues.removeWhere((issue) => 
      issue.projectId == projectId && 
      issue.assignee?.id == userId
    );
    
    notifyListeners();
    debugPrint('Issues removed successfully');
  }
  


  List<Issue> getProjectIssues(int projectId) {
    return _issues.where((issue) => issue.projectId == projectId).toList();
  }
  
  List<Issue> searchIssues(int projectId, String query) {
    if (query.isEmpty) {
      return getProjectIssues(projectId);
    }
    
    final lowercaseQuery = query.toLowerCase();
    return _issues.where((issue) => 
      issue.projectId == projectId && (
        issue.title.toLowerCase().contains(lowercaseQuery) ||
        issue.key.toLowerCase().contains(lowercaseQuery) ||
        issue.description.toLowerCase().contains(lowercaseQuery) ||
        issue.status.toLowerCase().contains(lowercaseQuery) ||
        issue.type.toLowerCase().contains(lowercaseQuery) ||
        issue.priority.toLowerCase().contains(lowercaseQuery) ||
        (issue.assignee?.name.toLowerCase().contains(lowercaseQuery) ?? false)
      )
    ).toList();
  }



Future<void> fetchProjectIssues(int projectId) async {
  if (_disposed || token == null) return;
  
  final url = '${dotenv.env['API_URL']}/projects/$projectId/issues';
  
  try {
    debugPrint('▼▼▼ FETCHING ISSUES FOR PROJECT $projectId ▼▼▼');
    debugPrint('API URL: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (_disposed) return;
    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    if (response.statusCode >= 400) {
      throw HttpException('Failed to fetch issues: ${response.statusCode}');
    }

    final responseData = json.decode(response.body) as List<dynamic>;
    
    final List<Issue> loadedIssues = [];
    for (var issueData in responseData) {
      try {
        loadedIssues.add(Issue.fromJson(issueData));
      } catch (e) {
        debugPrint('Error parsing issue: $e');
      }
    }

    
    _issues = _issues.where((issue) => issue.projectId != projectId).toList();
    _issues.addAll(loadedIssues);
    
    _projectIssuesCache[projectId] = List.from(loadedIssues);
    _updateFilteredIssues();
    
    debugPrint('▲▲▲ SUCCESSFULLY LOADED ${loadedIssues.length} ISSUES ▲▲▲');
  } catch (error) {
    if (_disposed) return;
    debugPrint('■■■ ERROR FETCHING ISSUES ■■■');
    debugPrint('$error');
    
    
    _projectIssuesCache[projectId] = [];
    _issues.removeWhere((issue) => issue.projectId == projectId);
    _updateFilteredIssues();
  } finally {
    if (!_disposed) {
      notifyListeners();
    }
  }
}

  void _updateFilteredIssues() {
    
    _filteredIssues = List.from(_issues);
    
    _filteredIssues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  
  void applyFilters({String? type, String? priority, String? status}) {
    _filteredIssues = _issues.where((issue) {
      bool matches = true;
      if (type != null && type.isNotEmpty) {
        matches = matches && issue.type.toLowerCase() == type.toLowerCase();
      }
      if (priority != null && priority.isNotEmpty) {
        matches = matches && issue.priority.toLowerCase() == priority.toLowerCase();
      }
      if (status != null && status.isNotEmpty) {
        matches = matches && issue.status.toLowerCase() == status.toLowerCase();
      }
      return matches;
    }).toList();
    
    notifyListeners();

  }
   void resetFilters() {
    _updateFilteredIssues();
    notifyListeners();
  }

Future<Issue> createIssue({
    required int projectId,
    required String title,
    required String description,
    required String type,
    required String priority,
    required String status,
    int? assigneeId,
    DateTime? dueDate,
  }) async {
    if (_disposed) throw HttpException('Provider has been disposed');
    if (token == null) throw HttpException('Not authenticated');
    
    final url = '${dotenv.env['API_URL']}/projects/$projectId/issues';
    
    try {
      final String sanitizedPriority = priority.toLowerCase();
      
      final data = {
        'title': title,
        'description': description,
        'type': type.toLowerCase(),
        'priority': sanitizedPriority,
        'status': status,
        if (assigneeId != null) 'assignee_id': assigneeId,
        if (dueDate != null) 'due_date': dueDate.toIso8601String(),
      };
      
      debugPrint('Creating issue for project $projectId with data: $data');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (_disposed) throw HttpException('Provider has been disposed');

      if (response.statusCode >= 400) {
        final responseData = json.decode(response.body);
        debugPrint('Server error response: $responseData');
        throw HttpException(responseData['message'] ?? responseData['error'] ?? 'Failed to create issue');
      }

      final responseData = json.decode(response.body);
      final newIssue = Issue.fromJson(responseData);
      
      
      _issues.add(newIssue);
      
      
      if (_projectIssuesCache.containsKey(projectId)) {
        _projectIssuesCache[projectId]!.add(newIssue);
      }
      
      
      _updateFilteredIssues();
      
      
      notifyListeners();
      
      debugPrint('Issue created successfully: ${newIssue.id} - ${newIssue.title}');
      
      
      await fetchProjectIssues(projectId);
      
      return newIssue;
    } catch (error) {
      if (_disposed) return Future.error('Provider has been disposed');
      debugPrint('Error creating issue: $error');
      rethrow;
    }
  }

  Future<void> updateIssue({
    required int id,
    required String title,
    required String description,
    required String type,
    required String priority,
    required String status,
    int? assigneeId,
    DateTime? dueDate,
  }) async {
    if (_disposed) return;
    if (token == null) throw HttpException('Not authenticated');

    
    final currentIssue = findById(id);
    
    
    final url = '${dotenv.env['API_URL']}/issues/$id';

    try {
      
      final Map<String, int> priorityMap = {
        'low': 1,
        'medium': 2,
        'high': 3
      };
      
      final int priorityValue = priorityMap[priority.toLowerCase()] ?? 2; 
      
 
      int columnId = currentIssue?.column?.id ?? 0;
      
  

      final data = {
        'title': title,
        'description': description,
        'type': type.toLowerCase(),
        'priority': priorityValue, 
        'column_id': columnId, 
        'deposit': true, 
        if (assigneeId != null) 'assignee_id': assigneeId,
        if (dueDate != null) 'due_date': dueDate.toIso8601String(),
      };

      debugPrint('Updating issue with data: $data');
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (_disposed) return;

      if (response.statusCode >= 400) {
        final responseData = json.decode(response.body);
        debugPrint('Server error response: $responseData');
        throw HttpException(responseData['message'] ?? responseData['error'] ?? 'Failed to update issue');
      }

      final responseData = json.decode(response.body);
      
      
      final index = _issues.indexWhere((issue) => issue.id == id);
      if (index >= 0) {
        _issues[index] = Issue.fromJson(responseData);
        notifyListeners();
      }
      
      debugPrint('Issue updated successfully');
    } catch (error) {
      if (_disposed) return;
      debugPrint('Error updating issue: $error');
      rethrow;
    }
  }

  Future<void> deleteIssue(int id) async {
    if (_disposed) return;
    if (token == null) throw HttpException('Not authenticated');
    
    final issueIndex = _issues.indexWhere((issue) => issue.id == id);
    if (issueIndex < 0) {
      return;
    }
    
    final url = '${dotenv.env['API_URL']}/issues/$id';
    
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (_disposed) return;
      
      if (response.statusCode >= 400) {
        final errorData = json.decode(response.body);
        throw HttpException(errorData['message'] ?? 'Failed to delete issue');
      }

      _issues.removeAt(issueIndex);
      notifyListeners();
    } catch (error) {
      if (_disposed) return;
      debugPrint('Error deleting issue: $error');
      rethrow;
    }
  }

  Future<List<Comment>> fetchIssueComments(int projectId, int issueId) async {
    if (_disposed) return [];
    if (token == null) throw HttpException('Not authenticated');
    
    final url = '${dotenv.env['API_URL']}/projects/$projectId/issues/$issueId/comments';
    debugPrint('Fetching comments from: $url');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (_disposed) return [];
      
      debugPrint('Response status: ${response.statusCode}');
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode >= 400) {
        throw HttpException('Failed to fetch comments');
      }

      if (responseData is List) {
        return responseData.map((commentData) => Comment.fromJson(commentData)).toList();
      } else {
        debugPrint('Unexpected response format: $responseData');
        return [];
      }
    } catch (error) {
      if (_disposed) return [];
      debugPrint('Error fetching comments: $error');
      rethrow;
    }
  }
   
  Future<Comment> addComment(int projectId, int issueId, String content) async {
    if (_disposed) throw HttpException('Provider has been disposed');
    if (token == null) throw HttpException('Not authenticated');
    
    final url = '${dotenv.env['API_URL']}/projects/$projectId/issues/$issueId/comments';
    
    try {
      debugPrint('Sending comment to: $url');
      debugPrint('Comment data: { "content": "$content", "issue_id": $issueId }');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'content': content,
          'issue_id': issueId,
        }),
      );

      if (_disposed) throw HttpException('Provider has been disposed');
      
      debugPrint('Response status code: ${response.statusCode}');
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode >= 400) {
        throw HttpException(responseData['message'] ?? 'Failed to add comment');
      }

      return Comment.fromJson(responseData);
    } catch (error) {
      if (_disposed) return Future.error('Provider has been disposed');
      debugPrint('Error adding comment: $error');
      rethrow;
    }
  }

 Future<Map<String, int>> getIssueStats(int projectId) async {
    if (_disposed) throw HttpException('Provider has been disposed');
    if (token == null) throw HttpException('Not authenticated');

    final url = '${dotenv.env['API_URL']}/projects/$projectId/issues/stats';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (_disposed) throw HttpException('Provider has been disposed');

      if (response.statusCode >= 400) {
        throw HttpException('Failed to fetch issue stats');
      }

      final stats = json.decode(response.body) as Map<String, dynamic>;

      return {
        'total': stats['total'] ?? 0,
        'open': stats['open'] ?? 0,
        'done': stats['done'] ?? 0,
      };
    } catch (error) {
      if (_disposed) return Future.error('Provider has been disposed');
      rethrow;
    }
  }
  
  Future<Comment?> changeStatus(
    int issueId, 
    String status, 
    {String? comment}
  ) async {
    if (_disposed) throw HttpException('Provider has been disposed');
    if (token == null) throw HttpException('Not authenticated');

    final url = '${dotenv.env['API_URL']}/issues/$issueId/status';

    try {
      
      final formattedStatus = _formatStatusForBackend(status);
      
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': formattedStatus,
          if (comment != null) 'comment': comment,
        }),
      );

      if (_disposed) throw HttpException('Provider has been disposed');

      if (response.statusCode >= 400) {
        final errorResponse = json.decode(response.body);
        throw HttpException(errorResponse['message'] ?? 'Failed to change status');
      }

      final responseData = json.decode(response.body);
      debugPrint('Status change response: $responseData');

      
      final updatedIssue = Issue.fromJson(responseData['issue'] ?? responseData);
      final index = _issues.indexWhere((i) => i.id == issueId);
      if (index != -1) {
        _issues[index] = updatedIssue;
        notifyListeners();
      }

      return responseData['comment'] != null 
        ? Comment.fromJson(responseData['comment'])
        : null;
    } catch (error) {
      if (_disposed) return Future.error('Provider has been disposed');
      debugPrint('Error changing issue status: $error');
      rethrow;
    }
  }

  String _formatStatusForBackend(String status) {
    
    switch (status.toLowerCase()) {
      case 'in progress':
        return 'in_progress';
      case 'in review':
        return 'in_review';
      case 'to do':
        return 'to_do';
      default:
        return status.toLowerCase().replaceAll(' ', '_');
    }
  }
  Future<Issue> fetchIssueDetails(int issueId) async {
  if (_disposed) throw HttpException('Provider has been disposed');
  if (token == null) throw HttpException('Not authenticated');

  final url = '${dotenv.env['API_URL']}/issues/$issueId';

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (_disposed) throw HttpException('Provider has been disposed');

    if (response.statusCode >= 400) {
      throw HttpException('Failed to load issue details');
    }

    final issueData = json.decode(response.body);
    final issue = Issue.fromJson(issueData);
    
    
    final index = _issues.indexWhere((i) => i.id == issueId);
    if (index != -1) {
      _issues[index] = issue;
    } else {
      _issues.insert(0, issue);
    }
    
    final filteredIndex = _filteredIssues.indexWhere((i) => i.id == issueId);
    if (filteredIndex != -1) {
      _filteredIssues[filteredIndex] = issue;
    } else {
      _filteredIssues.insert(0, issue);
    }
    
    notifyListeners();
    return issue;
  } catch (error) {
    if (_disposed) return Future.error('Provider has been disposed');
    debugPrint('Error fetching issue details: $error');
    rethrow;
  }
}


}