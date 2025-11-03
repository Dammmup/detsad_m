import 'dart:convert';

class Group {
  final String id;
  final String name;
  final String? description;
  final int? childrenCount;
  final String? teacher;
  final bool? isActive;
  final int? maxStudents;
  final List<String>? ageGroup;
  final String? createdAt;
  final String? updatedAt;

  Group({
    required this.id,
    required this.name,
    this.description,
    this.childrenCount,
    this.teacher,
    this.isActive,
    this.maxStudents,
    this.ageGroup,
    this.createdAt,
    this.updatedAt,
  });

  // Convert from JSON
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      childrenCount: json['childrenCount'],
      teacher: json['teacher'],
      isActive: json['isActive'],
      maxStudents: json['maxStudents'],
      ageGroup: json['ageGroup'] != null 
          ? List<String>.from(json['ageGroup']) 
          : null,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
 }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'childrenCount': childrenCount,
      'teacher': teacher,
      'isActive': isActive,
      'maxStudents': maxStudents,
      'ageGroup': ageGroup,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // Convert from JSON string
  factory Group.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return Group.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse group data from JSON string: $e');
    }
  }

  // Copy with method for updates
  Group copyWith({
    String? id,
    String? name,
    String? description,
    int? childrenCount,
    String? teacher,
    bool? isActive,
    int? maxStudents,
    List<String>? ageGroup,
    String? createdAt,
    String? updatedAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      childrenCount: childrenCount ?? this.childrenCount,
      teacher: teacher ?? this.teacher,
      isActive: isActive ?? this.isActive,
      maxStudents: maxStudents ?? this.maxStudents,
      ageGroup: ageGroup ?? this.ageGroup,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}