import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../models/todo_model.dart';

class TodoService {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<TodoModel>> getTodos() {
    String userId = _auth.currentUser!.uid;
    return _firebaseFirestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TodoModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addTodo(TodoModel todo) async {
    String userId = _auth.currentUser!.uid;
    await _firebaseFirestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .add(todo.toMap());
  }

  // Add a public event (for admins)
  Future<void> addPublicEvent(TodoModel todo) async {
    await _firebaseFirestore.collection('events').add(todo.toMap());
  }

  // Add a private event (for individual users)
  Future<void> addPrivateEvent(TodoModel todo) async {
    String userId = _auth.currentUser!.uid;
    await _firebaseFirestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .add(todo.toMap());
  }

  // Fetch both public and private events for the current user
  Stream<List<TodoModel>> getEvents() {
    String userId = _auth.currentUser!.uid;

    // Stream for public events
    Stream<List<TodoModel>> publicEvents = _firebaseFirestore
        .collection('events')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TodoModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });

    // Stream for private events
    Stream<List<TodoModel>> privateEvents = _firebaseFirestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TodoModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });

    // Combine the streams
    return Rx.combineLatest2(
      publicEvents,
      privateEvents,
          (List<TodoModel> public, List<TodoModel> private) => [...public, ...private],
    );
  }

  Future<void> editEvent(String eventId, TodoModel updatedEvent) async {
    await _firebaseFirestore.collection('events').doc(eventId).update(updatedEvent.toMap());
  }

  Future<void> deleteEvent(String eventId) async {
    await _firebaseFirestore.collection('events').doc(eventId).delete();
  }

  Future<void> toggleTaskCompletion(String docId, bool isCompleted) async {
    String userId = _auth.currentUser!.uid;
    await _firebaseFirestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(docId)
        .update({'isCompleted': isCompleted});
  }

  Future<void> deleteTodo(String docId) async {
    String userId = _auth.currentUser!.uid;
    await _firebaseFirestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(docId)
        .delete();
  }

  Future<void> editPrivateEvent(String eventId, TodoModel updatedEvent) async {
    String userId = _auth.currentUser!.uid;
    await _firebaseFirestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .update(updatedEvent.toMap());
  }

  Future<void> deletePrivateEvent(String eventId) async {
    String userId = _auth.currentUser!.uid;
    await _firebaseFirestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .delete();
  }
}