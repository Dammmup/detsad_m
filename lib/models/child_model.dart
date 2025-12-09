import 'dart:convert';

class Child {
  final String id;
  final String fullName;
  final String? iin;
  final String? birthday;
  final String? parentName;
  final String? parentPhone;
  final String? staffId;
  final dynamic groupId; // Can be Group object or string ID
  final bool? active;
  final String? gender;

  Child({
    required this.id,
    required this.fullName,
    this.iin,
    this.birthday,
    this.parentName,
    this.parentPhone,
    this.staffId,
    this.groupId,
    this.active,
    this.gender,
  });

  // Convert from JSON
  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      iin: json['iin'],
      birthday: json['birthday'],
      parentName: json['parentName'],
      parentPhone: json['parentPhone'],
      staffId: json['staffId'],
      groupId: json['groupId'],
      active: json['active'],
      gender: json['gender'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'iin': iin,
      'birthday': birthday,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'staffId': staffId,
      'groupId': groupId,
      'active': active,
      'gender': gender,
    };
  }

 // Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

 // Convert from JSON string
 factory Child.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return Child.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse child data from JSON string: $e');
    }
 }

  // Copy with method for updates
  Child copyWith({
    String? id,
    String? fullName,
    String? iin,
    String? birthday,
    String? parentName,
    String? parentPhone,
    String? staffId,
    dynamic groupId,
    bool? active,
    String? gender,
  }) {
    return Child(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      iin: iin ?? this.iin,
      birthday: birthday ?? this.birthday,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      staffId: staffId ?? this.staffId,
      groupId: groupId ?? this.groupId,
      active: active ?? this.active,
      gender: gender ?? this.gender,
    );
  }
}