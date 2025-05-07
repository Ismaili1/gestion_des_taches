
import 'dart:convert';
class NotificationModel {
  final int id;
  final String type;
  final Map<String, dynamic> data;
  final bool readAt;
  final DateTime createdAt;
  final String? title;
  final String? message;

  // Added these getters to easily extract issue data
  int? get issueId => data != null ? int.tryParse(data['issue_id']?.toString() ?? '') : null;
  int? get projectId => data != null ? int.tryParse(data['project_id']?.toString() ?? '') : null;

  NotificationModel({
    required this.id,
    required this.type,
    required this.data,
    required this.readAt,
    required this.createdAt,
    this.title,
    this.message,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Extract data from the JSON response
    Map<String, dynamic> notificationData = {};
    
    if (json['data'] != null) {
      // If data is a string (JSON string), try to parse it
      if (json['data'] is String) {
        try {
          notificationData = jsonDecode(json['data']);
        } catch (e) {
          notificationData = {};
        }
      } else if (json['data'] is Map) {
        notificationData = Map<String, dynamic>.from(json['data']);
      }
    }
    
    // Extract type - either from the direct type field or from data
    final String notificationType = json['type'] ?? notificationData['type'] ?? 'unknown';
    
    // Extract title and message from direct fields or from data
    final String? notificationTitle = json['title'] ?? notificationData['title'];
    final String? notificationMessage = json['message'] ?? notificationData['message'];

    return NotificationModel(
      id: json['id'] ?? 0,
      type: notificationType,
      data: notificationData,
      readAt: json['read_at'] != null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      title: notificationTitle,
      message: notificationMessage,
    );
  }

  NotificationModel copyWith({
    bool? readAt,
  }) {
    return NotificationModel(
      id: id,
      type: type,
      data: data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      title: title,
      message: message,
    );
  }
}