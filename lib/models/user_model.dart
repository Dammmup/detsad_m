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
  final bool isActive;
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
    this.isActive = true,
    this.lastLoginAt,
    this.email,
  });

  // Convert from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    // Handle fullName field from server response by splitting it
    String firstName = '';
    String lastName = '';
    String? middleName;
    
    if (json.containsKey('fullName') && json['fullName'] != null) {
      // Split fullName into firstName, lastName, and middleName
      List<String> nameParts = (json['fullName'] as String).split(' ');
      if (nameParts.length >= 1) {
        lastName = nameParts[0]; // In many systems, the first part is the last name
      }
      if (nameParts.length >= 2) {
        firstName = nameParts[1];
      }
      if (nameParts.length >= 3) {
        middleName = nameParts.sublist(2).join(' ');
      }
    } else {
      // Use the original fields if fullName is not present
      firstName = json['firstName'] as String ?? '';
      lastName = json['lastName'] as String ?? '';
      middleName = json['middleName'] as String?;
    }
    
    return User(
      id: json['id'] as String,
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      phone: json['phone'] as String,
      role: json['role'] as String,
      avatar: json['avatar'] as String?,
      position: json['position'] as String?,
      department: json['department'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.parse(json['lastLoginAt'] as String) : null,
      email: json['email'] as String?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'fullName': _getFullName(), // Include fullName for server compatibility
      'phone': phone,
      'role': role,
      'avatar': avatar,
      'position': position,
      'department': department,
      'isActive': isActive,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'email': email,
    };
  }

  // Convert from JSON string
  factory User.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return User.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse user data from JSON string: $e');
    }
  }

  // Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // Copy with method for updates
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
    bool? isActive,
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
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      email: email ?? this.email,
    );
  }
  
  // Helper method to generate full name from first, last, and middle names
  String _getFullName() {
    List<String> parts = [lastName, firstName];
    if (middleName != null && middleName!.isNotEmpty) {
      parts.add(middleName!);
    }
    return parts.join(' ').trim();
  }
}