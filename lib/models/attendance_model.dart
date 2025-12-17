import 'dart:convert';

class Attendance {
  final String id;
  final String userId;
  final String? childId;
  final String groupId;
  final String date;
  final String checkIn;
  final String? checkOut;
  final String status;
  final String? notes;
  final String? markedBy;
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
    this.markedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    String? parsedChildId;
    if (json['childId'] != null) {
      if (json['childId'] is String) {
        parsedChildId = json['childId'] as String;
      } else if (json['childId'] is Map && json['childId']['_id'] != null) {
        parsedChildId = json['childId']['_id'].toString();
      } else if (json['childId'] is Map && json['childId']['id'] != null) {
        parsedChildId = json['childId']['id'].toString();
      }
    }

    String? parsedUserId;
    if (json['userId'] != null) {
      if (json['userId'] is String) {
        parsedUserId = json['userId'] as String;
      } else if (json['userId'] is Map && json['userId']['_id'] != null) {
        parsedUserId = json['userId']['_id'].toString();
      }
    }

    String parsedDate = '';
    if (json['date'] != null) {
      if (json['date'] is String) {
        parsedDate = json['date'].split('T')[0];
      } else {
        parsedDate = json['date'].toString();
      }
    }

    return Attendance(
      id: json['_id'] ?? json['id'] ?? '',
      userId: parsedUserId ?? parsedChildId ?? '',
      childId: parsedChildId ?? parsedUserId,
      groupId: json['groupId']?.toString() ??
          (json['groupId'] is Map
              ? (json['groupId']['_id'] ?? json['groupId']['id'])?.toString()
              : '') ??
          '',
      date: parsedDate,
      checkIn:
          json['checkIn']?.toString() ?? json['actualStart']?.toString() ?? '',
      checkOut: json['checkOut']?.toString() ?? json['actualEnd']?.toString(),
      status: json['status'] ?? 'absent',
      notes: json['notes'],
      markedBy: json['markedBy']?.toString() ??
          (json['markedBy'] is Map
              ? (json['markedBy']['_id'] ?? json['markedBy']['id'])?.toString()
              : null),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      '_id': id,
      'groupId': groupId,
      'date': date,
      'status': status,
    };

    if (childId != null && childId!.isNotEmpty) {
      json['childId'] = childId;
    } else if (userId.isNotEmpty) {
      json['childId'] = userId;
    }

    if (checkIn.isNotEmpty) json['checkIn'] = checkIn;
    if (checkOut != null && checkOut!.isNotEmpty) json['checkOut'] = checkOut;
    if (notes != null && notes!.isNotEmpty) json['notes'] = notes;
    if (markedBy != null && markedBy!.isNotEmpty) json['markedBy'] = markedBy;
    if (createdAt != null && createdAt!.isNotEmpty)
      json['createdAt'] = createdAt;
    if (updatedAt != null && updatedAt!.isNotEmpty)
      json['updatedAt'] = updatedAt;

    return json;
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory Attendance.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return Attendance.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse attendance data from JSON string: $e');
    }
  }

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
    String? markedBy,
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
      markedBy: markedBy ?? this.markedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
