import 'package:aldamiram/models/child_model.dart';
import 'package:aldamiram/models/user_model.dart';

class ChildPaymentModel {
  final String id;
  final String? childId;
  final String? userId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final num amount;
  final num total;
  final String status;
  final String? monthPeriod;
  final String? paymentType;
  final num? paidAmount;
  final Child? child;
  final User? user;
  final num? penalties;
  final num? latePenalties;
  final num? accruals;
  final num? deductions;
  final String? comments;

  ChildPaymentModel({
    required this.id,
    this.childId,
    this.userId,
    required this.periodStart,
    required this.periodEnd,
    required this.amount,
    required this.total,
    required this.status,
    this.monthPeriod,
    this.paymentType,
    this.paidAmount,
    this.child,
    this.user,
    this.penalties,
    this.latePenalties,
    this.accruals,
    this.deductions,
    this.comments,
  });

  factory ChildPaymentModel.fromJson(Map<String, dynamic> json) {
    return ChildPaymentModel(
      id: json['_id'] ?? json['id'] ?? '',
      childId: _extractId(json['childId']),
      userId: _extractId(json['userId']),
      periodStart: json['period'] != null && json['period']['start'] != null
          ? DateTime.parse(json['period']['start'])
          : DateTime.now(),
      periodEnd: json['period'] != null && json['period']['end'] != null
          ? DateTime.parse(json['period']['end'])
          : DateTime.now(),
      amount: json['amount'] ?? 0,
      total: json['total'] ?? 0,
      status: json['status'] ?? 'active',
      monthPeriod: json['monthPeriod'],
      paymentType: json['paymentType'],
      paidAmount: json['paidAmount'],
      child: json['childId'] is Map<String, dynamic>
          ? Child.fromJson(json['childId'])
          : null,
      user: json['userId'] is Map<String, dynamic>
          ? User.fromJson(json['userId'])
          : null,
      penalties: json['penalties'],
      latePenalties: json['latePenalties'],
      accruals: json['accruals'],
      deductions: json['deductions'],
      comments: json['comments'],
    );
  }

  static String? _extractId(dynamic val) {
    if (val == null) return null;
    if (val is String) return val;
    if (val is Map<String, dynamic>) {
      return val['_id'] ?? val['id'];
    }
    return null;
  }
}
