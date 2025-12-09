import 'dart:convert';

class Task {
  final String id;
  final String title;
  final String? description;
  final String assignedTo;
  final String assignedBy;
  final String? assignedToSpecificUser;
  final DateTime? dueDate;
  final String priority;
  final String status;
  final String category;
 final List<String>? attachments;
  final String? notes;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? completedBy;
  final String? cancelledBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.assignedTo,
    required this.assignedBy,
    this.assignedToSpecificUser,
    this.dueDate,
    required this.priority,
    required this.status,
    required this.category,
    this.attachments,
    this.notes,
    this.completedAt,
    this.cancelledAt,
    this.completedBy,
    this.cancelledBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      assignedTo: json['assignedTo']?['_id'] ?? json['assignedTo'] ?? '',
      assignedBy: json['assignedBy']?['_id'] ?? json['assignedBy'] ?? '',
      assignedToSpecificUser: json['assignedToSpecificUser'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'pending',
      category: json['category'] ?? '',
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
      notes: json['notes'],
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']) : null,
      completedBy: json['completedBy'],
      cancelledBy: json['cancelledBy'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'assignedBy': assignedBy,
      'assignedToSpecificUser': assignedToSpecificUser,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
      'status': status,
      'category': category,
      'attachments': attachments,
      'notes': notes,
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'completedBy': completedBy,
      'cancelledBy': cancelledBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory Task.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return Task.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse task data from JSON string: $e');
    }
  }
}