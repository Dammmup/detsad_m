class MedicalRecord {
  final String id;
  final String childId;
  final DateTime date;
  final double temperature;
  final bool hasCough;
  final bool hasRunnyNose;
  final bool hasSoreThroat;
  final String? notes;
  final String? staffId;
  final String? status; // 'healthy', 'sick', 'observation'

  MedicalRecord({
    required this.id,
    required this.childId,
    required this.date,
    required this.temperature,
    this.hasCough = false,
    this.hasRunnyNose = false,
    this.hasSoreThroat = false,
    this.notes,
    this.staffId,
    this.status,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      childId: json['childId'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      temperature: (json['temperature'] ?? 36.6).toDouble(),
      hasCough: json['hasCough'] ?? false,
      hasRunnyNose: json['hasRunnyNose'] ?? false,
      hasSoreThroat: json['hasSoreThroat'] ?? false,
      notes: json['notes'],
      staffId: json['staffId'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'date': date.toIso8601String(),
      'temperature': temperature,
      'hasCough': hasCough,
      'hasRunnyNose': hasRunnyNose,
      'hasSoreThroat': hasSoreThroat,
      'notes': notes,
      'staffId': staffId,
      'status': status,
    };
  }
}
