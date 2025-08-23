import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuditLogger {
  const AuditLogger();

  Future<int> _nextSequence(String projectId) async {
    final firestore = FirebaseFirestore.instance;
    final projectRef = firestore.collection('projects').doc(projectId);

    try {
      return await firestore.runTransaction<int>((transaction) async {
        final snapshot = await transaction.get(projectRef);
        if (!snapshot.exists) {
          print('Warning: Project $projectId does not exist when trying to get sequence');
          return 1; // Start with 1 if project doesn't exist
        }
        
        final current = (snapshot.data()?['log_sequence'] ?? 0) as int;
        final next = current + 1;
        transaction.update(projectRef, {'log_sequence': next});
        print('Updated log sequence for project $projectId: $current -> $next');
        return next;
      });
    } catch (e) {
      print('Error getting next sequence for project $projectId: $e');
      // Fallback: try to get current sequence without transaction
      try {
        final snapshot = await projectRef.get();
        final current = (snapshot.data()?['log_sequence'] ?? 0) as int;
        final next = current + 1;
        await projectRef.update({'log_sequence': next});
        print('Updated log sequence (fallback) for project $projectId: $current -> $next');
        return next;
      } catch (fallbackError) {
        print('Fallback sequence update failed for project $projectId: $fallbackError');
        return DateTime.now().millisecondsSinceEpoch; // Use timestamp as fallback
      }
    }
  }

  Future<String> writeLog({
    required String projectId,
    required String action,
    String? summary,
    Map<String, dynamic>? changes,
    String? remarks,
    Map<String, dynamic>? attachments,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      throw Exception('User not authenticated when trying to write log');
    }
    
    final email = user.email ?? 'unknown';
    final userName = user.displayName;
    final timestamp = DateTime.now().toIso8601String();
    
    print('Writing log for project $projectId, action: $action, user: $email');
    
    try {
      final sequence = await _nextSequence(projectId);
      
      final docRef = firestore.collection('logs').doc();
      final log = <String, dynamic>{
        'log_id': docRef.id,
        'project_id': projectId,
        'action': action,
        'user_email': email,
        if (userName != null && userName.isNotEmpty) 'user_name': userName,
        'timestamp': timestamp,
        'sequence': sequence,
        if (summary != null) 'summary': summary,
        if (changes != null) 'changes': changes,
        if (remarks != null) 'remarks': remarks,
        if (attachments != null) 'attachments': attachments,
      };
      
      print('Log data to be written: $log');
      
      await docRef.set(log);
      
      print('Log written successfully with ID: ${docRef.id}');
      
      // Also update the project's updated_at timestamp
      try {
        await firestore.collection('projects').doc(projectId).update({
          'updated_at': timestamp,
          'updated_by': email,
        });
        print('Project $projectId updated_at timestamp updated');
      } catch (e) {
        print('Warning: Could not update project timestamp: $e');
      }
      
      return docRef.id;
    } catch (e) {
      print('Error writing log for project $projectId: $e');
      rethrow;
    }
  }
}


