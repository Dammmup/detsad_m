import 'dart:convert';

class Attendance {
  final String id;
  final String userId; // For backward compatibility
  final String? childId; // Primary field for child attendance (matches backend)
  final String groupId; // Added groupId
  final String date;
  final String checkIn;
  final String? checkOut;
  final String status; // 'present' | 'absent' | 'late' | 'early_departure'
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  Attendance({
    required this.id,
    this.userId = '',
    this.childId,
    required this.groupId,
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
      userId: json['userId'] ?? json['childId'] ?? '',
      childId: json['childId'] ?? json['userId'],
      groupId: json['groupId']?.toString() ?? '', // Added groupId
      date: json['date']?.toString() ?? '',
      checkIn: json['checkIn']?.toString() ?? json['actualStart']?.toString() ?? '',
      checkOut: json['checkOut']?.toString() ?? json['actualEnd']?.toString(),
      status: json['status'] ?? 'absent',
      notes: json['notes'],
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

 // Convert to JSON
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      '_id': id,
      'groupId': groupId,
      'date': date,
      'status': status,
    };
    
    // Use childId if available, otherwise userId (for backward compatibility)
    if (childId != null && childId!.isNotEmpty) {
      json['childId'] = childId;
    } else if (userId.isNotEmpty) {
      json['childId'] = userId;
    }
    
    // Add optional fields
    if (checkIn.isNotEmpty) json['checkIn'] = checkIn;
    if (checkOut != null && checkOut!.isNotEmpty) json['checkOut'] = checkOut;
    if (notes != null && notes!.isNotEmpty) json['notes'] = notes;
    if (createdAt != null && createdAt!.isNotEmpty) json['createdAt'] = createdAt;
    if (updatedAt != null && updatedAt!.isNotEmpty) json['updatedAt'] = updatedAt;
    
    return json;
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
    String? childId,
    String? groupId,
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
      childId: childId ?? this.childId,
      groupId: groupId ?? this.groupId,
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