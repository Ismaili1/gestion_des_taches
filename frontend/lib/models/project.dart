
import './user.dart';
import 'package:flutter/foundation.dart';


class ProjectMember {
  final User user;
  final String role;

  ProjectMember({
    required this.user,
    required this.role,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    // Format: user object + pivot
    if (json['pivot'] != null && json['pivot']['role'] != null) {
      return ProjectMember(
        user: User.fromJson(json),
        role: json['pivot']['role'],
      );
    }

    // Format: nested user + role
    if (json['user'] != null && json['role'] != null) {
      return ProjectMember(
        user: User.fromJson(json['user']),
        role: json['role'],
      );
    }

    // Default fallback
    return ProjectMember(
      user: User.fromJson(json),
      role: json['role'] ?? 'member',
    );
  }
}

class Project {
  final int id;
  final String name;
  final String key;
  final String description;
  final User lead;
  final String direction;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProjectMember> members;

  Project({
    required this.id,
    required this.name,
    required this.key,
    required this.description,
    required this.lead,
    required this.direction,
    required this.createdAt,
    required this.updatedAt,
    required this.members,
  });
factory Project.fromJson(Map<String, dynamic> json) {
  // Helper function to parse dates with non-null guarantee
  DateTime parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    return DateTime.tryParse(date.toString()) ?? DateTime.now();
  }

  User parseLead(dynamic leadData, int? leadId) {
  try {
    if (leadData != null && leadData is Map<String, dynamic>) {
      return User.fromJson(leadData);
    }
    return User(
      id: leadId ?? -1,
      name: 'Unknown Lead',
      email: '',
      role: 'guest',
      direction: '',
      createdAt: DateTime.now(),
    );
  } catch (e) {
    debugPrint('Error parsing lead: $e');
    return User(
      id: leadId ?? -1,
      name: 'Error',
      email: '',
      role: 'guest',
      direction: '',
      createdAt: DateTime.now(),
    );
  }
}


  // Safe members parsing
  List<ProjectMember> parseMembers(dynamic membersData) {
    try {
      if (membersData is List) {
        return membersData
            .whereType<Map<String, dynamic>>()
            .map((m) => ProjectMember.fromJson(m))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error parsing members: $e');
      return [];
    }
  }

  return Project(
    id: json['id'] ?? -1,
    name: json['name']?.toString() ?? '',
    key: json['key']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    lead: parseLead(json['lead'], json['lead_id']),
    direction: json['direction']?.toString() ?? '',
    createdAt: parseDate(json['created_at']), // Now guaranteed non-null
    updatedAt: parseDate(json['updated_at']), // Now guaranteed non-null
    members: parseMembers(json['members']),
  );
}


  int get memberCount => members.length;
}
