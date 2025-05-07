// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import '../providers/issue_provider.dart';
// import '../providers/auth_provider.dart';
// import '../utils/http_exception.dart';
// import '../models/issue.dart';
// import '../models/comment.dart';
// import './issue_form_screen.dart';

// class IssueDetailScreen extends StatefulWidget {
//   static const routeName = '/issue-detail';
//   final int projectId;
//   final int issueId;

//   const IssueDetailScreen({super.key, required this.projectId, required this.issueId});

//   @override
//   State<IssueDetailScreen> createState() => _IssueDetailScreenState();
// }

// class _IssueDetailScreenState extends State<IssueDetailScreen> {
//   var _isLoading = false;
//   var _isLoadingComments = false;
//   List<Comment> _comments = [];
//   final _commentController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _loadIssue();
//     _loadComments();
//   }

//   Future<void> _loadIssue() async {
//     setState(() => _isLoading = true);
//     try {
//       await Provider.of<IssueProvider>(context, listen: false)
//           .fetchIssueDetails(widget.issueId);
//     } catch (error) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to load issue: $error')),
//       );
//     }
//     setState(() => _isLoading = false);
//   }

//   Future<void> _loadComments() async {
//     setState(() => _isLoadingComments = true);
//     try {
//       final comments = await Provider.of<IssueProvider>(context, listen: false)
//           .fetchIssueComments(widget.projectId, widget.issueId);
//       setState(() => _comments = comments);
//     } catch (error) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to load comments: $error')),
//       );
//     }
//     setState(() => _isLoadingComments = false);
//   }

//   Future<void> _addComment() async {
//     if (_commentController.text.isEmpty) return;
//     setState(() => _isLoading = true);
//     try {
//       final newComment = await Provider.of<IssueProvider>(context, listen: false)
//           .addComment(widget.projectId, widget.issueId, _commentController.text);
//       setState(() {
//         _comments.insert(0, newComment);
//         _commentController.clear();
//       });
//     } catch (error) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to add comment: $error')),
//       );
//     }
//     setState(() => _isLoading = false);
//   }

//   Future<void> _changeStatusWithComment(
//     int issueId, 
//     String status, 
//     String comment,
//   ) async {
//     try {
//       setState(() => _isLoading = true);
      
//       final currentStatus = Provider.of<IssueProvider>(context, listen: false)
//           .findById(issueId)
//           .status
//           .toLowerCase()
//           .replaceAll(' ', '_');

//       final newStatus = status.toLowerCase().replaceAll(' ', '_');

//       if (!_isValidTransition(currentStatus, newStatus)) {
//         throw HttpException('Invalid status transition from $currentStatus to $newStatus');
//       }

//       await Provider.of<IssueProvider>(
//         context, 
//         listen: false,
//       ).changeStatus(issueId, newStatus, comment: comment);

//       await _loadIssue();
//       await _loadComments();
//     } catch (error) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(error.toString())),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   bool _isValidTransition(String currentStatus, String newStatus) {
//     final validTransitions = {
//       'to_do': ['in_progress'],
//       'seen': ['in_progress'],
//       'in_progress': ['in_review'],
//       'in_review': ['in_progress', 'done'],
//     };

//     return validTransitions[currentStatus]?.contains(newStatus) ?? false;
//   }

//   // Check if current user has edit permission for this issue
//   bool _hasEditPermission(Issue issue, dynamic currentUser) {
//     // Admin or super admin can edit any issue
//     if (currentUser?.role == 'admin' || currentUser?.role == 'superadmin') {
//       return true;
//     }
    
//     // Normal users can only edit issues assigned to them
//     return issue.assignee?.id == currentUser?.id;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final issue = Provider.of<IssueProvider>(context).findById(widget.issueId);
//     final currentUser = Provider.of<AuthProvider>(context).user;
//     final isAssignee = issue.assignee?.id == currentUser?.id;
//     final isAdmin = currentUser?.role == 'admin' || currentUser?.role == 'superadmin';
//     final isDone = issue.status.toLowerCase().replaceAll(' ', '_') == 'done';
    
//     // Check if user has edit permission
//     final canEdit = _hasEditPermission(issue, currentUser);

//     List<Widget> actionButtons = [];

//     if (isAssignee && !isDone) {
//       if (issue.status.toLowerCase() == 'seen') {
//         actionButtons.add(
//           ElevatedButton(
//             onPressed: () async {
//               await _changeStatusWithComment(
//                 issue.id, 
//                 'in_progress', 
//                 'Started working on this issue'
//               );
//             },
//             child: const Text('Start Working'),
//           ),
//         );
//       } else if (!isDone) {
//         actionButtons.add(
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text('Review Mode:'),
//               const SizedBox(width: 8),
//               Switch(
//                 value: issue.status.toLowerCase().replaceAll(' ', '_') == 'in_review',
//                 onChanged: (bool isInReview) async {
//                   final newStatus = isInReview ? 'in_review' : 'in_progress';
//                   final comment = isInReview 
//                       ? 'Sent to review' 
//                       : 'Returned to progress';
//                   await _changeStatusWithComment(issue.id, newStatus, comment);
//                 },
//                 activeColor: Colors.orange,
//               ),
//             ],
//           ),
//         );
//       }
//     }

