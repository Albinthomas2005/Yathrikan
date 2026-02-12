import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bus_model.dart';

class BusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'buses';

  // Get all buses as a stream (real-time updates)
  Stream<List<Bus>> getBusesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Bus.fromJson(doc.data());
      }).toList();
    });
  }

  // Get all buses (one-time fetch)
  Future<List<Bus>> getBuses() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Bus.fromJson(doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch buses: ${e.toString()}');
    }
  }

  // Get a single bus by ID
  Future<Bus?> getBusById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();

      if (doc.exists && doc.data() != null) {
        return Bus.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch bus: ${e.toString()}');
    }
  }

  // Add a new bus
  Future<void> addBus(Bus bus) async {
    try {
      await _firestore.collection(_collection).doc(bus.id).set(bus.toJson());
    } catch (e) {
      throw Exception('Failed to add bus: ${e.toString()}');
    }
  }

  // Update an existing bus
  Future<void> updateBus(Bus bus) async {
    try {
      final updatedBus = bus.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection(_collection)
          .doc(bus.id)
          .update(updatedBus.toJson());
    } catch (e) {
      throw Exception('Failed to update bus: ${e.toString()}');
    }
  }

  // Delete a bus
  Future<void> deleteBus(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete bus: ${e.toString()}');
    }
  }

  // Toggle bus active status
  Future<void> toggleBusStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update bus status: ${e.toString()}');
    }
  }

  // Search buses by bus number or route name
  Future<List<Bus>> searchBuses(String query) async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      return snapshot.docs
          .map((doc) => Bus.fromJson(doc.data()))
          .where((bus) =>
              bus.busNumber.toLowerCase().contains(query.toLowerCase()) ||
              bus.routeName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search buses: ${e.toString()}');
    }
  }
}
