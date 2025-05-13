class TodoModel {
  String id; // This is the user-defined ID for the task
  String docId; // Firestore document ID (optional)
  String task;
  String description;
  DateTime dueDate;
  String priority;
  bool isCompleted;
  final String ownerId; // New field
  final bool isPublic;  // New field

  TodoModel({
    required this.id,
    required this.task,
    required this.description,
    required this.dueDate,
    required this.priority,
    this.isCompleted = false,
    this.docId = '', // Initialize docId as an empty string
    required this.ownerId,
    required this.isPublic,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': task,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
      'isCompleted': isCompleted,
      'ownerId': ownerId,
      'isPublic': isPublic,
    };
  }

  static TodoModel fromMap(Map<String, dynamic> map, String docId) {
    return TodoModel(
      id: map['id'],
      task: map['task'],
      description: map['description'],
      dueDate: DateTime.parse(map['dueDate']),
      priority: map['priority'],
      isCompleted: map['isCompleted'],
      docId: docId, // Assign the Firestore document ID
      ownerId: map['ownerId'] ?? '',
      isPublic: map['isPublic'] ?? false,
    );
  }
}
