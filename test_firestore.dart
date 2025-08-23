import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print('Firebase initialized successfully');
  
  // Test 1: Check if we can access Firestore
  try {
    print('Testing basic Firestore access...');
    final testDoc = await FirebaseFirestore.instance
        .collection('test')
        .add({
      'message': 'Hello from test script',
      'timestamp': DateTime.now().toIso8601String(),
    });
    print('✅ Successfully created test document: ${testDoc.id}');
    
    // Clean up test document
    await testDoc.delete();
    print('✅ Successfully deleted test document');
  } catch (e) {
    print('❌ Firestore access failed: $e');
  }
  
  // Test 2: Check if projects collection exists and has data
  try {
    print('\nTesting projects collection...');
    final projectsSnapshot = await FirebaseFirestore.instance
        .collection('projects')
        .limit(5)
        .get();
    
    print('Found ${projectsSnapshot.docs.length} projects');
    
    if (projectsSnapshot.docs.isEmpty) {
      print('No projects found. Creating sample project...');
      
      final newProject = await FirebaseFirestore.instance
          .collection('projects')
          .add({
        'company_name': 'Test Company',
        'project_name': 'Sample Project',
        'description': 'This is a test project created by the debug script',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'created_by': 'test_user',
        'files': [],
      });
      
      print('✅ Created sample project: ${newProject.id}');
    } else {
      print('Existing projects:');
      for (var doc in projectsSnapshot.docs) {
        final data = doc.data();
        print('  - ${data['company_name']}: ${data['project_name']}');
      }
    }
  } catch (e) {
    print('❌ Projects collection test failed: $e');
  }
  
  // Test 3: Test authentication
  try {
    print('\nTesting authentication...');
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('✅ User is authenticated: ${user.email}');
    } else {
      print('⚠️ No user is currently authenticated');
    }
  } catch (e) {
    print('❌ Authentication test failed: $e');
  }
  
  print('\nTest completed!');
}
