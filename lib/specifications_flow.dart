import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'logging.dart';
import 'rfi_flow.dart';
import 'home_dashboard.dart';
import 'services/project_service.dart';
import 'models/project.dart';

class SpecificationsFlow extends StatefulWidget {
  const SpecificationsFlow({super.key});

  @override
  State<SpecificationsFlow> createState() => _SpecificationsFlowState();
}

class _SpecificationsFlowState extends State<SpecificationsFlow> {
  String _selectedType = 'windows';
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Form controllers
  final _projectNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _colorController = TextEditingController();
  final _ironmongeryController = TextEditingController();
  final _uValueController = TextEditingController();
  final _gValueController = TextEditingController();
  final _ventsController = TextEditingController();
  final _acousticsController = TextEditingController();
  final _sbdController = TextEditingController();
  final _pas24Controller = TextEditingController();
  final _restrictorsController = TextEditingController();
  final _specialRequirementsController = TextEditingController();
  
  // Image storage
  Map<String, File?> _images = {};
  Map<String, String?> _imageUrls = {};

  @override
  void dispose() {
    _projectNameController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _colorController.dispose();
    _ironmongeryController.dispose();
    _uValueController.dispose();
    _gValueController.dispose();
    _ventsController.dispose();
    _acousticsController.dispose();
    _sbdController.dispose();
    _pas24Controller.dispose();
    _restrictorsController.dispose();
    _specialRequirementsController.dispose();
    super.dispose();
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Project - Specifications'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Type Selection
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Project Type',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeOption('windows', 'Windows', Icons.window),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTypeOption('doors', 'Doors', Icons.door_front_door),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Project Details Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Project Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _projectNameController,
                        decoration: const InputDecoration(
                          labelText: 'Project Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Project name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _companyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Company Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Company name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _companyAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Company Address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        maxLines: 2,
                        validator: (value) =>
                            value!.isEmpty ? 'Company address is required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Specifications Form
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                      
                      if (_selectedType == 'windows') ...[
                        _buildSpecificationField(
                          'Color',
                          _colorController,
                          Icons.palette,
                          isRequired: true,
                        ),
                        _buildSpecificationField(
                          'Ironmongery',
                          _ironmongeryController,
                          Icons.build,
                          isRequired: true,
                        ),
                        _buildSpecificationField(
                          'U-Value',
                          _uValueController,
                          Icons.thermostat,
                          isRequired: true,
                        ),
                        _buildSpecificationField(
                          'G-Value',
                          _gValueController,
                          Icons.wb_sunny,
                          isRequired: true,
                        ),
                        _buildSpecificationField(
                          'Vents',
                          _ventsController,
                          Icons.air,
                          isRequired: true,
                        ),
                        _buildSpecificationField(
                          'Acoustics',
                          _acousticsController,
                          Icons.volume_up,
                          isRequired: true,
                        ),
                        _buildSpecificationField(
                          'SBD',
                          _sbdController,
                          Icons.security,
                          isRequired: true,
                        ),
                        _buildSpecificationField(
                          'PAS24',
                          _pas24Controller,
                          Icons.verified,
                          isRequired: true,
                        ),
                        _buildSpecificationField(
                          'Restrictors',
                          _restrictorsController,
                          Icons.block,
                          isRequired: true,
                        ),
                      ],
                      
                      // Special Requirements (always shown)
                      _buildSpecificationField(
                        'Special Requirements',
                        _specialRequirementsController,
                        Icons.note_add,
                        isRequired: false,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () {
                        // Navigate back to home dashboard
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeDashboard()),
                          (route) => false,
                        );
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _saveProject,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save & Continue to RFI'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption(String value, String label, IconData icon) {
    final isSelected = _selectedType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected 
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected 
                    ? Theme.of(context).primaryColor
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificationField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: 'Enter $label',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_a_photo),
                onPressed: () => _pickImage(label),
                tooltip: 'Add Image',
              ),
            ),
            validator: isRequired ? (value) {
              if (value?.trim().isEmpty ?? true) {
                return '$label is required';
              }
              return null;
            } : null,
          ),
          if (_images[label] != null) ...[
            const SizedBox(height: 8),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _images[label]!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                        onPressed: () {
                          setState(() {
                            _images.remove(label);
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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

  Future<void> _pickImage(String field) async {
    try {
      // Show dialog to choose between camera and gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      
      if (source != null) {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: source);
        
        if (image != null) {
          setState(() {
            _images[field] = File(image.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Upload images first (still using Firebase Storage for now)
      await _uploadImages();
      
      // Create project using API
      final project = Project(
        projectName: _projectNameController.text.trim().isNotEmpty 
            ? _projectNameController.text.trim()
            : 'New ${_capitalize(_selectedType)} Project',
        companyName: _companyNameController.text.trim().isNotEmpty
            ? _companyNameController.text.trim()
            : 'Your Company',
        companyAddress: _companyAddressController.text.trim().isNotEmpty
            ? _companyAddressController.text.trim()
            : 'Your Address',
        projectType: _selectedType,
        status: 'active',
        specifications: _selectedType == 'windows' ? [
          Specification(
            versionNo: 1,
            colour: _colorController.text.trim(),
            ironmongery: _ironmongeryController.text.trim(),
            uValue: double.tryParse(_uValueController.text.trim()) ?? 0.0,
            gValue: double.tryParse(_gValueController.text.trim()) ?? 0.0,
            vents: _ventsController.text.trim(),
            acoustics: _acousticsController.text.trim(),
            sbd: _sbdController.text.trim(),
            pas24: _pas24Controller.text.trim(),
            restrictors: _restrictorsController.text.trim(),
            specialComments: _specialRequirementsController.text.trim(),
            attachmentUrl: _imageUrls['color_image'] ?? '',
          ),
        ] : [],
        rfis: [], // Don't send RFIs when creating project - they're added later
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save project via API
      final createdProject = await ProjectService.instance.createProject(project);
      
      if (createdProject == null) {
        throw Exception('Failed to create project');
      }
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to RFI flow
      if (createdProject.id != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RFIFlow(projectId: createdProject.id.toString()),
          ),
        );
      } else {
        // If project creation failed, go back to home dashboard
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeDashboard(),
          ),
          (route) => false,
        );
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final storage = FirebaseStorage.instance;
    
    for (var entry in _images.entries) {
      if (entry.value != null) {
        try {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${entry.key}.jpg';
          final ref = storage.ref('specifications/${user.uid}/$fileName');
          
          await ref.putFile(entry.value!);
          final url = await ref.getDownloadURL();
          
          _imageUrls[entry.key] = url;
        } catch (e) {
          print('Error uploading image for ${entry.key}: $e');
        }
      }
    }
  }
}
