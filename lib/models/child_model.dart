import 'dart:convert';

class Child {
  final String id;
  final String fullName;
  final String? iin;
  final String? birthday;
  final String? parentName;
  final String? parentPhone;
  final String? staffId;
  final String? groupId; // Can be Group object or string ID
  final String? groupName; // Group name from populated groupId
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
    this.groupName,
    this.active,
    this.gender,
  });

// И factory:
  factory Child.fromJson(Map<String, dynamic> json) {
    // birthday processing (как у тебя)
    String? birthdayString;
    if (json['birthday'] != null) {
      if (json['birthday'] is String) {
        birthdayString = json['birthday'];
      } else {
        try {
          birthdayString = DateTime.parse(json['birthday'].toString())
              .toIso8601String()
              .split('T')[0];
        } catch (_) {
          birthdayString = null;
        }
      }
    }

    // Normalize groupId and extract groupName from populated object
    dynamic rawGroup = json['groupId'] ?? json['group'] ?? json['group_id'];
    String? groupIdString;
    String? groupNameString;
    if (rawGroup == null) {
      groupIdString = null;
      groupNameString = null;
    } else if (rawGroup is Map) {
      // Populated group object from backend
      groupIdString = (rawGroup['oid'] ?? rawGroup['_id'] ?? rawGroup['id'])?.toString();
      groupNameString = rawGroup['name']?.toString();
    } else {
      // Just a string ID
      groupIdString = rawGroup.toString();
      groupNameString = null;
    }

    return Child(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      fullName: json['fullName'] ?? '',
      iin: json['iin'],
      birthday: birthdayString,
      parentName: json['parentName'],
      parentPhone: json['parentPhone'],
      staffId: json['staffId'],
      groupId: groupIdString,
      groupName: groupNameString,
      active: json['active'],
      gender: json['gender'],
    );
  }


  // Convert to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'fullName': fullName,
      'iin': iin,
      'birthday': birthday,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'staffId': staffId,
      'active': active,
      'gender': gender,
    };

    // Добавляем _id только если он не пустой (для обновления существующего ребенка)
    if (id.isNotEmpty) {
      json['_id'] = id;
    }

    // Обрабатываем groupId - если это объект, извлекаем ID, иначе используем как есть
    if (groupId != null) {
      if (groupId is Map) {
        // Если  groupId - это объект группы, извлекаем ID
        final groupMap = groupId as Map;
        json['groupId'] = groupMap['_id'] ?? groupMap['id'] ?? groupId;
      } else {
        // Если groupId - это строка, используем напрямую
        json['groupId'] = groupId;
      }
    }

    return json;
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
    String? groupName,
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
      groupName: groupName ?? this.groupName,
      active: active ?? this.active,
      gender: gender ?? this.gender,
    );
  }
}
