import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth.dart';
import 'projects.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Test Firestore access on startup
  _testFirestoreOnStartup();
  
  runApp(const MyApp());
}

Future<void> _testFirestoreOnStartup() async {
  try {
    print('Testing Firestore access on startup...');
    
    // Test read access
    final projectsSnapshot = await FirebaseFirestore.instance
        .collection('projects')
        .limit(1)
        .get();
    
    print('Startup Firestore test - Read access: ${projectsSnapshot.docs.length} documents found');
    
    // Test if we can see the projects collection structure
    if (projectsSnapshot.docs.isNotEmpty) {
      final doc = projectsSnapshot.docs.first;
      final data = doc.data();
      print('Startup Firestore test - Sample project data: $data');
    }
    
  } catch (e) {
    print('Startup Firestore test failed: $e');
    print('This indicates a Firestore configuration or security rules issue');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Projects',
      theme: ThemeData(useMaterial3: true),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.active) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final user = snapshot.data;
          if (user == null) return const AuthPage();

          return const ProjectsPage();
        },
      ),
    );
  }
}
