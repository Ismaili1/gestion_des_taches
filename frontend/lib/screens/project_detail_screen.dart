import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../providers/issue_provider.dart';
import '../providers/auth_provider.dart';
import '../models/project.dart';
import '../screens/project_form_screen.dart';
import '../screens/issue_form_screen.dart';
import '../widgets/issue_list.dart';
import '../widgets/project_members.dart';
import '../models/user.dart';
import 'dart:async';


class ProjectDetailScreen extends StatefulWidget {
  final int projectId;

  const ProjectDetailScreen(this.projectId, {Key? key}) : super(key: key);

  @override
  _ProjectDetailScreenState createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadData();
  }

  void _handleTabChange() {
    
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _loadData() async {
  setState(() => _isLoading = true);
  
  try {
    debugPrint('Loading project ${widget.projectId} details...');
    
    
    await Provider.of<ProjectProvider>(context, listen: false)
        .fetchProjectDetails(widget.projectId);

    
    final issueProvider = Provider.of<IssueProvider>(context, listen: false);
    await issueProvider.fetchProjectIssues(widget.projectId);

    debugPrint('Project ${widget.projectId} data loaded successfully');
    
  } catch (error, stackTrace) {
    debugPrint('Error loading project data: $error');
    debugPrint(stackTrace.toString());
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Failed to load project data'),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: _loadData,
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final isAdmin = currentUser?.role == 'admin' || currentUser?.role == 'superadmin';


    final exists = provider.projects.any((p) => p.id == widget.projectId);
    if (!exists) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const SizedBox();
    }

    final project = provider.findById(widget.projectId);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProjectFormScreen(projectId: project.id),
                  ),
                );
              },
            ),
          if (isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: const Text('Are you sure you want to delete this project?'),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(ctx).pop(false),
                        ),
                        TextButton(
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          onPressed: () => Navigator.of(ctx).pop(true),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    Navigator.of(context).pop();
                    try {
                      await Provider.of<ProjectProvider>(context, listen: false)
                          .deleteProject(project.id);
                    } catch (error) {
                      debugPrint('Delete project error: $error');
                    }
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Project'),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Issues'),
            Tab(text: 'Members'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          IssueList(project.id),
          ProjectMembers(project),
        ],
      ),
      
      floatingActionButton: _showFloatingActionButton(project, isAdmin),
    );
  }

  
  Widget? _showFloatingActionButton(Project project, bool isAdmin) {
    
    if (_tabController.index == 0) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => IssueFormScreen(projectId: project.id),
            ),
          );
        },
        child: const Icon(Icons.add),
      );
    }
    
    else if (_tabController.index == 1 && isAdmin) {
      return FloatingActionButton(
        onPressed: () {
          _showAddMemberDialog(context, project);
        },
        child: const Icon(Icons.add),
      );
    }
    
    return null;
  }
 
void _showAddMemberDialog(BuildContext context, Project project) {
  final searchController = TextEditingController();
  final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
  List<User> searchResults = [];
  String selectedRole = 'Developer';
  Timer? _debounce;
  bool isLoading = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Project Member',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search User',
                      border: OutlineInputBorder(),
                      suffixIcon: isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () async {
                        if (value.isEmpty) {
                          setState(() => searchResults = []);
                          return;
                        }
                        try {
                          setState(() => isLoading = true);
                          final results = await projectProvider.searchUsers(value);
                          setState(() {
                            searchResults = results.where((user) => 
                              !project.members.any((m) => m.user.id == user.id)
                            ).toList();
                            isLoading = false;
                          });
                        } catch (error) {
                          setState(() => isLoading = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Search error: ${error.toString()}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedRole,
                    items: ['Developer', 'QA', 'Designer', 'Observer']
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedRole = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : searchResults.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No users found',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: searchResults.length,
                                  itemBuilder: (ctx, i) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    elevation: 1,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        child: Text(searchResults[i].name[0]),
                                      ),
                                      title: Text(searchResults[i].name),
                                      subtitle: Text(searchResults[i].email),
                                      onTap: () async {
                                        try {
                                          await projectProvider.addProjectMember(
                                            project.id,
                                            searchResults[i].id,
                                            selectedRole,
                                          );
                                          if (mounted) {
                                            Navigator.of(ctx).pop();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text('Member added successfully'),
                                              ),
                                            );
                                          }
                                        } catch (error) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Error: ${error.toString()}'),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _debounce?.cancel();
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  ).then((_) => _debounce?.cancel());
}

}