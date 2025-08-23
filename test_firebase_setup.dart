import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print('=== Firebase Setup Test ===');
  
  // Test 1: Authentication
  print('\n1. Testing Authentication...');
  try {
    final auth = FirebaseAuth.instance;
    print('✅ Firebase Auth initialized');
    
    // Check if user is signed in
    final user = auth.currentUser;
    if (user != null) {
      print('✅ User is signed in: ${user.email}');
    } else {
      print('⚠️ No user signed in (this is normal for testing)');
    }
  } catch (e) {
    print('❌ Authentication test failed: $e');
  }
  
  // Test 2: Firestore Database
  print('\n2. Testing Firestore Database...');
  try {
    final firestore = FirebaseFirestore.instance;
    print('✅ Firestore initialized');
    
    // Test write access
    final testDoc = await firestore.collection('test_access').add({
      'test': true,
      'timestamp': DateTime.now().toIso8601String(),
      'message': 'Firestore write test successful',
    });
    print('✅ Firestore write test passed - Document ID: ${testDoc.id}');
    
    // Test read access
    final snapshot = await testDoc.get();
    print('✅ Firestore read test passed - Data: ${snapshot.data()}');
    
    // Clean up test document
    await testDoc.delete();
    print('✅ Firestore delete test passed');
    
  } catch (e) {
    print('❌ Firestore test failed: $e');
    print('   This usually means Firestore is not enabled or security rules are too restrictive');
  }
  
  // Test 3: Firebase Storage
  print('\n3. Testing Firebase Storage...');
  try {
    final storage = FirebaseStorage.instance;
    print('✅ Firebase Storage initialized');
    
    // Test storage reference creation
    final ref = storage.ref('test/test_file.txt');
    print('✅ Storage reference created: ${ref.fullPath}');
    
    // Note: We won't actually upload a file in this test to avoid complexity
    print('✅ Firebase Storage test passed (reference creation)');
    
  } catch (e) {
    print('❌ Firebase Storage test failed: $e');
    print('   This usually means Firebase Storage is not enabled');
  }
  
  // Test 4: Security Rules (if user is authenticated)
  print('\n4. Testing Security Rules...');
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      // Test user-specific data access
      final userDoc = await FirebaseFirestore.instance
          .collection('projects')
          .where('created_by', isEqualTo: user.email)
          .limit(1)
          .get();
      
      print('✅ Security rules test passed - User can query their own data');
      print('   Found ${userDoc.docs.length} projects for user ${user.email}');
      
    } catch (e) {
      print('❌ Security rules test failed: $e');
      print('   This might indicate security rules are too restrictive');
    }
  } else {
    print('⚠️ Skipping security rules test - no user signed in');
  }
  
  print('\n=== Test Summary ===');
  print('If you see any ❌ errors above, you need to:');
  print('1. Enable the corresponding Firebase service');
  print('2. Check security rules');
  print('3. Verify Firebase configuration');
  print('\nFor detailed setup instructions, see the Firebase Console documentation.');
}
