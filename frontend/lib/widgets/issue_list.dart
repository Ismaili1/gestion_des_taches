  // // lib/widgets/issue_list.dart
  // import 'package:flutter/material.dart';
  // import 'package:provider/provider.dart';
  // import '../providers/issue_provider.dart';
  // import '../providers/auth_provider.dart';
  // import '../models/issue.dart';
  // import '../screens/issue_detail_screen.dart';

  // class IssueList extends StatefulWidget {
  //   final int projectId;
    
  //   const IssueList(this.projectId, {super.key});
    
  //   @override
  //   State<IssueList> createState() => _IssueListState();
  // }

  // class _IssueListState extends State<IssueList> {
  //   String _searchQuery = '';
    
  //   @override
  //   Widget build(BuildContext context) {
  //     final issueProvider = Provider.of<IssueProvider>(context);
  //     final allIssues = issueProvider.getProjectIssues(widget.projectId);
      
  //     // Filter issues based on search query
  //     final issues = _searchQuery.isEmpty 
  //         ? allIssues 
  //         : allIssues.where((issue) {
  //             final query = _searchQuery.toLowerCase();
  //             return issue.title.toLowerCase().contains(query) ||
  //                   issue.key.toLowerCase().contains(query) ||
  //                   issue.description.toLowerCase().contains(query) ||
  //                   issue.status.toLowerCase().contains(query) ||
  //                   issue.type.toLowerCase().contains(query) ||
  //                   issue.priority.toLowerCase().contains(query) ||
  //                   (issue.assignee?.name.toLowerCase().contains(query) ?? false);
  //           }).toList();

  //     if (allIssues.isEmpty) {
  //       return Center(
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             const Icon(
  //               Icons.description,
  //               size: 80,
  //               color: Colors.grey,
  //             ),
  //             const SizedBox(height: 16),
  //             Text(
  //               'No issues found',
  //               style: TextStyle(
  //                 fontSize: 18,
  //                 color: Colors.grey[600],
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             Text(
  //               'Create your first issue to get started',
  //               style: TextStyle(
  //                 color: Colors.grey[600],
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     }
      
  //     return Column(
  //       children: [
  //         Padding(
  //           padding: const EdgeInsets.all(16.0),
  //           child: TextField(
  //             decoration: InputDecoration(
  //               labelText: 'Search Issues',
  //               hintText: 'Search by title, key, status, type...',
  //               prefixIcon: const Icon(Icons.search),
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               suffixIcon: _searchQuery.isNotEmpty 
  //                 ? IconButton(
  //                     icon: const Icon(Icons.clear),
  //                     onPressed: () {
  //                       setState(() {
  //                         _searchQuery = '';
  //                       });
  //                       // Clear the text field
  //                       FocusScope.of(context).unfocus();
  //                     },
  //                   )
  //                 : null,
  //             ),
  //             onChanged: (value) {
  //               setState(() {
  //                 _searchQuery = value;
  //               });
  //             },
  //           ),
  //         ),
  //         Expanded(
  //           child: issues.isEmpty
  //             ? Center(
  //                 child: Column(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     const Icon(
  //                       Icons.search_off,
  //                       size: 64,
  //                       color: Colors.grey,
  //                     ),
  //                     const SizedBox(height: 16),
  //                     Text(
  //                       'No issues match your search',
  //                       style: TextStyle(
  //                         fontSize: 16,
  //                         color: Colors.grey[600],
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               )
  //             : ListView.builder(
  //                 padding: const EdgeInsets.all(8),
  //                 itemCount: issues.length,
  //                 itemBuilder: (ctx, i) => IssueCard(
  //                   projectId: widget.projectId,
  //                   issue: issues[i],
  //                   onTap: () {
  //                     Navigator.of(context).push(
  //                       MaterialPageRoute(
  //                         builder: (ctx) => IssueDetailScreen(
  //                           projectId: widget.projectId,
  //                           issueId: issues[i].id,
  //                         ),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //               ),
  //         ),
  //       ],
  //     );
  //   }
  // }

  // class IssueCard extends StatefulWidget {
  //   final int projectId;
  //   final Issue issue;
  //   final VoidCallback onTap;
    
  //   const IssueCard({
  //     super.key,
  //     required this.projectId,
  //     required this.issue,
  //     required this.onTap,
  //   });
    
  //   @override
  //   State<IssueCard> createState() => _IssueCardState();
  // }

  // class _IssueCardState extends State<IssueCard> {
  //   var _isDeleting = false;

  //   @override
  //   Widget build(BuildContext context) {
  //     final authProvider = Provider.of<AuthProvider>(context, listen: false);
  //     final currentUser = authProvider.user;
  //     final isAdmin = currentUser?.role == 'admin' || currentUser?.role == 'superadmin';
  //     final isDeposited = widget.issue.deposit == true;
      
  //     return Card(
  //       margin: const EdgeInsets.only(bottom: 8),
  //       child: InkWell(
  //         onTap: widget.onTap,
  //         borderRadius: BorderRadius.circular(4),
  //         child: Padding(
  //           padding: const EdgeInsets.all(16.0),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 children: [
  //                   Container(
  //                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                     decoration: BoxDecoration(
  //                       color: _getTypeColor(widget.issue.type),
  //                       borderRadius: BorderRadius.circular(4),
  //                     ),
  //                     child: Text(
  //                       widget.issue.type,
  //                       style: const TextStyle(
  //                         color: Colors.white,
  //                         fontWeight: FontWeight.bold,
  //                         fontSize: 12,
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 8),
  //                   Text(
  //                     widget.issue.key,
  //                     style: TextStyle(
  //                       color: Colors.grey[600],
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                   const Spacer(),
  //                   if (isDeposited)
  //                     Padding(
  //                       padding: const EdgeInsets.only(right: 8.0),
  //                       child: Tooltip(
  //                         message: 'Deposited Issue',
  //                         child: Icon(
  //                           Icons.lock_outline, 
  //                           size: 16, 
  //                           color: Colors.blue[800],
  //                         ),
  //                       ),
  //                     ),
  //                   // Add delete button for admin/superadmin users
  //                   if (isAdmin)
  //                     _isDeleting
  //                       ? const SizedBox(
  //                           height: 20, 
  //                           width: 20, 
  //                           child: CircularProgressIndicator(strokeWidth: 2),
  //                         )
  //                       : IconButton(
  //                           icon: const Icon(Icons.delete_outline, size: 20),
  //                           color: Colors.red,
  //                           tooltip: isDeposited 
  //                             ? 'Cannot delete deposited issues' 
  //                             : 'Delete Issue',
  //                           onPressed: isDeposited 
  //                             ? null 
  //                             : () => _confirmDeleteIssue(context),
  //                           constraints: const BoxConstraints(),
  //                           padding: const EdgeInsets.only(right: 8),
  //                           visualDensity: VisualDensity.compact,
  //                         ),
  //                   Container(
  //                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                     decoration: BoxDecoration(
  //                       color: _getStatusColor(widget.issue.status),
  //                       borderRadius: BorderRadius.circular(4),
  //                     ),
  //                     child: Text(
  //                       widget.issue.status,
  //                       style: const TextStyle(
  //                         color: Colors.white,
  //                         fontWeight: FontWeight.bold,
  //                         fontSize: 12,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 8),
  //               Text(
  //                 widget.issue.title,
  //                 style: const TextStyle(
  //                   fontWeight: FontWeight.bold,
  //                   fontSize: 16,
  //                 ),
  //               ),
  //               const SizedBox(height: 8),
  //               Row(
  //                 children: [
  //                   Icon(
  //                     Icons.flag,
  //                     size: 16,
  //                     color: _getPriorityColor(widget.issue.priority),
  //                   ),
  //                   const SizedBox(width: 4),
  //                   Text(
  //                     widget.issue.priority,
  //                     style: TextStyle(
  //                       color: Colors.grey[600],
  //                       fontSize: 12,
  //                     ),
  //                   ),
  //                   const SizedBox(width: 16),
  //                   Icon(
  //                     Icons.person_outline,
  //                     size: 16,
  //                     color: Colors.grey[600],
  //                   ),
  //                   const SizedBox(width: 4),
  //                   Text(
  //                     widget.issue.assignee?.name ?? 'Unassigned',
  //                     style: TextStyle(
  //                       color: Colors.grey[600],
  //                       fontSize: 12,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     );
  //   }
    
  //   // Show confirmation dialog before deleting issue
  //   Future<void> _confirmDeleteIssue(BuildContext context) async {
  //     final confirmed = await showDialog<bool>(
  //       context: context,
  //       builder: (ctx) => AlertDialog(
  //         title: const Text('Delete Issue'),
  //         content: Text(
  //           'Are you sure you want to delete issue ${widget.issue.key} - ${widget.issue.title}?\n\nThis action cannot be undone.',
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(ctx).pop(false),
  //             child: const Text('Cancel'),
  //           ),
  //           TextButton(
  //             onPressed: () => Navigator.of(ctx).pop(true),
  //             style: TextButton.styleFrom(foregroundColor: Colors.red),
  //             child: const Text('Delete'),
  //           ),
  //         ],
  //       ),
  //     ) ?? false;

  //     if (!confirmed) return;

  //     // Proceed with deletion
  //     setState(() => _isDeleting = true);
  //     try {
  //       await Provider.of<IssueProvider>(context, listen: false)
  //           .deleteIssue(widget.issue.id);
        
  //       // Show success message
  //       if (!mounted) return;
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Issue ${widget.issue.key} deleted successfully')),
  //       );
  //     } catch (error) {
  //       // Show error message
  //       if (!mounted) return;
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Failed to delete issue: $error')),
  //       );
  //       setState(() => _isDeleting = false);
  //     }
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
import '../providers/issue_provider.dart';
import '../providers/auth_provider.dart';
import '../models/issue.dart';
import '../screens/issue_detail_screen.dart';

