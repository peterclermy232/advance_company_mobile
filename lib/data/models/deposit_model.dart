// ============================================
// lib/data/models/deposit_model.dart
// ============================================
class DepositModel extends Equatable {
  final int id;
  final String userName;
  final String amount;
  final String paymentMethod;
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
  final int user;
  final int? approvedBy;
  final int? rejectedBy;

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
      id: json['id'] as int,
      userName: json['user_name'] as String,
      amount: json['amount'] as String,
      paymentMethod: json['payment_method'] as String,
      status: json['status'] as String,
      transactionReference: json['transaction_reference'] as String,
      mpesaPhone: json['mpesa_phone'] as String?,
      notes: json['notes'] as String?,
      mpesaCheckoutRequestId: json['mpesa_checkout_request_id'] as String?,
      mpesaMerchantRequestId: json['mpesa_merchant_request_id'] as String?,
      mpesaReceiptNumber: json['mpesa_receipt_number'] as String?,
      mpesaTransactionDate: json['mpesa_transaction_date'] != null
          ? DateTime.parse(json['mpesa_transaction_date'] as String)
          : null,
      mpesaResponseCode: json['mpesa_response_code'] as String?,
      mpesaResponseDescription: json['mpesa_response_description'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.parse(json['rejected_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      user: json['user'] as int,
      approvedBy: json['approved_by'] as int?,
      rejectedBy: json['rejected_by'] as int?,
    );
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
