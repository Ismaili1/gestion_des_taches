
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../models/project.dart';
// import '../providers/issue_provider.dart';
// import '../providers/project_provider.dart';
// import '../providers/auth_provider.dart';
// import '../screens/project_detail_screen.dart';
// import '../utils/http_exception.dart';

// class ProjectItem extends StatelessWidget {
//   final Project project;

//   const ProjectItem(this.project, {super.key});

//   Future<void> _deleteProject(BuildContext context) async {
//     final scaffold = ScaffoldMessenger.of(context);
//     final projectProvider = Provider.of<ProjectProvider>(context, listen: false);

//     try {
//       final shouldDelete = await showDialog<bool>(
//         context: context,
//         builder: (ctx) => AlertDialog(
//           title: const Text('Delete Project'),
//           content: const Text('Are you sure you want to delete this project? This action cannot be undone.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(ctx).pop(false),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.of(ctx).pop(true),
//               child: const Text(
//                 'Delete',
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//           ],
//         ),
//       );

//       if (shouldDelete != true) return;

//       await projectProvider.deleteProject(project.id);

//       scaffold.showSnackBar(
//         const SnackBar(
//           content: Text('Project deleted successfully'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//     } on HttpException catch (e) {
//       scaffold.showSnackBar(
//         SnackBar(
//           content: Text(e.message),
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     } catch (e) {
//       scaffold.showSnackBar(
//         const SnackBar(
//           content: Text('An unexpected error occurred'),
//           duration: Duration(seconds: 3),
//         ),
//       );
//       debugPrint('Unexpected error: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = Provider.of<AuthProvider>(context).currentUser;
//     final isAdmin = currentUser?.role == 'admin' || currentUser?.role == 'superadmin';

//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.only(bottom: 16),
//       child: InkWell(
//         onTap: () {
//           Navigator.of(context).push(
//             MaterialPageRoute(
//               builder: (ctx) => ProjectDetailScreen(project.id),
//             ),
//           );
//         },
//         child: Stack(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: Theme.of(context).primaryColor,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Center(
//                           child: Text(
//                             project.key.isNotEmpty ? project.key[0] : "",
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 20,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               project.name,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 18,
//                               ),
//                             ),
//                             Text(
//                               'Key: ${project.key}',
//                               style: TextStyle(
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     project.description,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       FutureBuilder(
//                         future: Provider.of<IssueProvider>(context, listen: false)
//                             .getIssueStats(project.id),
//                         builder: (ctx, snapshot) {
//                           if (snapshot.connectionState == ConnectionState.waiting) {
//                             return const SizedBox(
//                               height: 20,
//                               width: 20,
//                               child: CircularProgressIndicator(strokeWidth: 2),
//                             );
//                           }

//                           if (!snapshot.hasData) {
//                             return const Text('No data');
//                           }

//                           final stats = snapshot.data as Map<String, int>;

//                           return Row(
//                             children: [
//                               _buildStatItem(stats['total'] ?? 0, 'Issues', Colors.blue),
//                               const SizedBox(width: 16),
//                               _buildStatItem(stats['open'] ?? 0, 'Open', Colors.orange),
//                               const SizedBox(width: 16),
//                               _buildStatItem(stats['done'] ?? 0, 'Done', Colors.green),
//                             ],
//                           );
//                         },
//                       ),
//                       const Spacer(),
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.people,
//                             size: 16,
//                             color: Colors.grey[600],
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${project.members.length} ${project.members.length == 1 ? 'member' : 'members'}',
//                             style: TextStyle(
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             if (isAdmin) // Only show delete button for admins
//               Positioned(
//                 top: 8,
//                 right: 8,
//                 child: IconButton(
//                   icon: const Icon(Icons.delete, color: Colors.red),
//                   onPressed: () => _deleteProject(context),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatItem(int count, String label, Color color) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           count.toString(),
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: color,
//             fontSize: 16,
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey[600],
//           ),
//         ),
//       ],
//     );
//   }
// }
// lib/widgets/project_item.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/issue_provider.dart';
import '../providers/project_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/project_detail_screen.dart';
import '../utils/http_exception.dart';

class ProjectItem extends StatelessWidget {
  final Project project;

  const ProjectItem(this.project, {super.key});

  Future<void> _deleteProject(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);

    try {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Project'),
          content: const Text('Are you sure you want to delete this project? This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
      );

      if (shouldDelete != true) return;

      await projectProvider.deleteProject(project.id);

      scaffold.showSnackBar(const SnackBar(content: Text('Project deleted successfully')));
    } on HttpException catch (e) {
      scaffold.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      scaffold.showSnackBar(const SnackBar(content: Text('An unexpected error occurred')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;
    final isAdmin = currentUser?.role == 'admin' || currentUser?.role == 'superadmin';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => ProjectDetailScreen(project.id)),
          );
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(project.key.isNotEmpty ? project.key[0] : "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('Key: ${project.key}', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Text(project.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 16),
                  Row(children: [
                    FutureBuilder(
                      future: Provider.of<IssueProvider>(context, listen: false).getIssueStats(project.id),
                      builder: (ctx, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }
                        if (!snapshot.hasData) return const Text('No data');
                        final stats = snapshot.data as Map<String, int>;
                        return Row(children: [
                          _buildStatItem(stats['total'] ?? 0, 'Issues', Colors.blue),
                          const SizedBox(width: 16),
                          _buildStatItem(stats['open'] ?? 0, 'Open', Colors.orange),
                          const SizedBox(width: 16),
                          _buildStatItem(stats['done'] ?? 0, 'Done', Colors.green),
                        ]);
                      },
                    ),
                    const Spacer(),
                    Row(children: [
                      const Icon(Icons.people, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${project.members.length} ${project.members.length == 1 ? 'member' : 'members'}', style: TextStyle(color: Colors.grey[600])),
                    ]),
                  ]),
                ],
              ),
            ),
            if (isAdmin)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteProject(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(int count, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(count.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
