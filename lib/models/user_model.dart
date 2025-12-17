import 'dart:convert';

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String phone;
  final String role;
  final String? avatar;
  final String? position;
  final String? department;
  final bool active;
  final DateTime? lastLoginAt;
  final String? email;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.phone,
    required this.role,
    this.avatar,
    this.position,
    this.department,
    this.active = true,
    this.lastLoginAt,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final String id =
        (json['_id'] ?? json['id'] ?? json['userId'] ?? '').toString();
    String firstName = '';
    String lastName = '';
    String? middleName;

    if (json.containsKey('fullName') && json['fullName'] != null) {
      List<String> nameParts = (json['fullName'] as String).split(' ');
      if (nameParts.isNotEmpty) {
        lastName = nameParts[0];
      }
      if (nameParts.length >= 2) {
        firstName = nameParts[1];
      }
      if (nameParts.length >= 3) {
        middleName = nameParts.sublist(2).join(' ');
      }
    } else {
      firstName:
      (json['firstName'] ?? '').toString();
      lastName:
      (json['lastName'] ?? '').toString();
      middleName:
      json['middleName']?.toString();
    }

    return User(
      id: id,
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      phone: (json['phone'] ?? '').toString(),
      role: (json['role'] ?? 'staff').toString(),
      avatar: json['avatar'] as String?,
      position: json['position'] as String?,
      department: json['department'] as String?,
      active: json['active'] as bool? ?? true,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'fullName': _getFullName(),
      'phone': phone,
      'role': role,
      'avatar': avatar,
      'position': position,
      'department': department,
      'active': active,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'email': email,
    };
  }

  factory User.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return User.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse user data from JSON string: $e');
    }
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? middleName,
    String? phone,
    String? role,
    String? avatar,
    String? position,
    String? department,
    bool? active,
    DateTime? lastLoginAt,
    String? email,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      position: position ?? this.position,
      department: department ?? this.department,
      active: active ?? this.active,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      email: email ?? this.email,
    );
  }

  String _getFullName() {
    List<String> parts = [lastName, firstName];
    if (middleName != null && middleName!.isNotEmpty) {
      parts.add(middleName!);
    }
    return parts.join(' ').trim();
  }
}
