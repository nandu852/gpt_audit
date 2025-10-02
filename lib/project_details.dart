import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'edit_project_page.dart';
import 'audit_log_page.dart';
import 'models/project.dart';
import 'services/project_service.dart';
import 'services/rfi_service.dart';

class ProjectDetailsPage extends StatefulWidget {
  final Project? project;
  final String? projectId;
  
  const ProjectDetailsPage({super.key, this.project, this.projectId});

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  Project? _project;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    print('🔍 ProjectDetailsPage: Loading project...');
    print('🔍 Project object: ${widget.project}');
    print('🔍 Project ID: ${widget.projectId}');
    
    if (widget.project != null) {
      // If project is already provided, use it
      print('📋 Using provided project object');
      setState(() {
        _project = widget.project;
        _isLoading = false;
      });
    } else if (widget.projectId != null) {
      // If only projectId is provided, fetch full project details
      print('📋 Fetching project with ID: ${widget.projectId}');
      try {
        final projectId = int.tryParse(widget.projectId!);
        print('📋 Parsed project ID: $projectId');
        if (projectId != null) {
          final project = await ProjectService.instance.getProjectById(projectId);
          print('📋 Retrieved project: $project');
          setState(() {
            _project = project;
            _isLoading = false;
            _error = project == null ? 'Project not found' : null;
          });
        } else {
          print('❌ Invalid project ID: ${widget.projectId}');
          setState(() {
            _error = 'Invalid project ID';
            _isLoading = false;
          });
        }
      } catch (e) {
        print('💥 Error loading project: $e');
        setState(() {
          _error = 'Failed to load project: $e';
          _isLoading = false;
        });
      }
    } else {
      print('❌ No project or project ID provided');
      setState(() {
        _error = 'No project or project ID provided';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Project Details'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _project == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Project Details'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Project not found',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProjectPage(projectId: _project!.id?.toString() ?? ''),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AuditLogPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildProjectDetails(_project!),
    );
  }

  Widget _buildProjectDetails(Project project) {
    final createdDate = project.createdAt;
    final updatedDate = project.updatedAt;
    final createdStr = createdDate != null 
        ? DateFormat('MMM d, y • h:mm a').format(createdDate)
        : 'Unknown date';
    final updatedStr = updatedDate != null 
        ? DateFormat('MMM d, y • h:mm a').format(updatedDate)
        : 'Unknown date';
    
    final status = project.status ?? 'Unknown';
    final statusColor = _getStatusColor(status);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Header
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.projectName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Type: ${project.projectType}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created: $createdStr',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (updatedStr != createdStr) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Updated: $updatedStr',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Specifications
          if (project.projectType == 'windows') _buildSpecificationsCard(project),
          
          // Special Requirements
          if (project.specifications.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSpecialRequirementsCard(project),
          ],
          
          // RFI Status
          if (project.rfis.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildRFIStatusCard(project),
          ],
          
          // Project Information
          const SizedBox(height: 16),
          _buildProjectInfoCard(project),
        ],
      ),
    );
  }

  Widget _buildSpecificationsCard(Project project) {
    if (project.specifications.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final spec = project.specifications.first; // Use first specification
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSpecificationRow('Color', spec.colour),
            _buildSpecificationRow('Ironmongery', spec.ironmongery),
            _buildSpecificationRow('U-Value', spec.uValue.toString()),
            _buildSpecificationRow('G-Value', spec.gValue.toString()),
            _buildSpecificationRow('Vents', spec.vents),
            _buildSpecificationRow('Acoustics', spec.acoustics),
            _buildSpecificationRow('SBD', spec.sbd),
            _buildSpecificationRow('PAS24', spec.pas24),
            _buildSpecificationRow('Restrictors', spec.restrictors),
            if (spec.specialComments.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSpecificationRow('Special Comments', spec.specialComments),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificationRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'Not specified',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialRequirementsCard(Project project) {
    final specialComments = project.specifications.isNotEmpty 
        ? project.specifications.first.specialComments 
        : '';
    
    if (specialComments.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Special Requirements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              specialComments,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRFIStatusCard(Project project) {
    final totalItems = project.rfis.length;
    final completedItems = project.rfis.where((rfi) => rfi.status == 'answered').length;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'RFI Status',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$completedItems/$totalItems',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: completedItems == totalItems ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: totalItems > 0 ? completedItems / totalItems : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                completedItems == totalItems ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            ...project.rfis.map((rfi) => _buildRFIItemFromRfi(rfi)),
          ],
        ),
      ),
    );
  }

  Widget _buildRFIItemFromRfi(Rfi rfi) {
    final isCompleted = rfi.status == 'answered' || rfi.answerValue != null;
    final answerValue = rfi.answerValue;
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  rfi.questionText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isCompleted ? Colors.green.shade700 : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          if (answerValue != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: answerValue == 'yes' ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Answer: ${answerValue.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: answerValue == 'yes' ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showEditRfiDialog(rfi),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _answerRfi(rfi.id!, 'yes'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Yes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _answerRfi(rfi.id!, 'no'),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('No'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRFIItem(Map<String, dynamic> item) {
    final isCompleted = item['completed'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey[600] : null,
                  ),
                ),
                if (item['description'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectInfoCard(Project project) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Project ID', project.id?.toString() ?? 'N/A'),
            _buildInfoRow('Company', project.companyName),
            _buildInfoRow('Address', project.companyAddress),
            _buildInfoRow('Type', project.projectType),
            if (project.createdAt != null)
              _buildInfoRow('Created', DateFormat('MMM d, y').format(project.createdAt!)),
            if (project.updatedAt != null)
              _buildInfoRow('Updated', DateFormat('MMM d, y').format(project.updatedAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'Unknown',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _answerRfi(int rfiId, String answerValue) async {
    try {
      print('💬 Answering RFI $rfiId with: $answerValue');
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final success = await RFIService.instance.answerRfi(rfiId, answerValue);
      
      // Hide loading indicator
      Navigator.pop(context);

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('RFI answered: $answerValue'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload the project to get updated RFI data
        await _loadProject();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to answer RFI'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      print('💥 Error answering RFI: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditRfiDialog(Rfi rfi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit RFI Answer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rfi.questionText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Current Answer:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: rfi.answerValue == 'yes' ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                rfi.answerValue?.toUpperCase() ?? 'Not answered',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: rfi.answerValue == 'yes' ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'New Answer:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _answerRfi(rfi.id!, 'yes');
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Yes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _answerRfi(rfi.id!, 'no');
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('No'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}