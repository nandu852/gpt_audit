import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Manual Firebase options for platforms that don't read native config files
/// (e.g., Windows). For Android we mirror the values from
/// `android/app/google-services.json` so a single codepath works everywhere.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web Firebase options not configured. Run flutterfire configure.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyBr2_1BLbXk1-GGgjaFWjWo0q2E6YaQQYk',
          appId: '1:714054305134:android:8faf76a9847ec7daf2ad7f',
          messagingSenderId: '714054305134',
          projectId: 'project-management-b73f3',
          storageBucket: 'project-management-b73f3.firebasestorage.app',
          // Add these required fields for authentication
          authDomain: 'project-management-b73f3.firebaseapp.com',
          iosClientId: '1:714054305134:ios:8faf76a9847ec7daf2ad7f',
          iosBundleId: 'com.nk.project_management',
        );

      case TargetPlatform.windows:
        return const FirebaseOptions(
          apiKey: 'AIzaSyBr2_1BLbXk1-GGgjaFWjWo0q2E6YaQQYk',
          appId: '1:714054305134:android:8faf76a9847ec7daf2ad7f',
          messagingSenderId: '714054305134',
          projectId: 'project-management-b73f3',
          storageBucket: 'project-management-b73f3.firebasestorage.app',
        );

      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Firebase options not configured for this platform. Run flutterfire configure.');
    }
  }
}


