// lib/models/comment.dart
import './user.dart';

class Comment {
  final int id;
  final int issueId;
  final String content;
  final User author;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.issueId,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
  });

factory Comment.fromJson(Map<String, dynamic> json) {
  try {
    return Comment(
      id: json['id'],
      issueId: json['issue_id'],
      content: json['content'],
      author: User.fromJson(json['user']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  } catch (e) {
    print('Error parsing comment: $e');
    print('JSON data: $json');
    rethrow;
  }
}
}