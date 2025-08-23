import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'logging.dart';

class AddProjectPage extends StatefulWidget {
  const AddProjectPage({super.key});

  @override
  State<AddProjectPage> createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final _company = TextEditingController();
  final _req = TextEditingController();
  final _spec = TextEditingController();
  bool _saving = false;
  List<Map<String, dynamic>> _attachments = [];

  @override
  void dispose() {
    _company.dispose();
    _req.dispose();
    _spec.dispose();
    super.dispose();
  }

  Future<void> _addAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
        allowMultiple: true,
      );

      if (result != null) {
        for (var file in result.files) {
          if (file.path != null) {
            setState(() {
              _attachments.add({
                'name': file.name,
                'size': file.size,
                'path': file.path,
                'type': file.extension,
              });
            });
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking files: $e')),
      );
    }
  }

  Future<void> _removeAttachment(int index) async {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _uploadAttachments(String projectId) async {
    if (_attachments.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final storage = FirebaseStorage.instance;
    final List<Map<String, dynamic>> uploadedFiles = [];

    for (var attachment in _attachments) {
      try {
        final file = File(attachment['path']);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${attachment['name']}';
        final ref = storage.ref('attachments/$projectId/$fileName');
        
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        
        uploadedFiles.add({
          'filename': attachment['name'],
          'size': attachment['size'],
          'url': url,
          'type': attachment['type'],
        });
      } catch (e) {
        print('Error uploading file ${attachment['name']}: $e');
      }
    }

    if (uploadedFiles.isNotEmpty) {
      await const AuditLogger().writeLog(
        projectId: projectId,
        action: 'upload_attachments',
        summary: '${uploadedFiles.length} attachment(s) uploaded',
        attachments: {'files': uploadedFiles},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Project'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _testFirestoreWrite,
            tooltip: 'Test Firestore Write',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _company,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Company name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _req,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Requirement(s)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Requirements are required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _spec,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Specification(s)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.settings),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Specifications are required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Attachments Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.attach_file),
                          const SizedBox(width: 8),
                          const Text(
                            'Attachments',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload PDF, images, or documents (optional)',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      
                      // Attachment List
                      if (_attachments.isNotEmpty) ...[
                        const Text(
                          'Selected Files:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...(_attachments.asMap().entries.map((entry) {
                          final index = entry.key;
                          final attachment = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                _getFileIcon(attachment['type']),
                                color: Theme.of(context).primaryColor,
                              ),
                              title: Text(attachment['name']),
                              subtitle: Text('${_formatFileSize(attachment['size'])} • ${attachment['type']?.toUpperCase()}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () => _removeAttachment(index),
                              ),
                            ),
                          );
                        })),
                        const SizedBox(height: 16),
                      ],
                      
                      OutlinedButton.icon(
                        onPressed: _addAttachment,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Files'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : () async {
                      if (!Form.of(context).validate()) return;
                      
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;
                      
                      setState(() => _saving = true);
                      try {
                        final now = DateTime.now().toIso8601String();
                        
                        // Debug: Print project data before saving
                        final projectData = {
                          'company_name': _company.text.trim(),
                          'requirements': _req.text.trim(),
                          'specifications': _spec.text.trim(),
                          'created_by': user.email,
                          'created_at': now,
                          'updated_by': user.email,
                          'updated_at': now,
                          'log_sequence': 0,
                        };
                        
                        print('Saving project with data: $projectData');
                        
                        final doc = await FirebaseFirestore.instance.collection('projects').add(projectData);
                        
                        print('Project saved successfully with ID: ${doc.id}');

                        // Upload attachments if any
                        if (_attachments.isNotEmpty) {
                          print('Uploading ${_attachments.length} attachment(s)');
                          await _uploadAttachments(doc.id);
                        }

                        // Log project creation
                        await const AuditLogger().writeLog(
                          projectId: doc.id,
                          action: 'create',
                          summary: 'Project created with ${_attachments.length} attachment(s)',
                        );

                        print('Audit log created for project: ${doc.id}');

                        if (!mounted) return;
                        
                        // Show success message and navigate to home
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Submitted'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        
                        // Navigate back to home screen (ProjectsPage)
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      } catch (e) {
                        print('Error creating project: $e');
                        if (!mounted) return;
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error creating project: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int size) {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Future<void> _testFirestoreWrite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in. Please log in to test Firestore write.')),
      );
      return;
    }

    final now = DateTime.now().toIso8601String();
    final testData = {
      'test_field': 'This is a test document',
      'created_by': user.email,
      'created_at': now,
      'updated_by': user.email,
      'updated_at': now,
    };

    try {
      final docRef = FirebaseFirestore.instance.collection('test_collection').doc('test_document');
      await docRef.set(testData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firestore write test successful! Document created/updated.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firestore write test failed: $e')),
      );
    }
  }
}