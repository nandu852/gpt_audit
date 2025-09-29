import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'logging.dart';
import 'specifications_flow.dart';
import 'home_dashboard.dart';

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
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Choose Project Type',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Select the type of project you want to create',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SpecificationsFlow()),
                    );
                  },
                  icon: const Icon(Icons.construction),
                  label: const Text('Start New Project'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigate back to home dashboard
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeDashboard()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Home'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
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