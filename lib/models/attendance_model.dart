import 'dart:convert';

class Attendance {
  final String id;
  final String userId;
  final String date;
  final String checkIn;
  final String? checkOut;
  final String status; // 'present' | 'absent' | 'late' | 'early_departure'
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  Attendance({
    required this.id,
    required this.userId,
    required this.date,
    required this.checkIn,
    this.checkOut,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  // Convert from JSON
  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      date: json['date'] ?? '',
      checkIn: json['checkIn'] ?? '',
      checkOut: json['checkOut'],
      status: json['status'] ?? 'absent',
      notes: json['notes'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

 // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'date': date,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'status': status,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

 // Convert from JSON string
  factory Attendance.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return Attendance.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse attendance data from JSON string: $e');
    }
  }

  // Copy with method for updates
  Attendance copyWith({
    String? id,
    String? userId,
    String? date,
    String? checkIn,
    String? checkOut,
    String? status,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return Attendance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}