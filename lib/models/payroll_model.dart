import 'fine_model.dart';
import 'user_model.dart';

class Payroll {
  final String? id;
  final User? staff; // Can be minimal user info
  final String period;
  final double baseSalary;
  final String baseSalaryType;
  final double total;
  final String status;
  final double accruals;
  final double penalties;
  final double latePenalties;
  final double absencePenalties;
  final double userFines;
  final double bonuses;
  final double advance;
  final List<Fine> fines;
  final double workedDays;
  final double workedShifts;
  final List<ShiftDetail> shiftDetails;

  Payroll({
    this.id,
    this.staff,
    required this.period,
    required this.baseSalary,
    required this.baseSalaryType,
    required this.total,
    required this.status,
    required this.accruals,
    required this.penalties,
    required this.latePenalties,
    required this.absencePenalties,
    required this.userFines,
    required this.bonuses,
    required this.advance,
    required this.fines,
    required this.workedDays,
    required this.workedShifts,
    this.shiftDetails = const [],
  });
// ... 

  factory Payroll.fromJson(Map<String, dynamic> json) {
    return Payroll(
      id: json['_id'],
      staff: json['staffId'] != null && json['staffId'] is Map 
          ? User.fromJson(json['staffId']) 
          : null,
      period: json['period'] ?? '',
      baseSalary: (json['baseSalary'] as num?)?.toDouble() ?? 0.0,
      baseSalaryType: json['baseSalaryType'] ?? 'month',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'draft',
      accruals: (json['accruals'] as num?)?.toDouble() ?? 0.0,
      penalties: (json['penalties'] as num?)?.toDouble() ?? 0.0,
      latePenalties: (json['latePenalties'] as num?)?.toDouble() ?? 0.0,
      absencePenalties: (json['absencePenalties'] as num?)?.toDouble() ?? 0.0,
      userFines: (json['userFines'] as num?)?.toDouble() ?? 0.0,
      bonuses: (json['bonuses'] as num?)?.toDouble() ?? 0.0,
      advance: (json['advance'] as num?)?.toDouble() ?? 0.0,
      fines: (json['fines'] as List<dynamic>?)
          ?.map((e) => Fine.fromJson(e))
          .toList() ?? [],
      workedDays: (json['workedDays'] as num?)?.toDouble() ?? 0.0,
      workedShifts: (json['workedShifts'] as num?)?.toDouble() ?? 0.0,
      shiftDetails: (json['shiftDetails'] as List<dynamic>?)
          ?.map((e) => ShiftDetail.fromJson(e))
          .toList() ?? [],
    );
  }
}

class ShiftDetail {
  final DateTime date;
  final double earnings;
  final double fines;
  final double net;
  final String reason;

  ShiftDetail({
    required this.date,
    required this.earnings,
    required this.fines,
    required this.net,
    required this.reason
  });

  factory ShiftDetail.fromJson(Map<String, dynamic> json) {
    return ShiftDetail(
      date: DateTime.parse(json['date']),
      earnings: (json['earnings'] as num?)?.toDouble() ?? 0.0,
      fines: (json['fines'] as num?)?.toDouble() ?? 0.0,
      net: (json['net'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] ?? '',
    );
  }
}