class IssueList extends StatefulWidget {
  final int projectId;
  
  const IssueList(this.projectId, {super.key});
  
  @override
  State<IssueList> createState() => _IssueListState();
}

class _IssueListState extends State<IssueList> {
  String _searchQuery = '';
  bool _isLoading = false;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIssues();
    });
  }

  Future<void> _loadIssues() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      await Provider.of<IssueProvider>(context, listen: false)
          .fetchProjectIssues(widget.projectId);
    } catch (e) {
      debugPrint('Error loading issues: $e');
      setState(() => _hasError = true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final issueProvider = Provider.of<IssueProvider>(context);
    final allIssues = issueProvider.getProjectIssues(widget.projectId);
    
    // Filter issues based on search query
    final issues = _searchQuery.isEmpty 
        ? allIssues 
        : allIssues.where((issue) {
            final query = _searchQuery.toLowerCase();
            return issue.title.toLowerCase().contains(query) ||
                  issue.key.toLowerCase().contains(query) ||
                  issue.description.toLowerCase().contains(query) ||
                  issue.status.toLowerCase().contains(query) ||
                  issue.type.toLowerCase().contains(query) ||
                  issue.priority.toLowerCase().contains(query) ||
                  (issue.assignee?.name.toLowerCase().contains(query) ?? false);
          }).toList();

    if (_isLoading && allIssues.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load issues',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadIssues,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (allIssues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No issues in project ${widget.projectId}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadIssues,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Issues',
              hintText: 'Search by title, key, status...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        if (_isLoading) 
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadIssues,
            child: issues.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No issues match your search',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: issues.length,
                  itemBuilder: (ctx, i) => IssueCard(
                    projectId: widget.projectId,
                    issue: issues[i],
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => IssueDetailScreen(
                            projectId: widget.projectId,
                            issueId: issues[i].id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

class IssueCard extends StatefulWidget {
  final int projectId;
  final Issue issue;
  final VoidCallback onTap;
  
  const IssueCard({
    super.key,
    required this.projectId,
    required this.issue,
    required this.onTap,
  });
  
  @override
  State<IssueCard> createState() => _IssueCardState();
}

class _IssueCardState extends State<IssueCard> {
  var _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final isAdmin = currentUser?.role == 'admin' || currentUser?.role == 'superadmin';
    final isDeposited = widget.issue.deposit == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(4),
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
                      color: _getTypeColor(widget.issue.type),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.issue.type.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.issue.key,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (isDeposited)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Tooltip(
                        message: 'Deposited Issue',
                        child: Icon(
                          Icons.lock_outline, 
                          size: 16, 
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  if (isAdmin)
                    _isDeleting
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: Colors.red,
                          tooltip: isDeposited 
                            ? 'Cannot delete deposited issues' 
                            : 'Delete Issue',
                          onPressed: isDeposited 
                            ? null 
                            : () => _confirmDeleteIssue(context),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.only(right: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.issue.status),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.issue.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.issue.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (widget.issue.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.issue.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.flag,
                    size: 16,
                    color: _getPriorityColor(widget.issue.priority),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.issue.priority,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.issue.assignee?.name ?? 'Unassigned',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.issue.createdAt.day}/${widget.issue.createdAt.month}/${widget.issue.createdAt.year}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _confirmDeleteIssue(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Issue'),
        content: Text(
          'Are you sure you want to delete issue ${widget.issue.key} - ${widget.issue.title}?',
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

    setState(() => _isDeleting = true);
    try {
      await Provider.of<IssueProvider>(context, listen: false)
          .deleteIssue(widget.issue.id);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${widget.issue.key}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: ${error.toString()}')),
      );
      setState(() => _isDeleting = false);
    }
  }
  
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'bug': return Colors.red[400]!;
      case 'feature': return Colors.green[400]!;
      case 'story': return Colors.teal[400]!;
      case 'task': return Colors.blue[400]!;
      case 'epic': return Colors.purple[400]!;
      default: return Colors.grey[400]!;
    }
  }
  
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.red[400]!;
      case 'medium': return Colors.orange[400]!;
      case 'low': return Colors.green[400]!;
      default: return Colors.blue[400]!;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'to do': return Colors.grey[400]!;
      case 'seen': return Colors.blueGrey[400]!;
      case 'in progress': return Colors.blue[400]!;
      case 'in review': return Colors.orange[400]!;
      case 'done': return Colors.green[400]!;
      default: return Colors.purple[400]!;
    }
  }
}  