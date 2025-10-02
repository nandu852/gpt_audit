import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project.dart';
import '../services/project_service.dart';

class AuditLogPage extends StatefulWidget {
  final String? projectId; // Optional project ID to filter logs
  const AuditLogPage({super.key, this.projectId});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  String _actionFilter = 'any';
  String _userFilter = '';
  String _projectFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;
  final _searchController = TextEditingController();
  bool _showFilters = false;
  List<String> _projectNames = [];
  Map<String, String> _projectIdToName = {}; // Map project ID to company name
  List<Specification> _specifications = [];
  bool _isLoadingSpecifications = false;
  bool _showSpecifications = false;

  @override
  void initState() {
    super.initState();
    _loadProjectNames();
    
    // If a specific project ID is provided, set it as the filter and load specifications
    if (widget.projectId != null) {
      _projectFilter = widget.projectId!;
      _showSpecifications = true; // Auto-show specifications
      _loadSpecifications();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectNames() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userEmail = user?.email;
      
      QuerySnapshot projectsSnapshot;
      if (userEmail != null) {
        // Filter projects by current user
        projectsSnapshot = await FirebaseFirestore.instance
            .collection('projects')
            .where('created_by', isEqualTo: userEmail)
            .orderBy('company_name')
            .get();
      } else {
        // Fallback if user is not authenticated
        projectsSnapshot = await FirebaseFirestore.instance
            .collection('projects')
            .orderBy('company_name')
            .get();
      }
      
      final names = <String>[];
      final idToName = <String, String>{};
      
      for (var doc in projectsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final companyName = data?['company_name'] ?? 'Unnamed Project';
        names.add(companyName);
        idToName[doc.id] = companyName;
      }
      
      setState(() {
        _projectNames = names;
        _projectIdToName = idToName;
      });
    } catch (e) {
      print('Error loading project names: $e');
    }
  }

