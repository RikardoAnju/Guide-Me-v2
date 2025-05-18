import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guide_me/notifikasi_model.dart'; 

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _adminNotificationsCollection = 'admin_notifications';
  final String _processedRequestsCollection = 'processed_requests'; // New collection to track processed requests

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _listenersInitialized = false;
  
  // Tambahkan set untuk melacak request yang sudah diproses
  final Set<String> _processedRoleRequests = {};
  final Set<String> _processedDestinationRecommendations = {};

  // Stream notifikasi untuk UI
  Stream<List<AdminNotification>> getNotificationsStream() {
    return _firestore
        .collection(_adminNotificationsCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdminNotification.fromFirestore(doc))
            .toList());
  }

  Future<int> getUnreadCount() async {
    try {
      final snapshot = await _firestore
          .collection(_adminNotificationsCollection)
          .where('isRead', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_adminNotificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(_adminNotificationsCollection)
          .where('isRead', isEqualTo: false)
          .get();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  Future<String> _getUsernameFromUserId(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        return data?['name'] ??
            data?['username'] ??
            data?['displayName'] ??
            data?['email'] ??
            'Pengguna';
      }
    } catch (e) {
      print('Error getting username: $e');
    }
    return 'Pengguna';
  }

  // Add to processed_requests collection
  Future<void> _markRequestAsProcessed(String referenceId, String type) async {
    try {
      await _firestore
          .collection(_processedRequestsCollection)
          .doc(referenceId)
          .set({
        'type': type,
        'processedAt': FieldValue.serverTimestamp(),
      });
      
      // Add to in-memory set
      if (type == 'role_request') {
        _processedRoleRequests.add(referenceId);
      } else if (type == 'destinasi_requests') {
        _processedDestinationRecommendations.add(referenceId);
      }
    } catch (e) {
      print('Error marking request as processed: $e');
    }
  }

  // Check if request is already processed in the database
  Future<bool> _isRequestProcessed(String referenceId, String type) async {
    try {
      // First check in-memory cache
      if ((type == 'role_request' && _processedRoleRequests.contains(referenceId)) ||
          (type == 'destinasi_requests' && 
              _processedDestinationRecommendations.contains(referenceId))) {
        return true;
      }
      
      // If not in memory, check the database
      final doc = await _firestore
          .collection(_processedRequestsCollection)
          .doc(referenceId)
          .get();
          
      if (doc.exists) {
        // Add to in-memory cache too
        if (type == 'role_request') {
          _processedRoleRequests.add(referenceId);
        } else if (type == 'destinasi_requests') {
          _processedDestinationRecommendations.add(referenceId);
        }
        return true;
      }
      
      // Also check admin_notifications collection as a backup
      final check = await _firestore
          .collection(_adminNotificationsCollection)
          .where('referenceId', isEqualTo: referenceId)
          .where('type', isEqualTo: type)
          .get();
          
      return check.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if request is processed: $e');
      return false;
    }
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
    String? userId,
    String? referenceId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (referenceId != null) {
        // Check if request is already processed
        final isProcessed = await _isRequestProcessed(referenceId, type);
        if (isProcessed) {
          print('Request already processed, ignoring: $referenceId');
          return;
        }
        
        // Also update status in original collection to prevent reprocessing
        if (type == 'role_request') {
          await _firestore.collection('role_requests').doc(referenceId).update({
            'status': 'processing' // Change to a status that won't be picked up by listeners
          });
        } else if (type == 'destinasi_requests') {
          await _firestore.collection('destinasi_requests').doc(referenceId).update({
            'status': 'processing' // Change to a status that won't be picked up by listeners
          });
        }
      }

      String? username;
      String updatedMessage = message;

      if (userId != null) {
        username = await _getUsernameFromUserId(userId);
        if (message.contains(userId)) {
          updatedMessage = updatedMessage.replaceAll(userId, username);
        }
        if (message.startsWith('User ') || message.startsWith('user ')) {
          updatedMessage = '$username${message.substring(5)}';
        }
      }

      final notification = AdminNotification(
        id: '',
        title: title,
        message: updatedMessage,
        timestamp: DateTime.now(),
        type: type,
        isRead: false,
        userId: userId,
        username: username,
        referenceId: referenceId,
        additionalData: additionalData,
      );

      final docRef = await _firestore
          .collection(_adminNotificationsCollection)
          .add(notification.toFirestore());
          
      // Mark request as processed in our tracking collection
      if (referenceId != null) {
        await _markRequestAsProcessed(referenceId, type);
      }
      
      print('Notification added with ID: ${docRef.id}');
    } catch (e) {
      print('Error adding notification: $e');
    }
  }

  Stream<List<AdminNotification>> listenForRoleRequests() {
    return _firestore
        .collection('role_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
      List<AdminNotification> notifications = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        final role = data['role'] ?? 'tidak diketahui';
        final requestId = doc.id;
        
        // CRITICAL: Double-check if request is already processed in database
        // This ensures we never process the same request twice
        final isProcessed = await _isRequestProcessed(requestId, 'role_request');
        if (isProcessed) {
          // Update status in original collection to prevent future processing
          await _firestore.collection('role_requests').doc(requestId).update({
            'status': 'already_processed'
          }).catchError((e) {
            print('Error updating role request status: $e');
          });
          continue;
        }
        
        // Also check if this request already exists in admin_notifications
        final existingNotification = await _firestore
            .collection(_adminNotificationsCollection)
            .where('referenceId', isEqualTo: requestId)
            .get();
        
        if (existingNotification.docs.isNotEmpty) {
          // Already exists in notifications, mark as processed
          await _markRequestAsProcessed(requestId, 'role_request');
          
          // Update status in original collection
          await _firestore.collection('role_requests').doc(requestId).update({
            'status': 'already_processed'
          }).catchError((e) {
            print('Error updating role request status: $e');
          });
          
          continue;
        }

        String username = 'Pengguna';
        if (userId != null) {
          final storedUsername = data['username'] ?? '';
          username = storedUsername.isNotEmpty
              ? storedUsername
              : await _getUsernameFromUserId(userId);
        }

        notifications.add(AdminNotification(
          id: doc.id,
          title: 'Permintaan Peran Baru',
          message: '$username meminta peran $role',
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          type: 'role_request',
          isRead: false,
          userId: userId,
          username: username,
          referenceId: requestId,
        ));
      }

      return notifications;
    });
  }

  Stream<List<AdminNotification>> listenForDestinationRecommendations() {
    return _firestore
        .collection('destinasi_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
      List<AdminNotification> notifications = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        final destination = data['namaDestinasi'] ?? '-';
        final recommendationId = doc.id;
        
        // CRITICAL: Double-check if recommendation is already processed
        final isProcessed = await _isRequestProcessed(recommendationId, 'destinasi_requests');
        if (isProcessed) {
          // Update status in original collection to prevent future processing
          await _firestore.collection('destinasi_requests').doc(recommendationId).update({
            'status': 'already_processed'
          }).catchError((e) {
            print('Error updating destination recommendation status: $e');
          });
          continue;
        }
        
        // Also check if this request already exists in admin_notifications
        final existingNotification = await _firestore
            .collection(_adminNotificationsCollection)
            .where('referenceId', isEqualTo: recommendationId)
            .get();
        
        if (existingNotification.docs.isNotEmpty) {
          // Already exists in notifications, mark as processed
          await _markRequestAsProcessed(recommendationId, 'destinasi_requests');
          
          // Update status in original collection
          await _firestore.collection('destinasi_requests').doc(recommendationId).update({
            'status': 'already_processed'
          }).catchError((e) {
            print('Error updating destination recommendation status: $e');
          });
          
          continue;
        }

        String username = 'Pengguna';
        if (userId != null) {
          final storedUsername = data['username'] ?? '';
          username = storedUsername.isNotEmpty
              ? storedUsername
              : await _getUsernameFromUserId(userId);
        }

        notifications.add(AdminNotification(
          id: doc.id,
          title: 'Rekomendasi Destinasi Baru',
          message: '$username merekomendasikan destinasi $destination',
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          type: 'destinasi_requests',
          isRead: false,
          userId: userId,
          username: username,
          referenceId: recommendationId,
        ));
      }

      return notifications;
    });
  }

  Stream<List<AdminNotification>> listenForNewUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docChanges
          .where((change) => change.type == DocumentChangeType.added)
          .map((change) {
            final data = change.doc.data()!;
            if (data['notificationProcessed'] == true) return null;

            final username = data['name'] ??
                data['username'] ??
                data['displayName'] ??
                data['email'] ??
                'Pengguna Baru';

            return AdminNotification(
              id: change.doc.id,
              title: 'Pengguna Baru Terdaftar',
              message: '$username telah mendaftar',
              timestamp: (data['createdAt'] as Timestamp).toDate(),
              type: 'user_registration',
              isRead: false,
              userId: change.doc.id,
              username: username,
            );
          })
          .where((e) => e != null)
          .cast<AdminNotification>()
          .toList();
    });
  }

  Future<void> processAndSaveNotifications(
      List<AdminNotification> notifications) async {
    if (notifications.isEmpty) return;

    for (var notification in notifications) {
      try {
        // Check if notification should be processed
        if (notification.referenceId != null) {
          final isProcessed = await _isRequestProcessed(
              notification.referenceId!, notification.type);
          if (isProcessed) {
            continue;
          }
        }

        // Save notification to admin_notifications collection
        final docRef = await _firestore
            .collection(_adminNotificationsCollection)
            .add(notification.toFirestore());
            
        print('Saved notification with ID: ${docRef.id}');

        // Mark as processed and update original request status
        if (notification.referenceId != null) {
          await _markRequestAsProcessed(notification.referenceId!, notification.type);
          
          // Update status in original collection
          if (notification.type == 'role_request') {
            await _firestore.collection('role_requests').doc(notification.referenceId).update({
              'status': 'processing' // Change to status that won't be picked up again
            });
          } else if (notification.type == 'destination_recommendation') {
            await _firestore.collection('destination_recommendations')
                .doc(notification.referenceId).update({
              'status': 'processing' // Change to status that won't be picked up again
            });
          }
        }

        if (notification.type == 'user_registration' && notification.userId != null) {
          await _firestore
              .collection('users')
              .doc(notification.userId)
              .update({'notificationProcessed': true});
        }
      } catch (e) {
        print('Error saving notification: $e');
      }
    }
  }

  // Fungsi untuk sync set _processedRoleRequests dengan database
  Future<void> _syncProcessedRequests() async {
    try {
      // First clear any previous cache to avoid duplicates
      _processedRoleRequests.clear();
      _processedDestinationRecommendations.clear();
      
      // Sync from processed_requests collection
      final processedRequests = await _firestore
          .collection(_processedRequestsCollection)
          .get();
      
      for (var doc in processedRequests.docs) {
        final data = doc.data();
        final type = data['type'];
        final referenceId = doc.id;
        
        if (type == 'role_request') {
          _processedRoleRequests.add(referenceId);
        } else if (type == 'destination_recommendation') {
          _processedDestinationRecommendations.add(referenceId);
        }
      }
      
      // Find all notifs in admin_notifications with referenceId and add to processed
      final notifications = await _firestore
          .collection(_adminNotificationsCollection)
          .get();
      
      for (var doc in notifications.docs) {
        final data = doc.data();
        final referenceId = data['referenceId'];
        final type = data['type'];
        
        if (referenceId != null) {
          if (type == 'role_request') {
            _processedRoleRequests.add(referenceId);
            
            // Update status in original collection to prevent reprocessing
            await _firestore.collection('role_requests').doc(referenceId).update({
              'status': 'already_processed'
            }).catchError((e) {
              // If document doesn't exist or other error, just ignore
              print('Error updating role request status on sync: $e');
            });
          } else if (type == 'destination_recommendation') {
            _processedDestinationRecommendations.add(referenceId);
            
            // Update status in original collection to prevent reprocessing
            await _firestore.collection('destination_recommendations').doc(referenceId).update({
              'status': 'already_processed'
            }).catchError((e) {
              // If document doesn't exist or other error, just ignore
              print('Error updating destination recommendation status on sync: $e');
            });
          }
        }
      }
      
      print('Synced processed requests: ${_processedRoleRequests.length} role requests, '
            '${_processedDestinationRecommendations.length} destination recommendations');
      print('All existing notifications have been marked as processed.');
    } catch (e) {
      print('Error syncing processed requests: $e');
    }
  }

  void initNotificationListeners() {
    if (_listenersInitialized) {
      print('Listeners already initialized.');
      return;
    }

    _listenersInitialized = true;
    print('Initializing notification listeners');
    
    // CRITICAL: Need to first clean up any pending requests that were already processed
    _cleanUpPendingRequests().then((_) {
      // Then sync processed requests
      return _syncProcessedRequests();
    }).then((_) {
      // Then init listeners
      listenForRoleRequests().listen(processAndSaveNotifications);
      listenForDestinationRecommendations().listen(processAndSaveNotifications);
      listenForNewUsers().listen(processAndSaveNotifications);
    });
  }
  
  // New method to clean up pending requests at initialization
  Future<void> _cleanUpPendingRequests() async {
    try {
      // Get all existing notifications
      final notifications = await _firestore
          .collection(_adminNotificationsCollection)
          .get();
      
      // Create maps of reference IDs by type
      final Map<String, bool> roleRequestIds = {};
      final Map<String, bool> destinationRecommendationIds = {};
      
      // Collect all reference IDs from existing notifications
      for (var doc in notifications.docs) {
        final data = doc.data();
        final type = data['type'];
        final referenceId = data['referenceId'];
        
        if (referenceId != null) {
          if (type == 'role_request') {
            roleRequestIds[referenceId] = true;
          } else if (type == 'destination_recommendation') {
            destinationRecommendationIds[referenceId] = true;
          }
        }
      }
      
      // Update all pending role requests that already have notifications
      final pendingRoleRequests = await _firestore
          .collection('role_requests')
          .where('status', isEqualTo: 'pending')
          .get();
          
      for (var doc in pendingRoleRequests.docs) {
        if (roleRequestIds.containsKey(doc.id)) {
          await _firestore.collection('role_requests')
              .doc(doc.id)
              .update({'status': 'already_processed'});
          print('Updated role request status: ${doc.id}');
        }
      }
      
      // Update all pending destination recommendations that already have notifications
      final pendingDestRecommendations = await _firestore
          .collection('destination_recommendations')
          .where('status', isEqualTo: 'pending')
          .get();
          
      for (var doc in pendingDestRecommendations.docs) {
        if (destinationRecommendationIds.containsKey(doc.id)) {
          await _firestore.collection('destination_recommendations')
              .doc(doc.id)
              .update({'status': 'already_processed'});
          print('Updated destination recommendation status: ${doc.id}');
        }
      }
      
      print('Cleaned up pending requests that already have notifications');
    } catch (e) {
      print('Error cleaning up pending requests: $e');
    }
  }

  Future<void> removeDuplicateNotifications() async {
    try {
      final snapshot =
          await _firestore.collection(_adminNotificationsCollection).get();

      final Map<String, DocumentReference> seen = {};
      final List<DocumentReference> duplicates = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final key = '${data['referenceId'] ?? ''}:${data['type'] ?? ''}';

        if (key.trim().isEmpty) continue;

        if (seen.containsKey(key)) {
          duplicates.add(doc.reference);
        } else {
          seen[key] = doc.reference;
        }
      }

      for (int i = 0; i < duplicates.length; i += 400) {
        final batch = _firestore.batch();
        final end = (i + 400 < duplicates.length) ? i + 400 : duplicates.length;
        for (int j = i; j < end; j++) {
          batch.delete(duplicates[j]);
        }
        await batch.commit();
      }

      print('Removed ${duplicates.length} duplicate notifications.');
    } catch (e) {
      print('Error removing duplicates: $e');
    }
  }

  // Fungsi untuk menghapus satu notifikasi berdasarkan ID
  Future<void> deleteNotification(String notificationId) async {
    try {
      // Get notification first to check its type and referenceId
      final docSnapshot = await _firestore
          .collection(_adminNotificationsCollection)
          .doc(notificationId)
          .get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final type = data['type'];
        final referenceId = data['referenceId'];
        
        // Delete notification from Firestore
        await _firestore
            .collection(_adminNotificationsCollection)
            .doc(notificationId)
            .delete();
            
        // For role_request or destination_recommendation, mark as processed
        // and update the original request status
        if (referenceId != null) {
          // Immediately add to processed sets to prevent reprocessing
          if (type == 'role_request') {
            _processedRoleRequests.add(referenceId);
          } else if (type == 'destination_recommendation') {
            _processedDestinationRecommendations.add(referenceId);
          }
          
          // Mark in database as processed
          await _markRequestAsProcessed(referenceId, type);
          
          // CRITICAL: Update status in original collection to prevent reprocessing
          if (type == 'role_request') {
            await _firestore.collection('role_requests').doc(referenceId).update({
              'status': 'already_processed' // Use consistent status name 
            }).catchError((e) {
              print('Error updating role request status: $e');
            });
          } else if (type == 'destination_recommendation') {
            await _firestore.collection('destination_recommendations').doc(referenceId).update({
              'status': 'already_processed' // Use consistent status name
            }).catchError((e) {
              print('Error updating destination recommendation status: $e');
            });
          }
        }
        
        print('Notification deleted successfully and request marked as processed.');
      } else {
        print('Notification not found.');
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Method to manually clean up all pending requests 
  // Call this when you want to force cleanup all pending requests
  Future<void> cleanUpAllPendingRequests() async {
    try {
      print('Starting manual cleanup of all pending requests...');
      
      // Update all pending role requests to already_processed
      final pendingRoleRequests = await _firestore
          .collection('role_requests')
          .where('status', isEqualTo: 'pending')
          .get();
          
      int roleRequestsCount = 0;
      for (var doc in pendingRoleRequests.docs) {
        await _firestore.collection('role_requests')
            .doc(doc.id)
            .update({'status': 'already_processed'});
        
        // Also mark as processed in our tracking
        await _markRequestAsProcessed(doc.id, 'role_request');
        roleRequestsCount++;
      }
      
      // Update all pending destination recommendations to already_processed
      final pendingDestRecommendations = await _firestore
          .collection('destination_recommendations')
          .where('status', isEqualTo: 'pending')
          .get();
          
      int destRecommendationsCount = 0;
      for (var doc in pendingDestRecommendations.docs) {
        await _firestore.collection('destination_recommendations')
            .doc(doc.id)
            .update({'status': 'already_processed'});
        
        // Also mark as processed in our tracking
        await _markRequestAsProcessed(doc.id, 'destination_recommendation');
        destRecommendationsCount++;
      }
      
      print('Cleaned up $roleRequestsCount pending role requests and '
            '$destRecommendationsCount pending destination recommendations');
      
      // Force resync of processed requests
      await _syncProcessedRequests();
      
      return;
    } catch (e) {
      print('Error in manual cleanup of pending requests: $e');
    }
  }
}