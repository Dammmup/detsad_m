import 'dart:convert';

class Child {
  final String id;
  final String fullName;
  final String? iin;
  final String? birthday;
  final String? address;
  final String? parentName;
  final String? parentPhone;
  final String? staffId;
  final dynamic groupId; // Can be Group object or string ID
  final bool? active;
  final String? gender;
  final String? clinic;
  final String? bloodGroup;
  final String? rhesus;
  final String? disability;
  final String? dispensary;
  final String? diagnosis;
  final String? allergy;
  final String? infections;
  final String? hospitalizations;
  final String? incapacity;
  final String? checkups;
  final String? notes;
  final String? photo;
  final String? createdAt;
  final String? updatedAt;

  Child({
    required this.id,
    required this.fullName,
    this.iin,
    this.birthday,
    this.address,
    this.parentName,
    this.parentPhone,
    this.staffId,
    this.groupId,
    this.active,
    this.gender,
    this.clinic,
    this.bloodGroup,
    this.rhesus,
    this.disability,
    this.dispensary,
    this.diagnosis,
    this.allergy,
    this.infections,
    this.hospitalizations,
    this.incapacity,
    this.checkups,
    this.notes,
    this.photo,
    this.createdAt,
    this.updatedAt,
  });

  // Convert from JSON
  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      iin: json['iin'],
      birthday: json['birthday'],
      address: json['address'],
      parentName: json['parentName'],
      parentPhone: json['parentPhone'],
      staffId: json['staffId'],
      groupId: json['groupId'],
      active: json['active'],
      gender: json['gender'],
      clinic: json['clinic'],
      bloodGroup: json['bloodGroup'],
      rhesus: json['rhesus'],
      disability: json['disability'],
      dispensary: json['dispensary'],
      diagnosis: json['diagnosis'],
      allergy: json['allergy'],
      infections: json['infections'],
      hospitalizations: json['hospitalizations'],
      incapacity: json['incapacity'],
      checkups: json['checkups'],
      notes: json['notes'],
      photo: json['photo'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'iin': iin,
      'birthday': birthday,
      'address': address,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'staffId': staffId,
      'groupId': groupId,
      'active': active,
      'gender': gender,
      'clinic': clinic,
      'bloodGroup': bloodGroup,
      'rhesus': rhesus,
      'disability': disability,
      'dispensary': dispensary,
      'diagnosis': diagnosis,
      'allergy': allergy,
      'infections': infections,
      'hospitalizations': hospitalizations,
      'incapacity': incapacity,
      'checkups': checkups,
      'notes': notes,
      'photo': photo,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
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
    String? address,
    String? parentName,
    String? parentPhone,
    String? staffId,
    dynamic groupId,
    bool? active,
    String? gender,
    String? clinic,
    String? bloodGroup,
    String? rhesus,
    String? disability,
    String? dispensary,
    String? diagnosis,
    String? allergy,
    String? infections,
    String? hospitalizations,
    String? incapacity,
    String? checkups,
    String? notes,
    String? photo,
    String? createdAt,
    String? updatedAt,
  }) {
    return Child(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      iin: iin ?? this.iin,
      birthday: birthday ?? this.birthday,
      address: address ?? this.address,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      staffId: staffId ?? this.staffId,
      groupId: groupId ?? this.groupId,
      active: active ?? this.active,
      gender: gender ?? this.gender,
      clinic: clinic ?? this.clinic,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      rhesus: rhesus ?? this.rhesus,
      disability: disability ?? this.disability,
      dispensary: dispensary ?? this.dispensary,
      diagnosis: diagnosis ?? this.diagnosis,
      allergy: allergy ?? this.allergy,
      infections: infections ?? this.infections,
      hospitalizations: hospitalizations ?? this.hospitalizations,
      incapacity: incapacity ?? this.incapacity,
      checkups: checkups ?? this.checkups,
      notes: notes ?? this.notes,
      photo: photo ?? this.photo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}