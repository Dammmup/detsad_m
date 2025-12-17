import 'dart:convert';

class Child {
  final String id;
  final String fullName;
  final String? iin;
  final String? birthday;
  final String? parentName;
  final String? parentPhone;
  final String? staffId;
  final String? groupId;
  final String? groupName;
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

  factory Child.fromJson(Map<String, dynamic> json) {
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

    dynamic rawGroup = json['groupId'] ?? json['group'] ?? json['group_id'];
    String? groupIdString;
    String? groupNameString;
    if (rawGroup == null) {
      groupIdString = null;
      groupNameString = null;
    } else if (rawGroup is Map) {
      groupIdString =
          (rawGroup['oid'] ?? rawGroup['_id'] ?? rawGroup['id'])?.toString();
      groupNameString = rawGroup['name']?.toString();
    } else {
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

    if (id.isNotEmpty) {
      json['_id'] = id;
    }

    if (groupId != null) {
      if (groupId is Map) {
        final groupMap = groupId as Map;
        json['groupId'] = groupMap['_id'] ?? groupMap['id'] ?? groupId;
      } else {
        json['groupId'] = groupId;
      }
    }

    return json;
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory Child.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return Child.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse child data from JSON string: $e');
    }
  }

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
