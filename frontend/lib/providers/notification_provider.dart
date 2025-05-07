import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../screens/issue_detail_screen.dart';
import 'package:provider/provider.dart';  
import '../models/notification.dart';
import '../utils/http_exception.dart';
import '../providers/issue_provider.dart'; 

class NotificationProvider with ChangeNotifier {
  final String? token;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  
  
  NotificationProvider(this.token, {List<NotificationModel> previousNotifications = const []}) {
    _notifications = previousNotifications;
    _unreadCount = _notifications.where((n) => !n.readAt).length;
  }

  
  
  
  
 
  
  
  
  
  

  List<NotificationModel> get notifications => [..._notifications];
  int get unreadCount => _unreadCount;
  
  
    
  
    
  
  
  
  
  
  
  
  

  
  
  

  
  
      
  
  
  
      
  
  
  
      
  
  
  
  
  
  
  
  
    
  
    
  
  
  
  
  
  
  
  

  
  
  

  
  
      
  
  
  
      
  
  
  
      
  
  
  
  
  
  

 Future<void> handleNotificationTap(BuildContext context, NotificationModel notification) async {
    try {
      
      await markAsRead(notification.id);

      
      if (notification.issueId != null) {
        
        await Provider.of<IssueProvider>(context, listen: false)
            .fetchIssueDetails(notification.issueId!);

        
        Navigator.of(context).pushNamed(
          IssueDetailScreen.routeName,
          arguments: {
            'projectId': notification.projectId ?? 0,
            'issueId': notification.issueId!,
          },
        );
      } else {
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notification.message ?? 'Notification tapped')),
        );
      }
    } catch (error) {
      debugPrint('Error handling notification tap: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open notification')),
      );
    }
  }

  Future<void> fetchNotifications() async {
    if (token == null) return;
    
    final url = '${dotenv.env['API_URL']}/notifications';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 400) {
        throw HttpException('Failed to fetch notifications');
      }

      final responseData = json.decode(response.body);
      final List<dynamic> notificationList = responseData is List ? responseData : responseData['notifications'] ?? [];
      
      _notifications = notificationList
          .map<NotificationModel>((item) => NotificationModel.fromJson(item))
          .toList();
      
      _unreadCount = responseData is Map 
          ? (responseData['unread_count'] as int? ?? _notifications.where((n) => !n.readAt).length)
          : _notifications.where((n) => !n.readAt).length;
      
      notifyListeners();
    } catch (error) {
      debugPrint('Error fetching notifications: $error');
      rethrow;
    }
  }

    Future<void> markAsRead(int id) async {
    if (token == null) return;
    
    final url = '${dotenv.env['API_URL']}/notifications/$id/read';
    
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode >= 400) {
        throw HttpException('Failed to mark notification as read');
      }

      final index = _notifications.indexWhere((notification) => notification.id == id);
      if (index >= 0) {
        final notification = _notifications[index];
        if (!notification.readAt) {
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        }
        
        _notifications[index] = notification.copyWith(readAt: true);
        notifyListeners();
      }
    } catch (error) {
      debugPrint('Error marking notification as read: $error');
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    if (token == null) return;
    
    final url = '${dotenv.env['API_URL']}/notifications/read-all';
    
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode >= 400) {
        throw HttpException('Failed to mark all notifications as read');
      }

      _notifications = _notifications.map((notification) => notification.copyWith(readAt: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (error) {
      debugPrint('Error marking all notifications as read: $error');
      rethrow;
    }
  } 

  
  
    
  
    
  
  
  
  
  
  
  
  
      
  
  
  

  
  
  
  
  
  
        
  
  
  
  
  
  
  

  
  
    
  
    
  
  
  
  
  
  
  
  
      
  
  
  

  
  
  
  
  
  
  
  Future<void> deleteNotification(int id) async {
    if (token == null) return;
    
    final url = '${dotenv.env['API_URL']}/notifications/$id';
    
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 400) {
        throw HttpException('Failed to delete notification');
      }

      _notifications.removeWhere((notif) => notif.id == id);
      _unreadCount = _notifications.where((n) => !n.readAt).length;
      notifyListeners();
    } catch (error) {
      debugPrint('Error deleting notification: $error');
      rethrow;
    }
  }


  
  

  

  
  
  
  
  
  
  

  
  
  

  
  
  
  
  
  
  
  
  
  
  
    
  
  
  
Future<int?> openIssueFromNotification(BuildContext context, NotificationModel notification) async {
    if (notification.issueId == null) return null;
    
    try {
      
      await markAsRead(notification.id);
      
      
      final issueProvider = Provider.of<IssueProvider>(context, listen: false);
      
      
      await issueProvider.fetchIssueDetails(notification.issueId!);
      
      return notification.issueId;
    } catch (error) {
      debugPrint('Error opening issue from notification: $error');
      rethrow;
    }
  }
}
