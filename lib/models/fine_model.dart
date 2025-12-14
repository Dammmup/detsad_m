
class Fine {
  final String? id;
  final double amount;
  final String reason;
  final String type;
  final DateTime date;
  final String? notes;

  Fine({
    this.id,
    required this.amount,
    required this.reason,
    required this.type,
    required this.date,
    this.notes,
  });

  factory Fine.fromJson(Map<String, dynamic> json) {
    return Fine(
      id: json['_id'],
      amount: (json['amount'] as num).toDouble(),
      reason: json['reason'] ?? '',
      type: json['type'] ?? 'other',
      date: DateTime.parse(json['date']),
      notes: json['notes'],
    );
  }
}
