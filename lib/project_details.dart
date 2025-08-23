import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'logging.dart';
import 'audit_log_page.dart';

class ProjectDetailsPage extends StatefulWidget {
  final String projectId;
  const ProjectDetailsPage({super.key, required this.projectId});

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  List<Map<String, dynamic>> _existingAttachments = [];
  bool _loadingAttachments = false;
  Map<String, dynamic>? _projectData;
  bool _loadingProject = true;

  @override
  void initState() {
    super.initState();
    _loadProjectData();
    _loadExistingAttachments();
  }

  Future<void> _loadProjectData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .get();
      
      if (doc.exists) {
        setState(() {
          _projectData = doc.data();
          _loadingProject = false;
        });
      } else {
        setState(() {
          _loadingProject = false;
        });
      }
    } catch (e) {
      setState(() {
        _loadingProject = false;
      });
      print('Error loading project data: $e');
    }
  }

  Future<void> _loadExistingAttachments() async {
    setState(() => _loadingAttachments = true);
    try {
      // Load attachments from logs
      final logsSnapshot = await FirebaseFirestore.instance
          .collection('logs')
          .where('project_id', isEqualTo: widget.projectId)
          .where('action', isEqualTo: 'upload_attachments')
          .orderBy('timestamp', descending: true)
          .get();

      final attachments = <Map<String, dynamic>>[];
      for (var doc in logsSnapshot.docs) {
        final data = doc.data();
        if (data['attachments'] != null && data['attachments']['files'] != null) {
          final files = data['attachments']['files'] as List;
          for (var file in files) {
            attachments.add(Map<String, dynamic>.from(file));
          }
        }
      }
      
      setState(() {
        _existingAttachments = attachments;
        _loadingAttachments = false;
      });
    } catch (e) {
      setState(() => _loadingAttachments = false);
      print('Error loading attachments: $e');
    }
  }

  Future<void> _uploadAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
        allowMultiple: true,
      );

    if (result == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

      final List<Map<String, dynamic>> uploadedFiles = [];

      for (var file in result.files) {
        if (file.path != null) {
          try {
            final fileObj = File(file.path!);
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final ref = FirebaseStorage.instance.ref('attachments/${widget.projectId}/$fileName');
            
            await ref.putFile(fileObj);
    final url = await ref.getDownloadURL();

            uploadedFiles.add({
              'filename': file.name,
              'size': file.size,
        'url': url,
              'type': file.extension,
            });
          } catch (e) {
            print('Error uploading file ${file.name}: $e');
          }
        }
      }

      if (uploadedFiles.isNotEmpty) {
        await const AuditLogger().writeLog(
          projectId: widget.projectId,
          action: 'upload_attachments',
          summary: '${uploadedFiles.length} attachment(s) uploaded',
          attachments: {'files': uploadedFiles},
        );

        // Reload attachments
        await _loadExistingAttachments();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${uploadedFiles.length} file(s) uploaded successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Future<void> _downloadAttachment(Map<String, dynamic> attachment) async {
    // For now, just show the URL. In a real app, you'd implement actual download
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download ${attachment['filename']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: ${attachment['filename']}'),
            Text('Size: ${_formatFileSize(attachment['size'])}'),
            Text('Type: ${attachment['type']?.toUpperCase()}'),
            const SizedBox(height: 16),
            const Text('URL:', style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(attachment['url']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int size) {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _loadingProject
          ? const Center(child: CircularProgressIndicator())
          : _projectData == null
              ? const Center(child: Text('Project not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project Information Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.business, color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Project Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Company Name
                              _buildProjectDetail('Company Name', _projectData!['company_name'] ?? 'Not specified'),
                              const SizedBox(height: 16),
                              
                              // Requirements
                              _buildProjectDetail('Requirements', _projectData!['requirements'] ?? 'Not specified'),
                              const SizedBox(height: 16),
                              
                              // Specifications
                              _buildProjectDetail('Specifications', _projectData!['specifications'] ?? 'Not specified'),
                              const SizedBox(height: 16),
                              
                              // Metadata
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildProjectDetail('Created By', _projectData!['created_by'] ?? 'Unknown'),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildProjectDetail('Created At', _formatTimestamp(_projectData!['created_at'])),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildProjectDetail('Last Updated By', _projectData!['updated_by'] ?? 'Unknown'),
                                  ),
                                  const SizedBox(width: 16),
        Expanded(
                                    child: _buildProjectDetail('Last Updated', _formatTimestamp(_projectData!['updated_at'])),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  OutlinedButton.icon(
                                    onPressed: _uploadAttachment,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Upload Files'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              if (_loadingAttachments)
                                const Center(child: CircularProgressIndicator())
                              else if (_existingAttachments.isEmpty)
                                const Center(
                                  child: Text(
                                    'No attachments yet',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              else
                                Column(
                                  children: _existingAttachments.map((attachment) {
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: Icon(
                                          _getFileIcon(attachment['type']),
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        title: Text(attachment['filename']),
                                        subtitle: Text(
                                          '${_formatFileSize(attachment['size'])} • ${attachment['type']?.toUpperCase()}',
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.download),
                                          onPressed: () => _downloadAttachment(attachment),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Activity Logs Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.history),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Activity Log',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AuditLogPage(projectId: widget.projectId),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('View All'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 300, // Fixed height for logs
                                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                  stream: FirebaseFirestore.instance
                                      .collection('logs')
                                      .where('project_id', isEqualTo: widget.projectId)
                                      .orderBy('timestamp', descending: true)
                                      .limit(5) // Show only recent logs
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    
                                    final docs = snapshot.data!.docs;
                                    if (docs.isEmpty) {
                                      return const Center(
                                        child: Text('No activity logs yet'),
                                      );
                                    }
                                    
                                    return ListView.builder(
                                      itemCount: docs.length,
                                      itemBuilder: (context, i) {
                                        final log = docs[i].data();
                                        final summary = log['summary'] ?? log['action'];
                                        final attachments = log['attachments'] as Map<String, dynamic>?;
                                        final changes = log['changes'] as Map<String, dynamic>?;
                                        
                                        return ExpansionTile(
                                          title: Text(summary),
                                          subtitle: Text(
                                            "${log['user_email']} — ${_formatTimestamp(log['timestamp'])}${log['sequence'] != null ? ' (#${log['sequence']})' : ''}",
                                          ),
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Project ID
                                                  if (log['project_id'] != null) ...[
                                                    _buildLogDetail('Project ID', log['project_id']),
                                                    const SizedBox(height: 8),
                                                  ],
                                                  
                                                  // Remarks
                                                  if (log['remarks'] != null && log['remarks'].toString().isNotEmpty) ...[
                                                    _buildLogDetail('Remarks', log['remarks']),
                                                    const SizedBox(height: 8),
                                                  ],
                                                  
                                                  // Changes
                                                  if (changes != null && changes.isNotEmpty) ...[
                                                    _buildLogDetail('Changes', _formatChanges(changes)),
                                                    const SizedBox(height: 8),
                                                  ],
                                                  
                                                  // Attachments
                                                  if (attachments != null && attachments['files'] != null) ...[
                                                    _buildLogDetail('Files', _formatAttachments(attachments['files'])),
                                                    const SizedBox(height: 8),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProjectDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value,
            style: TextStyle(color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }

  Widget _buildLogDetail(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final date = DateTime.parse(timestamp.toString());
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatChanges(Map<String, dynamic> changes) {
    final List<String> formatted = [];
    changes.forEach((key, value) {
      if (value is Map && value.containsKey('old') && value.containsKey('new')) {
        formatted.add('$key: "${value['old']}" → "${value['new']}"');
      } else {
        formatted.add('$key: $value');
      }
    });
    return formatted.join('\n');
  }

  String _formatAttachments(List files) {
    final List<String> formatted = [];
    for (var file in files) {
      if (file is Map) {
        final filename = file['filename'] ?? 'Unknown';
        final size = file['size'] ?? 0;
        final type = file['type'] ?? 'Unknown';
        formatted.add('• $filename ($size bytes, $type)');
      }
    }
    return formatted.join('\n');
  }
}