import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class SupportTicketService {
  static final SupportTicketService _instance = SupportTicketService._internal();
  factory SupportTicketService() => _instance;
  SupportTicketService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Streams for UI mapping from Firestore
  Stream<List<Map<String, dynamic>>> get pendingStream =>
      _firestore.collection('support_tickets').where('status', isEqualTo: 'pending').snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());

  Stream<List<Map<String, dynamic>>> get inProgressStream =>
      _firestore.collection('support_tickets').where('status', isEqualTo: 'in_progress').snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());

  Stream<List<Map<String, dynamic>>> get resolvedStream =>
      _firestore.collection('support_tickets').where('status', isEqualTo: 'resolved').snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());

  // Helper getters to read the current state lists asynchronously
  // Note: These do not cache in-memory in a sync way anymore as it's stream-based.
  // We'll maintain these as Futures if components expected them sync, but since
  // the previous implementation provided arrays `pendingTickets`, we can mock empty
  // arrays for sync calls and rely on streams for the UI.
  List<Map<String, dynamic>> _pendingCache = [];
  List<Map<String, dynamic>> _inProgressCache = [];
  List<Map<String, dynamic>> _resolvedCache = [];

  StreamSubscription? _pendingSub;
  StreamSubscription? _inProgressSub;
  StreamSubscription? _resolvedSub;

  void initialize() {
    _pendingSub = pendingStream.listen((data) => _pendingCache = data);
    _inProgressSub = inProgressStream.listen((data) => _inProgressCache = data);
    _resolvedSub = resolvedStream.listen((data) => _resolvedCache = data);
  }

  List<Map<String, dynamic>> get pendingTickets => _pendingCache;
  List<Map<String, dynamic>> get inProgressTickets => _inProgressCache;
  List<Map<String, dynamic>> get resolvedTickets => _resolvedCache;

  /// Adds a new ticket from the user side.
  Future<void> addTicket({
    required String title,
    required String description,
    required String category,
    String? busId,
    List<Map<String, dynamic>>? evidenceFiles,
  }) async {
    final randomStr = (10000 + Random().nextInt(90000)).toString();
    final documentId = '#YW-$randomStr';

    List<Map<String, dynamic>> uploadedEvidence = [];

    // Upload files to Firebase Storage if evidence exists
    if (evidenceFiles != null && evidenceFiles.isNotEmpty) {
      for (int i = 0; i < evidenceFiles.length; i++) {
        final fileMap = evidenceFiles[i];
        final File file = File(fileMap['path']);
        final isVideo = fileMap['type'] == 'video';
        
        try {
          final ext = isVideo ? 'mp4' : 'jpg';
          final storageRef = _storage.ref().child('support_tickets/$documentId/evidence_$i.$ext');
          final uploadTask = await storageRef.putFile(file);
          final downloadUrl = await uploadTask.ref.getDownloadURL();
          uploadedEvidence.add({'path': downloadUrl, 'type': isVideo ? 'video' : 'image'});
        } catch (e) {
          debugPrint('Error uploading evidence file: $e');
        }
      }
    }

    final newTicket = {
      'title': title,
      'description': description,
      'priority': _determinePriority(category),
      'userName': 'User (App)',
      'category': category,
      'busId': busId ?? '',
      'evidence': uploadedEvidence,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending', 
    };

    await _firestore.collection('support_tickets').doc(documentId).set(newTicket);
  }

  /// Resolves an existing ticket.
  Future<void> resolveTicket(String id) async {
    await _firestore.collection('support_tickets').doc(id).update({'status': 'resolved'});
  }

  Future<void> moveToInProgress(String id) async {
     await _firestore.collection('support_tickets').doc(id).update({'status': 'in_progress'});
  }

  String _determinePriority(String category) {
    if (category == 'Reckless Driving') return 'HIGH';
    if (category == 'Bus Condition') return 'MEDIUM';
    if (category == 'Staff Behavior') return 'MEDIUM';
    return 'LOW';
  }

  void dispose() {
    _pendingSub?.cancel();
    _inProgressSub?.cancel();
    _resolvedSub?.cancel();
  }
}
