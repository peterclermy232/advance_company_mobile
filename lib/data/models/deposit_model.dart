// lib/data/models/deposit_model.dart

enum DepositStatus { pending, approved, rejected, processing }

class DepositModel {
  final int id;
  final int accountId;
  final double amount;
  final String method; // 'mpesa' | 'bank_transfer' | 'cash'
  final DepositStatus status;
  final String? mpesaTransactionId;
  final String? phoneNumber;
  final String? rejectionReason;
  final String? approvedBy;
  final DateTime createdAt;
  final DateTime? approvedAt;

  const DepositModel({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
    this.mpesaTransactionId,
    this.phoneNumber,
    this.rejectionReason,
    this.approvedBy,
    this.approvedAt,
  });

  bool get isPending   => status == DepositStatus.pending;
  bool get isApproved  => status == DepositStatus.approved;
  bool get isRejected  => status == DepositStatus.rejected;

  factory DepositModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? 'pending';
    return DepositModel(
      id:                   json['id'] as int,
      accountId:            json['account'] as int? ?? json['account_id'] as int? ?? 0,
      amount:               (json['amount'] as num?)?.toDouble() ?? 0.0,
      method:               json['method'] as String? ?? 'mpesa',
      status:               _parseStatus(rawStatus),
      mpesaTransactionId:   json['mpesa_transaction_id'] as String?,
      phoneNumber:          json['phone_number'] as String?,
      rejectionReason:      json['rejection_reason'] as String?,
      approvedBy:           json['approved_by'] as String?,
      createdAt:  DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      approvedAt: DateTime.tryParse(json['approved_at'] as String? ?? ''),
    );
  }

  static DepositStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'approved':   return DepositStatus.approved;
      case 'rejected':   return DepositStatus.rejected;
      case 'processing': return DepositStatus.processing;
      default:           return DepositStatus.pending;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'account': accountId,
    'amount': amount,
    'method': method,
    'status': status.name,
    'mpesa_transaction_id': mpesaTransactionId,
    'phone_number': phoneNumber,
  };
}