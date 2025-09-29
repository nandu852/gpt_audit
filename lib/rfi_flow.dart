import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'logging.dart';
import 'home_dashboard.dart';
import 'notification_service.dart';
import 'services/rfi_service.dart';
import 'services/auth_service.dart';

class RFIFlow extends StatefulWidget {
  final String projectId;
  
  const RFIFlow({super.key, required this.projectId});

  @override
  State<RFIFlow> createState() => _RFIFlowState();
}

class _RFIFlowState extends State<RFIFlow> {
  List<RFIItem> _rfiItems = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRFIItems();
  }

  void _loadRFIItems() {
    // Default RFI items
    _rfiItems = [
      RFIItem(
        id: '1',
        title: 'Structural Integrity',
        description: 'Verify structural integrity meets requirements',
        completed: false,
      ),
      RFIItem(
        id: '2',
        title: 'Fire Safety Compliance',
        description: 'Ensure fire safety standards are met',
        completed: false,
      ),
      RFIItem(
        id: '3',
        title: 'Energy Efficiency',
        description: 'Confirm energy efficiency requirements',
        completed: false,
      ),
      RFIItem(
        id: '4',
        title: 'Accessibility Standards',
        description: 'Verify accessibility compliance',
        completed: false,
      ),
      RFIItem(
        id: '5',
        title: 'Quality Assurance',
        description: 'Final quality check and approval',
        completed: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RFI Requirements'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewRFIItem,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'RFI Progress',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_getCompletedCount()}/${_rfiItems.length} items completed',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _rfiItems.isEmpty ? 0 : _getCompletedCount() / _rfiItems.length,
                  backgroundColor: Colors.white30,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
          
          // RFI Items List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _rfiItems.length,
              itemBuilder: (context, index) {
                final item = _rfiItems[index];
                return _buildRFIItem(item, index);
              },
            ),
          ),
          
          // Save Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveRFI,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save RFI Requirements'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRFIItem(RFIItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: item.completed,
                  onChanged: (value) {
                    setState(() {
                      item.completed = value ?? false;
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: item.completed 
                              ? TextDecoration.lineThrough 
                              : null,
                          color: item.completed 
                              ? Colors.grey[600] 
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeRFIItem(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _getCompletedCount() {
    return _rfiItems.where((item) => item.completed).length;
  }

  void _addNewRFIItem() {
    showDialog(
      context: context,
      builder: (context) => _AddRFIItemDialog(
        onAdd: (title, description) {
          setState(() {
            _rfiItems.add(
              RFIItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: title,
                description: description,
                completed: false,
              ),
            );
          });
        },
      ),
    );
  }

  void _removeRFIItem(int index) {
    setState(() {
      _rfiItems.removeAt(index);
    });
  }

  Future<void> _saveRFI() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Check if projectId is valid
      if (widget.projectId.isEmpty) {
        throw Exception('Invalid project ID');
      }

      final projectId = int.tryParse(widget.projectId);
      if (projectId == null) {
        throw Exception('Invalid project ID format');
      }

      // Convert RFI items to API format
      final rfiItemsData = _rfiItems.map((item) => {
        'question_text': item.description,
        'status': item.completed ? 'answered' : 'pending',
        'answer_text': item.completed ? 'Completed' : null,
      }).toList();

      // Update project RFI data via API
      final rfiUpdated = await RFIService.instance.updateProjectRFI(projectId, rfiItemsData);
      
      if (!rfiUpdated) {
        throw Exception('Failed to update RFI data');
      }

      // Update project status based on completion
      final completedCount = _getCompletedCount();
      final totalCount = _rfiItems.length;
      final projectStatus = completedCount == totalCount ? 'completed' : 'pending';
      
      await RFIService.instance.updateProjectStatus(projectId, projectStatus);

      // Log RFI update
      await const AuditLogger().writeLog(
        projectId: widget.projectId,
        action: 'rfi_update',
        summary: 'RFI requirements updated: $completedCount/$totalCount completed',
      );

      // Schedule notifications for pending items
      if (completedCount < totalCount) {
        await NotificationService().scheduleRFIReminder(widget.projectId);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('RFI requirements saved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeDashboard()),
        (route) => false,
      );

    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving RFI: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}

class RFIItem {
  final String id;
  final String title;
  final String description;
  bool completed;

  RFIItem({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
  });
}

class _AddRFIItemDialog extends StatefulWidget {
  final Function(String title, String description) onAdd;

  const _AddRFIItemDialog({required this.onAdd});

  @override
  State<_AddRFIItemDialog> createState() => _AddRFIItemDialogState();
}

class _AddRFIItemDialogState extends State<_AddRFIItemDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add RFI Item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Description is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onAdd(
                _titleController.text.trim(),
                _descriptionController.text.trim(),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
