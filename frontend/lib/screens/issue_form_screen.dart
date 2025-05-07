import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/issue_provider.dart';
import '../providers/project_provider.dart';
import '../providers/auth_provider.dart';
import '../models/issue.dart';
import '../models/project.dart';
import '../models/user.dart';

class IssueFormScreen extends StatefulWidget {
  final int projectId;
  final int? issueId;

  const IssueFormScreen({
    super.key,
    required this.projectId,
    this.issueId,
  });

  @override
  _IssueFormScreenState createState() => _IssueFormScreenState();
}

class _IssueFormScreenState extends State<IssueFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'task';
  String _selectedPriority = 'medium';
  String _selectedStatus = 'to_do';
  DateTime? _dueDate;
  int? _selectedAssigneeId;
  bool _isLoading = false;
  bool _isCurrentUserAdmin = false;

  late Project _project;
  Issue? _existingIssue;
  User? _selectedAssignee;
  User? _currentUser;

  // Ensure all values are unique and in lowercase
  final List<String> _issueTypes = ['task', 'bug', 'story', 'epic'];
  final List<String> _priorities = ['high', 'medium', 'low'];
  final List<String> _statuses = ['to_do', 'in_progress', 'in_review', 'done'];

  // Map for displaying formatted status names
  final Map<String, String> _displayNames = {
    'to_do': 'To Do',
    'in_progress': 'In Progress',
    'in_review': 'In Review',
    'done': 'Done',
  };

  // Map for converting display names back to internal values
  final Map<String, String> _statusToInternalValue = {
    'To Do': 'to_do',
    'In Progress': 'in_progress',
    'In Review': 'in_review',
    'Done': 'done',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _currentUser = authProvider.currentUser;
      _isCurrentUserAdmin = _currentUser?.role == 'admin' || _currentUser?.role == 'super_admin';
      
      if (!_isCurrentUserAdmin && _currentUser != null && widget.issueId == null) {
        _selectedAssigneeId = _currentUser!.id;
        _selectedAssignee = _currentUser;
      }

      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      _project = await projectProvider.fetchProjectDetails(widget.projectId);
      
      if (widget.issueId != null) {
        final issueProvider = Provider.of<IssueProvider>(context, listen: false);
        await issueProvider.fetchProjectIssues(widget.projectId);
        _existingIssue = issueProvider.findById(widget.issueId!);
        
        _titleController.text = _existingIssue!.title;
        _descriptionController.text = _existingIssue!.description ?? '';
        _selectedType = _existingIssue!.type.toLowerCase();
        _selectedPriority = _existingIssue!.priority.toLowerCase();
        
        // Convert the status display name to internal value
        final statusFromIssue = _existingIssue!.status;
        _selectedStatus = _statusToInternalValue[statusFromIssue] ?? 'to_do';
        
        _dueDate = _existingIssue!.dueDate;
        
        if (_existingIssue!.assignee != null) {
          _selectedAssigneeId = _existingIssue!.assignee!.id;
          _selectedAssignee = _existingIssue!.assignee;
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveIssue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final issueProvider = Provider.of<IssueProvider>(context, listen: false);

      if (widget.issueId == null) {
        await issueProvider.createIssue(
          projectId: widget.projectId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          priority: _selectedPriority,
          status: _selectedStatus,
          assigneeId: _selectedAssigneeId,
          dueDate: _dueDate,
        );
      } else {
        await issueProvider.updateIssue(
          id: widget.issueId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          priority: _selectedPriority,
          status: _selectedStatus,
          assigneeId: _selectedAssigneeId,
          dueDate: _dueDate,
        );
      }

      Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save issue: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteIssue() async {
    if (widget.issueId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this issue?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            child: const Text('Delete'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final issueProvider = Provider.of<IssueProvider>(context, listen: false);
      await issueProvider.deleteIssue(widget.issueId!);
      Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete issue: $error')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  String _getAvatarText(String name) {
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }
  
  Future<void> _selectAssignee(BuildContext context) async {
    if (!_isCurrentUserAdmin) return;
    
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Assignee',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person_off, color: Colors.white),
                ),
                title: const Text('Unassigned'),
                subtitle: const Text('No one assigned'),
                selected: _selectedAssigneeId == null,
                onTap: () {
                  setState(() {
                    _selectedAssigneeId = null;
                    _selectedAssignee = null;
                  });
                  Navigator.of(ctx).pop();
                },
              ),
              ..._project.members.map((member) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      _getAvatarText(member.user.name),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(member.user.name),
                  subtitle: Text(member.user.email ?? 'No email provided'),
                  selected: _selectedAssigneeId == member.user.id,
                  onTap: () {
                    setState(() {
                      _selectedAssigneeId = member.user.id;
                      _selectedAssignee = member.user;
                    });
                    Navigator.of(ctx).pop();
                  },
                );
              }),
              if (_project.members.isEmpty)
                const ListTile(
                  title: Text('No project members available'),
                  enabled: false,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.issueId == null ? 'Create Issue' : 'Edit Issue'),
        actions: [
          if (widget.issueId != null && _isCurrentUserAdmin)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteIssue,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.trim().isEmpty ?? true ? 'Please enter an issue title' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      items: _issueTypes
                          .map((type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(
                                  type.substring(0, 1).toUpperCase() + type.substring(1),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedType = value!),
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedPriority,
                            items: _priorities
                                .map((priority) => DropdownMenuItem<String>(
                                      value: priority,
                                      child: Text(
                                        priority.substring(0, 1).toUpperCase() + priority.substring(1),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedPriority = value!),
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            items: _statuses
                                .map((status) => DropdownMenuItem<String>(
                                      value: status,
                                      child: Text(_displayNames[status] ?? status),
                                    ))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedStatus = value!),
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!_isCurrentUserAdmin && _currentUser != null)
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Assignee',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blue,
                              child: Text(
                                _getAvatarText(_currentUser!.name),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentUser!.name,
                                    style: const TextStyle(fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_currentUser?.email != null)
                                    Text(
                                      _currentUser!.email,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).hintColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_isCurrentUserAdmin)
                      InkWell(
                        onTap: () => _selectAssignee(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Assignee',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: _selectedAssignee != null 
                                    ? Colors.blue 
                                    : Colors.grey,
                                child: _selectedAssignee != null
                                    ? Text(
                                        _getAvatarText(_selectedAssignee!.name),
                                        style: const TextStyle(color: Colors.white),
                                      )
                                    : const Icon(Icons.person_off, size: 16, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _selectedAssignee?.name ?? 'Unassigned',
                                      style: const TextStyle(fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_selectedAssignee?.email != null)
                                      Text(
                                        _selectedAssignee!.email,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).hintColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _dueDate == null
                              ? 'No date selected'
                              : DateFormat('MMM d, yyyy').format(_dueDate!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveIssue,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.issueId == null ? 'Create Issue' : 'Save Changes',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}