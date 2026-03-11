
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
  // Extended fields used in UI
  final String? userName;
  final String? notes;
  final String? mpesaReceiptNumber;

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
    this.userName,
    this.notes,
    this.mpesaReceiptNumber,
  });

  bool get isPending => status == DepositStatus.pending || status == DepositStatus.processing;
  bool get isApproved => status == DepositStatus.approved;
  bool get isRejected => status == DepositStatus.rejected;

  /// Human-readable status label
  String get statusLabel {
    switch (status) {
      case DepositStatus.approved:
        return 'Approved';
      case DepositStatus.rejected:
        return 'Rejected';
      case DepositStatus.processing:
        return 'Processing';
      case DepositStatus.pending:
        return 'Pending';
    }
  }

  /// Human-readable payment method label
  String get paymentMethodLabel {
    switch (method.toLowerCase()) {
      case 'mpesa':
      case 'm_pesa':
        return 'M-Pesa';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'cash':
        return 'Cash';
      default:
        return method.toUpperCase();
    }
  }

  /// Transaction reference for display
  String get transactionReference =>
      mpesaTransactionId ?? mpesaReceiptNumber ?? 'TXN-${id.toString().padLeft(8, '0')}';

  /// M-Pesa phone number alias
  String? get mpesaPhone => phoneNumber;

  factory DepositModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? 'pending';
    return DepositModel(
      id: json['id'] as int,
      accountId: json['account'] as int? ?? json['account_id'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      method: json['method'] as String? ?? 'mpesa',
      status: _parseStatus(rawStatus),
      mpesaTransactionId: json['mpesa_transaction_id'] as String?,
      phoneNumber: json['phone_number'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      approvedBy: json['approved_by'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'] as String)
          : null,
      userName: json['user_name'] as String? ??
          json['member_name'] as String?,
      notes: json['notes'] as String?,
      mpesaReceiptNumber: json['mpesa_receipt_number'] as String?,
    );
  }

  static DepositStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
      case 'completed':
        return DepositStatus.approved;
      case 'rejected':
      case 'failed':
        return DepositStatus.rejected;
      case 'processing':
        return DepositStatus.processing;
      default:
        return DepositStatus.pending;
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