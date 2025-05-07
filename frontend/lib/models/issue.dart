

import './user.dart';
import 'package:flutter/foundation.dart';

class Issue {
  final int id;
  final int projectId;
  final String key;
  final String title;
  final String description;
  final String status;
  final String type;
  final String priority;
  final User reporter;
  final User? assignee;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final IssueColumn? column;
  final bool deposit;

  const Issue({
    required this.id,
    required this.projectId,
    required this.key,
    required this.title,
    required this.description,
    required this.status,
    required this.type,
    required this.priority,
    required this.reporter,
    this.assignee,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.column,
    this.deposit = false,
  });

  factory Issue.empty() => Issue(
        id: -1,
        projectId: -1,
        key: '',
        title: '',
        description: '',
        status: 'to_do',
        type: 'task',
        priority: 'medium',
        reporter: User.empty(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deposit: false,
      );

  factory Issue.fromJson(Map<String, dynamic> json) {
    try {
      // Priority mapping (handles both string and numeric priorities)
      final priority = _parsePriority(json['priority']);
      
      // Status resolution
      final status = _parseStatus(json['status'], json['column']);
      
      // Key generation fallback
      final key = _generateKey(json['key'], json['project'], json['id']);

      // Date parsing with fallbacks
      final createdAt = _parseDateTime(json['created_at']) ?? DateTime.now();
      final updatedAt = _parseDateTime(json['updated_at']) ?? DateTime.now();
      final dueDate = _parseDateTime(json['due_date']);

      return Issue(
        id: _parseInt(json['id']) ?? -1,
        projectId: _parseInt(json['project_id']) ?? -1,
        key: key,
        title: json['title']?.toString() ?? 'Untitled',
        description: json['description']?.toString() ?? '',
        status: status,
        type: (json['type']?.toString() ?? 'task').toLowerCase(),
        priority: priority,
        reporter: json['reporter'] != null 
            ? User.fromJson(json['reporter']) 
            : User.empty(),
        assignee: json['assignee'] != null 
            ? User.fromJson(json['assignee']) 
            : null,
        dueDate: dueDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
        column: json['column'] != null 
            ? IssueColumn.fromJson(json['column']) 
            : null,
        deposit: json['deposit'] != null 
            ? json['deposit'] == true || json['deposit'] == 1 
            : false,
      );
    } catch (e, stack) {
      debugPrint('Error parsing Issue: $e');
      debugPrint(stack.toString());
      return Issue.empty();
    }
  }

  static String _parsePriority(dynamic priority) {
    const priorityMap = {
      1: 'low',
      2: 'medium',
      3: 'high',
      '1': 'low',
      '2': 'medium',
      '3': 'high',
    };

    final priorityStr = priority?.toString().toLowerCase() ?? 'medium';
    return priorityMap[priority] ?? priorityStr;
  }

  static String _parseStatus(dynamic status, dynamic column) {
    const statusMap = {
      'to_do': 'To Do',
      'seen': 'Seen',
      'in_progress': 'In Progress',
      'in_review': 'In Review',
      'done': 'Done',
    };

    final columnStatus = column?['name']?.toString();
    final statusStr = (status ?? columnStatus ?? 'to_do').toString();
    return statusMap[statusStr.toLowerCase()] ?? statusStr;
  }

  static String _generateKey(dynamic key, dynamic project, dynamic id) {
    if (key?.toString().isNotEmpty == true) return key.toString();

    final projectKey = project?['key']?.toString();
    final issueId = id?.toString();

    if (projectKey != null && issueId != null) {
      return '$projectKey-$issueId';
    }
    return 'ISSUE-${id ?? 'X'}';
  }

  static DateTime? _parseDateTime(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return date;
    return DateTime.tryParse(date.toString());
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'key': key,
        'title': title,
        'description': description,
        'status': status,
        'type': type,
        'priority': priority,
        'reporter': reporter.toJson(),
        'assignee': assignee?.toJson(),
        'due_date': dueDate?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'column': column?.toJson(),
        'deposit': deposit ? 1 : 0,
      };

  Issue copyWith({
    int? id,
    int? projectId,
    String? key,
    String? title,
    String? description,
    String? status,
    String? type,
    String? priority,
    User? reporter,
    User? assignee,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    IssueColumn? column,
    bool? deposit,
  }) =>
      Issue(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        key: key ?? this.key,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        type: type ?? this.type,
        priority: priority ?? this.priority,
        reporter: reporter ?? this.reporter,
        assignee: assignee ?? this.assignee,
        dueDate: dueDate ?? this.dueDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        column: column ?? this.column,
        deposit: deposit ?? this.deposit,
      );
}

class IssueColumn {
  final int id;
  final String name;
  final int position;
  final int projectId;
  final int boardId;

  const IssueColumn({
    required this.id,
    required this.name,
    required this.position,
    required this.projectId,
    required this.boardId,
  });

  factory IssueColumn.fromJson(Map<String, dynamic> json) {
    try {
      return IssueColumn(
        id: _parseInt(json['id']) ?? 0,
        name: json['name']?.toString() ?? 'Unnamed Column',
        position: _parseInt(json['position']) ?? 0,
        projectId: _parseInt(json['project_id']) ?? 0,
        boardId: _parseInt(json['board_id']) ?? 0,
      );
    } catch (e) {
      debugPrint('Error parsing IssueColumn: $e');
      return const IssueColumn(
        id: -1,
        name: 'Invalid',
        position: 0,
        projectId: -1,
        boardId: -1,
      );
    }
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'position': position,
        'project_id': projectId,
        'board_id': boardId,
      };

  IssueColumn copyWith({
    int? id,
    String? name,
    int? position,
    int? projectId,
    int? boardId,
  }) =>
      IssueColumn(
        id: id ?? this.id,
        name: name ?? this.name,
        position: position ?? this.position,
        projectId: projectId ?? this.projectId,
        boardId: boardId ?? this.boardId,
      );
}