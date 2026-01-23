import 'dart:convert';

class Group {
  final String id;
  final String name;
  final String? description;
  final int? childrenCount;
  final String? teacher;
  final String? teacherId;
  final String? assistantId;
  final String? assistantTeacher;
  final bool? isActive;
  final int? maxStudents;
  final List<String>? ageGroup;
  final String? schedule;
  final String? room;
  final String? createdAt;
  final String? updatedAt;
  final List<Map<String, dynamic>>? children;
  final Map<String, dynamic>? educationalPlan;
  final List<String>? activities;

  Group({
    required this.id,
    required this.name,
    this.description,
    this.childrenCount,
    this.teacher,
    this.teacherId,
    this.assistantId,
    this.assistantTeacher,
    this.isActive,
    this.maxStudents,
    this.ageGroup,
    this.schedule,
    this.room,
    this.createdAt,
    this.updatedAt,
    this.children,
    this.educationalPlan,
    this.activities,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    dynamic rawId = json['_id'] ?? json['id'];
    String id;
    if (rawId is Map && rawId.containsKey('\$oid')) {
      id = rawId['\$oid'].toString();
    } else {
      id = (rawId ?? '').toString();
    }

    dynamic rawTeacher =
        json['teacherId'] ?? json['teacher'] ?? json['teacher_id'];
    String? teacherId;
    if (rawTeacher == null) {
      teacherId = null;
    } else if (rawTeacher is Map) {
      teacherId = (rawTeacher['_id'] ?? rawTeacher['id'])?.toString();
    } else {
      teacherId = rawTeacher.toString();
    }

    dynamic rawAssistant = json['assistantId'] ?? json['assistant_id'];
    String? assistantId;
    if (rawAssistant == null) {
      assistantId = null;
    } else if (rawAssistant is Map) {
      assistantId = (rawAssistant['_id'] ?? rawAssistant['id'])?.toString();
    } else {
      assistantId = rawAssistant.toString();
    }

    List<String>? ageGroupList;
    if (json['ageGroup'] != null) {
      if (json['ageGroup'] is List) {
        ageGroupList = List<String>.from(json['ageGroup']);
      } else if (json['ageGroup'] is String) {
        ageGroupList = [json['ageGroup'] as String];
      }
    }

    return Group(
      id: id,
      name: json['name'] ?? '',
      description: json['description'],
      childrenCount: json['childrenCount'],
      teacher: teacherId,
      teacherId: teacherId,
      assistantId: assistantId,
      assistantTeacher: json['assistantTeacher'],
      isActive: json['isActive'],
      maxStudents: json['maxStudents'],
      ageGroup: ageGroupList,
      schedule: json['schedule'],
      room: json['room'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      children: json['children'] != null
          ? List<Map<String, dynamic>>.from(json['children'])
          : null,
      educationalPlan: json['educationalPlan'] != null
          ? Map<String, dynamic>.from(json['educationalPlan'])
          : null,
      activities: json['activities'] != null
          ? List<String>.from(json['activities'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'childrenCount': childrenCount,
      'teacher': teacher,
      'assistantTeacher': assistantTeacher,
      'isActive': isActive,
      'maxStudents': maxStudents,
      'ageGroup': ageGroup,
      'schedule': schedule,
      'room': room,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'children': children,
      'educationalPlan': educationalPlan,
      'activities': activities,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory Group.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return Group.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse group data from JSON string: $e');
    }
  }

  Group copyWith({
    String? id,
    String? name,
    String? description,
    int? childrenCount,
    String? teacher,
    String? assistantTeacher,
    bool? isActive,
    int? maxStudents,
    List<String>? ageGroup,
    String? schedule,
    String? room,
    String? createdAt,
    String? updatedAt,
    List<Map<String, dynamic>>? children,
    Map<String, dynamic>? educationalPlan,
    List<String>? activities,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      childrenCount: childrenCount ?? this.childrenCount,
      teacher: teacher ?? this.teacher,
      assistantTeacher: assistantTeacher ?? this.assistantTeacher,
      isActive: isActive ?? this.isActive,
      maxStudents: maxStudents ?? this.maxStudents,
      ageGroup: ageGroup ?? this.ageGroup,
      schedule: schedule ?? this.schedule,
      room: room ?? this.room,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      children: children ?? this.children,
      educationalPlan: educationalPlan ?? this.educationalPlan,
      activities: activities ?? this.activities,
    );
  }
}
