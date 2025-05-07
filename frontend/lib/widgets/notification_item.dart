// // lib/widgets/notification_item.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/notification.dart';
import '../providers/notification_provider.dart';
import '../providers/project_provider.dart';
import '../screens/project_detail_screen.dart';
import '../screens/issue_detail_screen.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  
  const NotificationItem(this.notification, {super.key});
  
  // Helper method to safely parse potentially different types to int
  int? _safelyParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      // Remove any non-numeric characters (like '%')
      final numericString = value.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(numericString);
    }
    return null;
  }
  
  @override
  Widget build(BuildContext context) {
    // Extract data for displaying the notification
    final String title = notification.title ?? 
                        notification.data['title'] ?? 
                        _getDefaultTitle(notification.type);
    
    final String message = notification.message ?? 
                          notification.data['message'] ?? 
                          _getDefaultMessage(notification);
                          
    // Extract project and issue IDs for navigation with safe parsing
    final Map<String, dynamic> data = notification.data;
    final int? projectId = _safelyParseInt(data['project_id']) ?? _safelyParseInt(data['projectId']);
    final int? issueId = _safelyParseInt(data['issue_id']) ?? _safelyParseInt(data['issueId']);

    // Build the notification card
    return Dismissible(
      key: ValueKey(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        Provider.of<NotificationProvider>(context, listen: false)
            .deleteNotification(notification.id);
      },
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Notification'),
            content: const Text('Are you sure you want to delete this notification?'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(ctx).pop(false);
                },
              ),
              TextButton(
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.of(ctx).pop(true);
                },
              ),
            ],
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: () async {
            // Mark as read
            if (!notification.readAt) {
              await Provider.of<NotificationProvider>(context, listen: false)
                  .markAsRead(notification.id);
            }
            
            // Navigate only if we have valid IDs
            if (projectId != null) {
              if (notification.type == 'issue' && issueId != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => IssueDetailScreen(
                      projectId: projectId,
                      issueId: issueId,
                    ),
                  ),
                );
              } else {
                // Navigate to project screen for both project-related notifications
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => ProjectDetailScreen(projectId),
                  ),
                );
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!notification.readAt)
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 4, right: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: notification.readAt ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, yyyy • h:mm a').format(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                _getNotificationIcon(notification.type),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper method to get a default title based on notification type
  String _getDefaultTitle(String type) {
    switch (type) {
      case 'project':
        return 'Project Notification';
      case 'issue':
        return 'Issue Notification';
      case 'mention':
        return 'You were mentioned';
      case 'system':
        return 'System Notification';
      default:
        return 'Notification';
    }
  }
  
  // Helper method to get a default message if none is provided
  String _getDefaultMessage(NotificationModel notification) {
    switch (notification.type) {
      case 'project':
        final projectName = notification.data['project_name'] ?? 'a project';
        return 'You have a new notification about $projectName';
      case 'issue':
        return 'You have a new issue notification';
      default:
        return 'You have a new notification';
    }
  }
  
  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'project':
        return const Icon(Icons.folder, color: Colors.blue);
      case 'issue':
        return const Icon(Icons.bug_report, color: Colors.orange);
      case 'mention':
        return const Icon(Icons.alternate_email, color: Colors.purple);
      case 'system':
        return const Icon(Icons.info, color: Colors.grey);
      default:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }
}