  Future<void> _loadSpecifications() async {
    if (widget.projectId == null) return;
    
    setState(() {
      _isLoadingSpecifications = true;
    });
    
    try {
      final projectId = int.tryParse(widget.projectId!);
      if (projectId != null) {
        print('🔍 Loading specifications for project ID: $projectId');
        final specifications = await ProjectService.instance.getProjectSpecifications(projectId);
        print('📋 Loaded ${specifications.length} specifications');
        setState(() {
          _specifications = specifications;
          _isLoadingSpecifications = false;
        });
      } else {
        print('❌ Invalid project ID: ${widget.projectId}');
        setState(() {
          _isLoadingSpecifications = false;
        });
      }
    } catch (e) {
      print('💥 Error loading specifications: $e');
      setState(() {
        _isLoadingSpecifications = false;
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _actionFilter = 'any';
      _userFilter = '';
      _projectFilter = widget.projectId ?? ''; // Keep project filter if provided
      _startDate = null;
      _endDate = null;
      _searchController.clear();
    });
  }

  bool _isFilterActive() {
    return _actionFilter != 'any' ||
        _userFilter.isNotEmpty ||
        (_projectFilter.isNotEmpty && _projectFilter != widget.projectId) ||
        _startDate != null ||
        _endDate != null;
  }

  @override
  Widget build(BuildContext context) {
    // If project ID is provided, show only specifications
    if (widget.projectId != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Project Specifications'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: _isLoadingSpecifications
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading specifications...'),
                  ],
                ),
              )
            : _specifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No specifications found',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This project has no specifications yet',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _specifications.length,
                    itemBuilder: (context, index) {
                      return _buildSpecificationCard(_specifications[index]);
                    },
                  ),
      );
    }

    // Original audit logs view for all projects
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search in logs...',
                hintText: 'Search by summary, remarks, or any text',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Filters Section
          if (_showFilters) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list),
                      const SizedBox(width: 8),
                      const Text(
                        'Filters',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (_isFilterActive())
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Project Filter
                  Row(
                    children: [
                      const Text('Project: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _projectFilter.isEmpty ? null : _projectFilter,
                          hint: const Text('All projects'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('All projects'),
                            ),
                            ..._projectNames.map((name) => DropdownMenuItem<String>(
                              value: name,
                              child: Text(name),
                            )),
                          ],
                          onChanged: (value) => setState(() => _projectFilter = value ?? ''),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action Filter
                  Row(
                    children: [
                      const Text('Action: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _actionFilter,
                        items: const [
                          DropdownMenuItem(value: 'any', child: Text('All actions')),
                          DropdownMenuItem(value: 'create', child: Text('Create')),
                          DropdownMenuItem(value: 'update', child: Text('Update')),
                          DropdownMenuItem(value: 'upload_attachments', child: Text('Upload Files')),
                        ],
                        onChanged: (value) => setState(() => _actionFilter = value ?? 'any'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // User Filter
                  Row(
                    children: [
                      const Text('User: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Filter by user email',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => setState(() => _userFilter = value),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Date Range Filter
                  Row(
                    children: [
                      const Text('Date Range: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDateRange(context),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _startDate != null && _endDate != null
                                ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                : 'Select date range',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Active Filters Summary
          if (_isFilterActive()) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filters active: ${_projectFilter.isNotEmpty ? 'Project: $_projectFilter' : ''}${_actionFilter != 'any' ? ' Action: $_actionFilter' : ''}${_userFilter.isNotEmpty ? ' User: $_userFilter' : ''}${_startDate != null ? ' Date range selected' : ''}',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Audit Logs List
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _buildLogsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data!.docs;
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  if (data == null) return false;
                  
                  // Project filter
                  if (_projectFilter.isNotEmpty) {
                    final projectId = data['project_id'];
                    if (projectId == null) return false;
                    
                    // Check if the project name matches the filter
                    final projectName = _projectIdToName[projectId];
                    if (projectName != _projectFilter) return false;
                  }
                  
                  // Action filter
                  if (_actionFilter != 'any' && data['action'] != _actionFilter) {
                    return false;
                  }
                  
                  // User filter
                  if (_userFilter.isNotEmpty) {
                    final userEmail = (data['user_email'] ?? '').toString().toLowerCase();
                    if (!userEmail.contains(_userFilter.toLowerCase())) {
                      return false;
                    }
                  }
                  
                  // Date range filter
                  if (_startDate != null || _endDate != null) {
                    try {
                      final logDate = DateTime.parse(data['timestamp']);
                      if (_startDate != null && logDate.isBefore(_startDate!)) {
                        return false;
                      }
                      if (_endDate != null && logDate.isAfter(_endDate!)) {
                        return false;
                      }
                    } catch (e) {
                      // If timestamp parsing fails, exclude from results
                      return false;
                    }
                  }
                  
                  // Search filter
                  if (_searchController.text.isNotEmpty) {
                    final searchText = _searchController.text.toLowerCase();
                    final summary = (data['summary'] ?? '').toString().toLowerCase();
                    final remarks = (data['remarks'] ?? '').toString().toLowerCase();
                    final action = (data['action'] ?? '').toString().toLowerCase();
                    final userEmail = (data['user_email'] ?? '').toString().toLowerCase();
                    
                    if (!summary.contains(searchText) &&
                        !remarks.contains(searchText) &&
                        !action.contains(searchText) &&
                        !userEmail.contains(searchText)) {
                      return false;
                    }
                  }
                  
                  return true;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isFilterActive() ? Icons.filter_list_off : Icons.history,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isFilterActive() ? 'No logs match your filters' : 'No audit logs yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isFilterActive()
                              ? 'Try adjusting your filters or search terms'
                              : 'Create or edit projects to see audit logs',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        if (_isFilterActive()) ...[
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear All Filters'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final log = filteredDocs[index].data();
                    final summary = log['summary'] ?? log['action'];
                    final attachments = log['attachments'] as Map<String, dynamic>?;
                    final changes = log['changes'] as Map<String, dynamic>?;
                    
                    // Format timestamp
                    String formattedTime = 'Unknown';
                    try {
                      final timestamp = DateTime.parse(log['timestamp']);
                      formattedTime = '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
                    } catch (e) {
                      formattedTime = 'Invalid date';
                    }

                    // Get project name for display
                    String projectName = 'Unknown Project';
                    if (log['project_id'] != null) {
                      projectName = _projectIdToName[log['project_id']] ?? 'Unknown Project';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: _getActionIcon(log['action']),
                        title: Text(
                          summary,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${log['user_email']} — $formattedTime",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            if (log['project_id'] != null)
                              Text(
                                "Project: $projectName",
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (log['sequence'] != null)
                              Text(
                                "Sequence: #${log['sequence']}",
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
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
                                
                                // Raw Data (for debugging)
                                if (log['action'] == 'create' || log['action'] == 'update') ...[
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Raw Data:',
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
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      log.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildLogsStream() {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;
    
    if (widget.projectId != null) {
      // For project-specific logs
      return FirebaseFirestore.instance
          .collection('logs')
          .where('project_id', isEqualTo: widget.projectId)
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      // For all logs - filter by current user
      if (userEmail != null) {
        return FirebaseFirestore.instance
            .collection('logs')
            .where('user_email', isEqualTo: userEmail)
            .orderBy('timestamp', descending: true)
            .snapshots();
      } else {
        // Fallback if user is not authenticated
        return FirebaseFirestore.instance
            .collection('logs')
            .orderBy('timestamp', descending: true)
            .snapshots();
      }
    }
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

  Icon _getActionIcon(String? action) {
    switch (action) {
      case 'create':
        return Icon(Icons.add_circle, color: Colors.green.shade600);
      case 'update':
        return Icon(Icons.edit, color: Colors.blue.shade600);
      case 'upload_attachments':
        return Icon(Icons.attach_file, color: Colors.orange.shade600);
      default:
        return Icon(Icons.info, color: Colors.grey.shade600);
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

  Widget _buildSpecificationCard(Specification spec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Version ${spec.versionNo}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (spec.attachmentUrl != null)
                Icon(Icons.attach_file, color: Colors.green.shade600, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          _buildSpecificationDetail('Colour', spec.colour),
          _buildSpecificationDetail('Ironmongery', spec.ironmongery),
          _buildSpecificationDetail('U-Value', spec.uValue.toString()),
          _buildSpecificationDetail('G-Value', spec.gValue.toString()),
          _buildSpecificationDetail('Vents', spec.vents),
          _buildSpecificationDetail('Acoustics', spec.acoustics),
          _buildSpecificationDetail('SBD', spec.sbd),
          _buildSpecificationDetail('PAS24', spec.pas24),
          _buildSpecificationDetail('Restrictors', spec.restrictors),
          if (spec.specialComments.isNotEmpty)
            _buildSpecificationDetail('Special Comments', spec.specialComments),
          if (spec.attachmentUrl != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_file, color: Colors.green.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attachment: ${spec.attachmentUrl!.split('/').last}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecificationDetail(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}