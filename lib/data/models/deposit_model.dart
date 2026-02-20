import 'package:equatable/equatable.dart';

class DepositModel extends Equatable {
  // Backend sends "uuid" as the primary key (string), not an integer "id".
  final String id;

  final String userName;
  final String amount;

  /// Raw value from backend — may be uppercase e.g. "MPESA", "BANK".
  /// Use [paymentMethodLabel] for display.
  final String paymentMethod;

  /// Lowercase status from backend: 'pending' | 'completed' | 'failed'
  final String status;

  final String transactionReference;
  final String? mpesaPhone;
  final String? notes;
  final String? mpesaCheckoutRequestId;
  final String? mpesaMerchantRequestId;
  final String? mpesaReceiptNumber;
  final DateTime? mpesaTransactionDate;
  final String? mpesaResponseCode;
  final String? mpesaResponseDescription;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Backend sends user/approvedBy/rejectedBy as UUID strings, not integers.
  final String user;
  final String? approvedBy;
  final String? rejectedBy;

  const DepositModel({
    required this.id,
    required this.userName,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.transactionReference,
    this.mpesaPhone,
    this.notes,
    this.mpesaCheckoutRequestId,
    this.mpesaMerchantRequestId,
    this.mpesaReceiptNumber,
    this.mpesaTransactionDate,
    this.mpesaResponseCode,
    this.mpesaResponseDescription,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    this.approvedBy,
    this.rejectedBy,
  });

  factory DepositModel.fromJson(Map<String, dynamic> json) {
    return DepositModel(
      // Backend uses "uuid" as primary key — fall back to "id" if ever present.
      id: (json['uuid'] ?? json['id'] ?? '').toString(),

      userName: (json['user_name'] ?? '').toString(),
      amount: (json['amount'] ?? '0').toString(),
      paymentMethod: (json['payment_method'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      transactionReference:
      (json['transaction_reference'] ?? '').toString(),
      mpesaPhone: json['mpesa_phone']?.toString(),
      notes: json['notes']?.toString(),
      mpesaCheckoutRequestId:
      json['mpesa_checkout_request_id']?.toString(),
      mpesaMerchantRequestId:
      json['mpesa_merchant_request_id']?.toString(),
      mpesaReceiptNumber: json['mpesa_receipt_number']?.toString(),
      mpesaTransactionDate: json['mpesa_transaction_date'] != null
          ? DateTime.tryParse(json['mpesa_transaction_date'].toString())
          : null,
      mpesaResponseCode: json['mpesa_response_code']?.toString(),
      mpesaResponseDescription:
      json['mpesa_response_description']?.toString(),
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'].toString())
          : null,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.tryParse(json['rejected_at'].toString())
          : null,
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: DateTime.parse(
          (json['created_at'] ?? DateTime.now().toIso8601String())
              .toString()),
      updatedAt: DateTime.parse(
          (json['updated_at'] ?? DateTime.now().toIso8601String())
              .toString()),
      user: (json['user'] ?? '').toString(),
      approvedBy: json['approved_by']?.toString(),
      rejectedBy: json['rejected_by']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'uuid': id,
    'user_name': userName,
    'amount': amount,
    'payment_method': paymentMethod,
    'status': status,
    'transaction_reference': transactionReference,
    'mpesa_phone': mpesaPhone,
    'notes': notes,
    'mpesa_checkout_request_id': mpesaCheckoutRequestId,
    'mpesa_merchant_request_id': mpesaMerchantRequestId,
    'mpesa_receipt_number': mpesaReceiptNumber,
    'mpesa_transaction_date': mpesaTransactionDate?.toIso8601String(),
    'mpesa_response_code': mpesaResponseCode,
    'mpesa_response_description': mpesaResponseDescription,
    'approved_at': approvedAt?.toIso8601String(),
    'rejected_at': rejectedAt?.toIso8601String(),
    'rejection_reason': rejectionReason,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'user': user,
    'approved_by': approvedBy,
    'rejected_by': rejectedBy,
  };

  // ─── Display helpers ────────────────────────────────────────────────────────

  /// Lowercase status for safe comparisons.
  String get statusNormalized => status.toLowerCase();

  /// True when deposit is awaiting admin action.
  bool get isPending =>
      statusNormalized == 'pending' || statusNormalized == 'processing';

  /// True when approved / completed.
  bool get isApproved => statusNormalized == 'completed';

  /// True when rejected / failed.
  bool get isRejected =>
      statusNormalized == 'failed' || statusNormalized == 'rejected';

  /// Human-readable status matching the web app labels.
  String get statusLabel {
    switch (statusNormalized) {
      case 'completed':
        return 'Approved';
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'failed':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.isEmpty
            ? 'Unknown'
            : status[0].toUpperCase() + status.substring(1);
    }
  }

  /// Human-readable payment method.
  /// Handles uppercase ("MPESA") and lowercase ("mpesa") from backend.
  String get paymentMethodLabel {
    switch (paymentMethod.toUpperCase()) {
      case 'MPESA':
        return 'M-Pesa';
      case 'BANK':
        return 'Bank Transfer';
      case 'MANSA_X':
        return 'Mansa-X';
      default:
        return paymentMethod
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isEmpty
            ? w
            : w[0].toUpperCase() + w.substring(1).toLowerCase())
            .join(' ');
    }
  }

  @override
  List<Object?> get props => [
    id,
    userName,
    amount,
    paymentMethod,
    status,
    transactionReference,
    mpesaPhone,
    notes,
    createdAt,
    updatedAt,
    user,
  ];
}