//     if (isAdmin && 
//         issue.status.toLowerCase().replaceAll(' ', '_') == 'in_review' && 
//         !isDone) {
//       actionButtons.add(
//         const SizedBox(width: 16),
//       );
//       actionButtons.add(
//         ElevatedButton(
//           onPressed: () async {
//             await _changeStatusWithComment(
//               issue.id,
//               'done',
//               'Marked as done by admin',
//             );
//           },
//           child: const Text('Approve as Done'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.green,
//             foregroundColor: Colors.white,
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('${issue.key} - Issue'),
//         actions: [
//           // Only show edit button if user has permission
//           if (canEdit)
//             IconButton(
//               icon: const Icon(Icons.edit),
//               onPressed: () {
//                 Navigator.of(context).push(
//                   MaterialPageRoute(
//                     builder: (ctx) => IssueFormScreen(
//                       projectId: widget.projectId,
//                       issueId: widget.issueId,
//                     ),
//                   ),
//                 );
//               },
//             ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Card(
//                     margin: const EdgeInsets.only(bottom: 16),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                 decoration: BoxDecoration(
//                                   color: _getTypeColor(issue.type),
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                                 child: Text(
//                                   issue.type,
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                 decoration: BoxDecoration(
//                                   color: _getPriorityColor(issue.priority),
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                                 child: Text(
//                                   issue.priority,
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                               const Spacer(),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                 decoration: BoxDecoration(
//                                   color: _getStatusColor(issue.status),
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                                 child: Text(
//                                   issue.status,
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           Text(
//                             issue.title,
//                             style: const TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           Text(
//                             issue.description,
//                             style: const TextStyle(fontSize: 16),
//                           ),
//                           const SizedBox(height: 16),
//                           const Divider(),
//                           Row(
//                             children: [
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'Reporter',
//                                     style: TextStyle(
//                                       color: Colors.grey[600],
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                   Text(issue.reporter.name),
//                                 ],
//                               ),
//                               const SizedBox(width: 24),
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'Assignee',
//                                     style: TextStyle(
//                                       color: Colors.grey[600],
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                   Text(issue.assignee?.name ?? 'Unassigned'),
//                                 ],
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 8),
//                           Row(
//                             children: [
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'Created',
//                                     style: TextStyle(
//                                       color: Colors.grey[600],
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                   Text(DateFormat('MMM d, yyyy').format(issue.createdAt)),
//                                 ],
//                               ),
//                               const SizedBox(width: 24),
//                               if (issue.dueDate != null)
//                                 Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Due Date',
//                                       style: TextStyle(
//                                         color: Colors.grey[600],
//                                         fontSize: 12,
//                                       ),
//                                     ),
//                                     Text(DateFormat('MMM d, yyyy').format(issue.dueDate!)),
//                                   ],
//                                 ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                   if (actionButtons.isNotEmpty && !isDone)
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 16),
//                       child: Row(
//                         children: actionButtons,
//                       ),
//                     ),

//                   const Text(
//                     'Comments',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   _isLoadingComments
//                       ? const Center(child: CircularProgressIndicator())
//                       : _comments.isEmpty
//                           ? const Card(
//                               child: Padding(
//                                 padding: EdgeInsets.all(16.0),
//                                 child: Center(
//                                   child: Text('No comments yet'),
//                                 ),
//                               ),
//                             )
//                           : Column(
//                               children: _comments.map((comment) {
//                                 return Card(
//                                   margin: const EdgeInsets.only(bottom: 8),
//                                   child: Padding(
//                                     padding: const EdgeInsets.all(16.0),
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Row(
//                                           children: [
//                                             CircleAvatar(
//                                               radius: 16,
//                                               child: Text(comment.author.name[0]),
//                                             ),
//                                             const SizedBox(width: 8),
//                                             Text(
//                                               comment.author.name,
//                                               style: const TextStyle(fontWeight: FontWeight.bold),
//                                             ),
//                                             const Spacer(),
//                                             Text(
//                                               DateFormat('MMM d, yyyy • h:mm a').format(comment.createdAt),
//                                               style: TextStyle(
//                                                 color: Colors.grey[600],
//                                                 fontSize: 12,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 8),
//                                         Text(comment.content),
//                                       ],
//                                     ),
//                                   ),
//                                 );
//                               }).toList(),
//                             ),
//                 ],
//               ),
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Theme.of(context).cardColor,
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 4,
//                   offset: Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _commentController,
//                     decoration: const InputDecoration(
//                       hintText: 'Add a comment...',
//                       border: OutlineInputBorder(),
//                     ),
//                     maxLines: 3,
//                     minLines: 1,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 _isLoading
//                     ? const CircularProgressIndicator()
//                     : IconButton(
//                         icon: const Icon(Icons.send),
//                         onPressed: _addComment,
//                       ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getTypeColor(String type) {
//     switch (type.toLowerCase()) {
//       case 'bug':
//         return Colors.red;
//       case 'feature':
//       case 'story':
//         return Colors.green;
//       case 'task':
//         return Colors.blue;
//       case 'epic':
//         return Colors.purple;
//       default:
//         return Colors.grey;
//     }
//   }

//   Color _getPriorityColor(String priority) {
//     switch (priority.toLowerCase()) {
//       case 'high':
//         return Colors.red;
//       case 'medium':
//         return Colors.orange;
//       case 'low':
//         return Colors.green;
//       default:
//         return Colors.blue;
//     }
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'to do':
//         return Colors.grey;
//       case 'seen':
//         return Colors.blueGrey;
//       case 'in progress':
//         return Colors.blue;
//       case 'in review':
//         return Colors.orange;
//       case 'done':
//         return Colors.green;
//       default:
//         return Colors.purple;
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/issue_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/http_exception.dart';
import '../models/issue.dart';
import '../models/comment.dart';
import './issue_form_screen.dart';

class IssueDetailScreen extends StatefulWidget {
  static const routeName = '/issue-detail';
  final int projectId;
  final int issueId;

  const IssueDetailScreen({super.key, required this.projectId, required this.issueId});

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  var _isLoading = false;
  var _isLoadingComments = false;
  List<Comment> _comments = [];
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadIssue();
    _loadComments();
  }

  Future<void> _loadIssue() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<IssueProvider>(context, listen: false)
          .fetchIssueDetails(widget.issueId);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load issue: $error')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final comments = await Provider.of<IssueProvider>(context, listen: false)
          .fetchIssueComments(widget.projectId, widget.issueId);
      setState(() => _comments = comments);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load comments: $error')),
      );
    }
    setState(() => _isLoadingComments = false);
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final newComment = await Provider.of<IssueProvider>(context, listen: false)
          .addComment(widget.projectId, widget.issueId, _commentController.text);
      setState(() {
        // _comments.insert(0, newComment);
        if (newComment != null) {
  setState(() {
    _comments.insert(0, newComment);
    _commentController.clear();
  });
}

        _commentController.clear();
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: $error')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteIssue() async {
    // Show confirmation dialog before deleting
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Issue'),
        content: const Text(
          'Are you sure you want to delete this issue? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      await Provider.of<IssueProvider>(context, listen: false).deleteIssue(widget.issueId);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issue deleted successfully')),
      );
      
      // Navigate back after successful deletion
      Navigator.of(context).pop();
    } catch (error) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete issue: $error')),
      );
    }
  }

  Future<void> _changeStatusWithComment(
    int issueId, 
    String status, 
    String comment,
  ) async {
    try {
      setState(() => _isLoading = true);
      
      final currentStatus = Provider.of<IssueProvider>(context, listen: false)
          .findById(issueId)
          ?.status
          .toLowerCase()
          .replaceAll(' ', '_');

      final newStatus = status.toLowerCase().replaceAll(' ', '_');

      if (!_isValidTransition(currentStatus!, newStatus)) {
        throw HttpException('Invalid status transition from $currentStatus to $newStatus');
      }

      await Provider.of<IssueProvider>(
        context, 
        listen: false,
      ).changeStatus(issueId, newStatus, comment: comment);

      await _loadIssue();
      await _loadComments();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isValidTransition(String currentStatus, String newStatus) {
    final validTransitions = {
      'to_do': ['in_progress'],
      'seen': ['in_progress'],
      'in_progress': ['in_review'],
      'in_review': ['in_progress', 'done'],
    };

    return validTransitions[currentStatus]?.contains(newStatus) ?? false;
  }

  // Check if current user has edit permission for this issue
  bool _hasEditPermission(Issue issue, dynamic currentUser) {
    // Admin or super admin can edit any issue
    if (currentUser?.role == 'admin' || currentUser?.role == 'superadmin') {
      return true;
    }
    
    // Normal users can only edit issues assigned to them
    return issue.assignee?.id == currentUser?.id;
  }

  // Check if current user has admin permission
  bool _isAdmin(dynamic currentUser) {
    return currentUser?.role == 'admin' || currentUser?.role == 'superadmin';
  }

  @override
  Widget build(BuildContext context) {
    final issue = Provider.of<IssueProvider>(context).findById(widget.issueId);
    final currentUser = Provider.of<AuthProvider>(context).user;
    final isAssignee = issue?.assignee?.id == currentUser?.id;
    final isAdmin = _isAdmin(currentUser);
    final isDone = issue?.status.toLowerCase().replaceAll(' ', '_') == 'done';
    final isDeposited = issue?.deposit == true; // Check if issue is deposited
    
    // Check if user has edit permission
    final canEdit = _hasEditPermission(issue!, currentUser);

    List<Widget> actionButtons = [];

    // Show delete button only for admin/superadmin
    if (isAdmin) {
      actionButtons.add(
        ElevatedButton.icon(
          icon: const Icon(Icons.delete),
          label: const Text('Delete Issue'),
          onPressed: isDeposited ? null : _deleteIssue, // Disable if deposited
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.red.withOpacity(0.3),
          ),
        ),
      );
      
      // Show tooltip if deposited
      if (isDeposited) {
        actionButtons.add(
          const Tooltip(
            message: 'Cannot delete deposited issues',
            child: Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.info_outline, color: Colors.orange),
            ),
          ),
        );
      }
      
      actionButtons.add(const SizedBox(width: 16));
    }

    if (isAssignee && !isDone) {
      if (issue.status.toLowerCase() == 'seen') {
        actionButtons.add(
          ElevatedButton(
            onPressed: () async {
              await _changeStatusWithComment(
                issue.id, 
                'in_progress', 
                'Started working on this issue'
              );
            },
            child: const Text('Start Working'),
          ),
        );
      } else if (!isDone) {
        actionButtons.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Review Mode:'),
              const SizedBox(width: 8),
              Switch(
                value: issue.status.toLowerCase().replaceAll(' ', '_') == 'in_review',
                onChanged: (bool isInReview) async {
                  final newStatus = isInReview ? 'in_review' : 'in_progress';
                  final comment = isInReview 
                      ? 'Sent to review' 
                      : 'Returned to progress';
                  await _changeStatusWithComment(issue.id, newStatus, comment);
                },
                activeColor: Colors.orange,
              ),
            ],
          ),
        );
      }
    }

    if (isAdmin && 
        issue.status.toLowerCase().replaceAll(' ', '_') == 'in_review' && 
        !isDone) {
      actionButtons.add(
        const SizedBox(width: 16),
      );
      actionButtons.add(
        ElevatedButton(
          onPressed: () async {
            await _changeStatusWithComment(
              issue.id,
              'done',
              'Marked as done by admin',
            );
          },
          child: const Text('Approve as Done'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${issue.key} - Issue'),
        actions: [
          // Only show edit button if user has permission
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => IssueFormScreen(
                      projectId: widget.projectId,
                      issueId: widget.issueId,
                    ),
                  ),
                );
              },
            ),
          // Add delete button in app bar for admin/superadmin
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: isDeposited ? null : _deleteIssue, // Disable if deposited
              tooltip: isDeposited ? 'Cannot delete deposited issues' : 'Delete Issue',
              color: isDeposited ? Colors.grey : Colors.red,
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getTypeColor(issue.type),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  issue.type,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(issue.priority),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  issue.priority,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(issue.status),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  issue.status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isDeposited)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Tooltip(
                                    message: 'Deposited Issue',
                                    child: Icon(Icons.lock_outline, 
                                      size: 16, 
                                      color: Colors.blue[800]
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            issue.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            issue.description,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reporter',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(issue.reporter.name),
                                ],
                              ),
                              const SizedBox(width: 24),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Assignee',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(issue.assignee?.name ?? 'Unassigned'),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Created',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(DateFormat('MMM d, yyyy').format(issue.createdAt)),
                                ],
                              ),
                              const SizedBox(width: 24),
                              if (issue.dueDate != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Due Date',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(DateFormat('MMM d, yyyy').format(issue.dueDate!)),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (actionButtons.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: actionButtons,
                      ),
                    ),

                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _isLoadingComments
                      ? const Center(child: CircularProgressIndicator())
                      : _comments.isEmpty
                          ? const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text('No comments yet'),
                                ),
                              ),
                            )
                          : Column(
                              children: _comments.map((comment) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              child: Text(comment.author.name[0]),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              comment.author.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const Spacer(),
                                            Text(
                                              DateFormat('MMM d, yyyy • h:mm a').format(comment.createdAt),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(comment.content),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                _isLoading
                    ? const CircularProgressIndicator()
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _addComment,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'bug':
        return Colors.red;
      case 'feature':
      case 'story':
        return Colors.green;
      case 'task':
        return Colors.blue;
      case 'epic':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'to do':
        return Colors.grey;
      case 'seen':
        return Colors.blueGrey;
      case 'in progress':
        return Colors.blue;
      case 'in review':
        return Colors.orange;
      case 'done':
        return Colors.green;
      default:
        return Colors.purple;
    }
  }
}