import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_project_page.dart';
import 'project_details.dart';

class ProjectListPage extends StatefulWidget {
  const ProjectListPage({super.key});

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> with AutomaticKeepAliveClientMixin {
  bool _isLoading = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _projects = [];
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _projectsSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _projectsSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh projects when returning to this page
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Loading projects...');
      
      // First, check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      print('User authenticated: ${user.email}');

      // Cancel any existing subscription
      await _projectsSubscription?.cancel();

      // Use StreamBuilder approach but with better error handling
      // Filter projects by the current user
      _projectsSubscription = FirebaseFirestore.instance
          .collection('projects')
          .where('created_by', isEqualTo: user.email)
          .orderBy('updated_at', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          print('Projects stream updated. Found ${snapshot.docs.length} projects');
          
          if (mounted) {
            setState(() {
              _projects = snapshot.docs;
              _isLoading = false;
            });
          }

          // Debug: Print project details
          for (var i = 0; i < snapshot.docs.length; i++) {
            final doc = snapshot.docs[i];
            final data = doc.data() as Map<String, dynamic>?;
            print('Project $i: ID=${doc.id}, Company=${data?['company_name']}, Updated=${data?['updated_at']}');
          }
        },
        onError: (error) {
          print('Error in projects stream: $error');
          if (mounted) {
            setState(() {
              _errorMessage = error.toString();
              _isLoading = false;
            });
          }
        },
      );

    } catch (e) {
      print('Error setting up projects stream: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _manualRefresh() async {
    print('Manual refresh triggered');
    await _loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Existing Projects'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _manualRefresh,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _testFirestoreAccess,
            tooltip: 'Test Firestore',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _projects.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading projects...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && _projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error loading projects',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _manualRefresh,
              child: const Text('Retry'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testFirestoreAccess,
              child: const Text('Test Firestore Access'),
            ),
          ],
        ),
      );
    }

    if (_projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No projects found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'This could be due to:\n• No projects created yet\n• Firestore security rules\n• Authentication issues',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _manualRefresh,
              child: const Text('Refresh'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testFirestoreAccess,
              child: const Text('Test Firestore Access'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Debug info banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Found ${_projects.length} project(s)',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                  ),
                ),
            ],
          ),
        ),
        
        // Projects list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _manualRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _projects.length,
              itemBuilder: (context, index) {
                final doc = _projects[index];
                final data = doc.data() as Map<String, dynamic>?;
                if (data == null) return const SizedBox.shrink();
                
                // Format timestamp for display
                String formattedTime = 'Unknown';
                try {
                  if (data['updated_at'] != null) {
                    final timestamp = DateTime.parse(data['updated_at']);
                    formattedTime = '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
                  }
                } catch (e) {
                  formattedTime = 'Invalid date';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Project Header
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              color: Theme.of(context).primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                data['company_name'] ?? 'Unnamed Company',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Debug: Show project ID
                            Text(
                              'ID: ${doc.id.substring(0, 8)}...',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Project Details
                        if (data['requirements'] != null) ...[
                          Text(
                            'Requirements:',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['requirements'].length > 100
                                ? '${data['requirements'].substring(0, 100)}...'
                                : data['requirements'],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                        ],
                        
                        if (data['specifications'] != null) ...[
                          Text(
                            'Specifications:',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['specifications'].length > 100
                                ? '${data['specifications'].substring(0, 100)}...'
                                : data['specifications'],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                        ],
                        
                        // Metadata
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Last modified: $formattedTime',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              data['updated_by'] ?? 'Unknown user',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProjectDetailsPage(projectId: doc.id),
                                    ),
                                  );
                                  // Refresh after returning from project details
                                  _manualRefresh();
                                },
                                icon: const Icon(Icons.visibility),
                                label: const Text('View'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditProjectPage(projectId: doc.id, data: data),
                                    ),
                                  );
                                  // Refresh after returning from edit
                                  _manualRefresh();
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _testFirestoreAccess() async {
    try {
      // Test 1: Try to read from projects collection
      print('Testing Firestore read access...');
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .limit(1)
          .get();
      
      print('Read test result: ${projectsSnapshot.docs.length} documents found');
      
      // Test 2: Try to write a test document
      print('Testing Firestore write access...');
      final testDoc = await FirebaseFirestore.instance
          .collection('test_access')
          .add({
        'test': true,
        'timestamp': DateTime.now().toIso8601String(),
        'user': 'test_user',
      });
      
      print('Write test result: Document created with ID: ${testDoc.id}');
      
      // Test 3: Try to delete the test document
      await testDoc.delete();
      print('Delete test result: Test document deleted successfully');
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firestore access test successful! Check console for details.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      print('Firestore access test failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firestore access test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
