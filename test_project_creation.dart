import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print('=== Project Creation and User Filtering Test ===');
  
  // Test 1: Check authentication
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    print('✅ User authenticated: ${user.email}');
  } else {
    print('❌ No user authenticated');
    return;
  }
  
  // Test 2: Create a test project
  try {
    print('\nCreating test project...');
    final now = DateTime.now().toIso8601String();
    final projectData = {
      'company_name': 'Test Company ${DateTime.now().millisecondsSinceEpoch}',
      'requirements': 'Test requirements',
      'specifications': 'Test specifications',
      'created_by': user.email,
      'created_at': now,
      'updated_by': user.email,
      'updated_at': now,
      'log_sequence': 0,
    };
    
    final doc = await FirebaseFirestore.instance.collection('projects').add(projectData);
    print('✅ Test project created with ID: ${doc.id}');
    
    // Test 3: Verify user filtering works
    print('\nTesting user filtering...');
    final userProjects = await FirebaseFirestore.instance
        .collection('projects')
        .where('created_by', isEqualTo: user.email)
        .get();
    
    print('✅ Found ${userProjects.docs.length} projects for user ${user.email}');
    
    // Test 4: Create audit log
    print('\nCreating audit log...');
    await FirebaseFirestore.instance.collection('logs').add({
      'project_id': doc.id,
      'action': 'create',
      'user_email': user.email,
      'timestamp': now,
      'sequence': 1,
      'summary': 'Test project created',
    });
    print('✅ Audit log created');
    
    // Test 5: Verify audit log filtering
    print('\nTesting audit log filtering...');
    final userLogs = await FirebaseFirestore.instance
        .collection('logs')
        .where('user_email', isEqualTo: user.email)
        .get();
    
    print('✅ Found ${userLogs.docs.length} logs for user ${user.email}');
    
  } catch (e) {
    print('❌ Test failed: $e');
  }
  
  print('\n=== Test completed ===');
}

