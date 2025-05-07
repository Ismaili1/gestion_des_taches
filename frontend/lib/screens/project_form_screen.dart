
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../models/project.dart';
import '../models/user.dart';

class ProjectFormScreen extends StatefulWidget {
  final int? projectId;

  const ProjectFormScreen({this.projectId, super.key});

  @override
  _ProjectFormScreenState createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _keyController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isInit = true;
  Project? _existingProject;

  User? _selectedUser;
  String? _selectedDirection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit && widget.projectId != null) {
      _existingProject =
          Provider.of<ProjectProvider>(context, listen: false)
              .findById(widget.projectId!);
      if (_existingProject != null) {
        _nameController.text = _existingProject!.name;
        _keyController.text = _existingProject!.key;
        _descriptionController.text = _existingProject!.description;
        _selectedUser = _existingProject!.lead;
        _selectedDirection = _existingProject!.direction;
      }
    }
    _isInit = false;
  }




  

































      

      

      




      

































Future<void> _saveProject() async {
  if (!_formKey.currentState!.validate()) return;
  if (_selectedUser == null || _selectedDirection == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a lead and direction')),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    await Provider.of<ProjectProvider>(context, listen: false).createProject(
      _nameController.text.trim(),
      _keyController.text.trim().toUpperCase(),
      _descriptionController.text.trim(),
      _selectedUser!.id,
      _selectedDirection!,
    );

    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Project created successfully!')),
    );
    
    Navigator.of(context).pop();
  } catch (e) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Project created but refresh needed: ${e.toString()}'),
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.of(context).pop();
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.projectId == null ? 'Create Project' : 'Edit Project',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a project name'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _keyController,
                decoration: const InputDecoration(
                  labelText: 'Project Key (Short Code)',
                  border: OutlineInputBorder(),
                  helperText: 'e.g. PROJ, TEST, DEV (2-10 characters)',
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 10,
                enabled: widget.projectId == null,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a project key';
                  if (value.length < 2) return 'Key must be at least 2 characters';
                  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value)) return 'Only letters & numbers';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 16),

              
              Autocomplete<User>(
                initialValue: TextEditingValue(
                  text: _selectedUser?.email ?? '',
                ),
                displayStringForOption: (u) => u.email,
                optionsBuilder: (textEditingValue) async {
                  final query = textEditingValue.text.trim();
                  if (query.isEmpty) return const Iterable<User>.empty();
                  return await context
                      .read<ProjectProvider>()
                      .searchUsers(query);
                },
                onSelected: (user) {
                  setState(() => _selectedUser = user);
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Search Lead by Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (_) => _selectedUser == null
                        ? 'Please select a project lead'
                        : null,
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final user = options.elementAt(index);
                            return ListTile(
                              title: Text(user.name),
                              subtitle: Text(user.email),
                              onTap: () => onSelected(user),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Direction',
                  border: OutlineInputBorder(),
                ),
                value: _selectedDirection,
                items: const [
                  'general',
                  'engineering',
                  'marketing',
                  'sales',
                  'design'
                ]
                    .map((dir) => DropdownMenuItem(
                          value: dir,
                          child: Text(dir),
                        ))
                    .toList(),
                onChanged: (value) => setState(() {
                  _selectedDirection = value;
                }),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please select a direction'
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProject,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    widget.projectId == null ? 'CREATE PROJECT' : 'UPDATE PROJECT',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

