

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/project_provider.dart';
// import '../providers/auth_provider.dart';
// import '../models/project.dart';
// import '../models/user.dart';

// class ProjectMembers extends StatelessWidget {
//   final Project project;

//   const ProjectMembers(this.project, {super.key});

//   @override
//   Widget build(BuildContext context) {
//     final projectProvider = Provider.of<ProjectProvider>(context);
//     final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
//     final isAdmin = currentUser?.role == 'admin' || currentUser?.role == 'superadmin';


//     return project.members.isEmpty
//         ? Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.people, size: 80, color: Colors.grey),
//                 const SizedBox(height: 16),
//                 Text('No members found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
//                 const SizedBox(height: 8),
//                 Text('Add members to your project', style: TextStyle(color: Colors.grey[600])),
//               ],
//             ),
//           )
//         : ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: project.members.length,
//             itemBuilder: (ctx, i) => Card(
//               margin: const EdgeInsets.only(bottom: 8),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   children: [
//                     CircleAvatar(child: Text(project.members[i].user.name[0])),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(project.members[i].user.name,
//                               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                           Text(project.members[i].user.email,
//                               style: TextStyle(color: Colors.grey[600])),
//                         ],
//                       ),
//                     ),
//                     Chip(
//                       label: Text(project.members[i].role),
//                       backgroundColor: _getRoleColor(project.members[i].role),
//                       labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
//                     ),
//                     if (isAdmin && project.members[i].user.id != project.lead.id)
//                       IconButton(
//                         icon: const Icon(Icons.delete, color: Colors.red),
//                         onPressed: () async {
//                           final confirm = await showDialog<bool>(
//                             context: context,
//                             builder: (ctx) => AlertDialog(
//                               title: const Text('Remove Member'),
//                               content: const Text('Are you sure you want to remove this member?'),
//                               actions: [
//                                 TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
//                                 TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
//                               ],
//                             ),
//                           );
//                           if (confirm == true) {
//                             try {
//                               await projectProvider.removeProjectMember(project.id, project.members[i].user.id);
//                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member removed successfully')));
//                             } catch (error) {
//                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to remove member')));
//                             }
//                           }
//                         },
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//   }

//   Color _getRoleColor(String role) {
//     switch (role) {
//       case 'Developer':
//         return Colors.blue;
//       case 'QA':
//         return Colors.green;
//       case 'Designer':
//         return Colors.purple;
//       case 'Observer':
//         return Colors.orange;
//       default:
//         return Colors.grey;
//     }
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../providers/auth_provider.dart';
import '../models/project.dart';
import '../models/user.dart';

class ProjectMembers extends StatelessWidget {
  final Project project;

  const ProjectMembers(this.project, {super.key});

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final isAdmin = currentUser?.isAdmin == true || 
                    currentUser?.isSuperAdmin == true || 
                    project.lead.id == currentUser?.id;

    return project.members.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No members found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text('Add members to your project', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: project.members.length,
            itemBuilder: (ctx, i) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(child: Text(project.members[i].user.name.isNotEmpty ? project.members[i].user.name[0] : '?')),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(project.members[i].user.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(project.members[i].user.email,
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(project.members[i].role),
                      backgroundColor: _getRoleColor(project.members[i].role),
                      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    if (isAdmin && project.members[i].user.id != project.lead.id)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showRemoveMemberDialog(
                          context, 
                          projectProvider,
                          project.id, 
                          project.members[i].user.id,
                          project.members[i].user.name,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'developer':
        return Colors.blue;
      case 'qa':
        return Colors.green;
      case 'designer':
        return Colors.purple;
      case 'observer':
        return Colors.orange;
      case 'admin':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
  
  void _showRemoveMemberDialog(
    BuildContext context, 
    ProjectProvider provider,
    int projectId, 
    int userId,
    String userName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove $userName from this project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(true);
              try {
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Removing member...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                await provider.removeProjectMember(projectId, userId);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member removed successfully')),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to remove member: ${error.toString()}')),
                  );
                }
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
