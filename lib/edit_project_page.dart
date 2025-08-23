import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'logging.dart';

class EditProjectPage extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic> data;
  const EditProjectPage({super.key, required this.projectId, required this.data});

  @override
  State<EditProjectPage> createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  final _remarks = TextEditingController();
  bool _saving = false;
  List<Map<String, dynamic>> _newAttachments = [];

  @override
  void dispose() {
    _remarks.dispose();
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
              _newAttachments.add({
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
      _newAttachments.removeAt(index);
    });
  }

  Future<void> _uploadNewAttachments() async {
    if (_newAttachments.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final storage = FirebaseStorage.instance;
    final List<Map<String, dynamic>> uploadedFiles = [];

    for (var attachment in _newAttachments) {
      try {
        final file = File(attachment['path']);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${attachment['name']}';
        final ref = storage.ref('attachments/${widget.projectId}/$fileName');
        
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
        projectId: widget.projectId,
        action: 'upload_attachments',
        summary: '${uploadedFiles.length} new attachment(s) uploaded',
        attachments: {'files': uploadedFiles},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Project'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Project Information Header
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Project Information (Read-Only)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Company Name (Locked)
                      _buildLockedField(
                        label: 'Company Name',
                        value: widget.data['company_name'] ?? 'Not specified',
                        icon: Icons.business,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Requirements (Locked)
                      _buildLockedField(
                        label: 'Requirements',
                        value: widget.data['requirements'] ?? 'Not specified',
                        icon: Icons.description,
                        isMultiline: true,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Specifications (Locked)
                      _buildLockedField(
                        label: 'Specifications',
                        value: widget.data['specifications'] ?? 'Not specified',
                        icon: Icons.settings,
                        isMultiline: true,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Remarks Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.note, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Remarks (Required)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Explain why you are making changes to this project',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _remarks,
                        decoration: const InputDecoration(
                          labelText: 'Remarks',
                          border: OutlineInputBorder(),
                          hintText: 'Enter your remarks here...',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Remarks are required to explain the changes';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // New Attachments Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.attach_file, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Add New Attachments (Optional)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload additional PDF, images, or documents',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      
                      // New Attachment List
                      if (_newAttachments.isNotEmpty) ...[
                        const Text(
                          'Files to Upload:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...(_newAttachments.asMap().entries.map((entry) {
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
              
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
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
                        
                        // Upload new attachments if any
                        await _uploadNewAttachments();
                        
                        // Save log entry with sequence
                        await const AuditLogger().writeLog(
                          projectId: widget.projectId,
                          action: 'update',
                          summary: 'Project updated with remarks${_newAttachments.isNotEmpty ? ' and ${_newAttachments.length} new attachment(s)' : ''}',
                          remarks: _remarks.text.trim(),
                        );

                        if (!mounted) return;
                        
                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Project updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        // Navigate back to home screen as specified
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
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

  Widget _buildLockedField({
    required String label,
    required String value,
    required IconData icon,
    bool isMultiline = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontStyle: isMultiline ? FontStyle.normal : FontStyle.italic,
            ),
            maxLines: isMultiline ? null : 1,
            overflow: isMultiline ? null : TextOverflow.ellipsis,
          ),
        ),
      ],
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
}