import 'package:flutter_test/flutter_test.dart';
import 'package:saccoapp/data/models/deposit_model.dart';

// Regression coverage for a real bug: this model used to assume `id`/`user`
// were ints and `amount` was a raw JSON number. The live backend actually
// sends UUID strings (under `uuid`, not `id`) and stringified decimals,
// which threw on every real deposit until fixed.
void main() {
  // Captured verbatim from a real /api/financial/deposits/ response.
  final liveBackendJson = {
    'uuid': '020dd59a-20ba-44b4-b7d9-5c4e8b5c5a88',
    'user_name': 'Peter Atito',
    'amount': '20000.00',
    'payment_method': 'mpesa',
    'status': 'completed',
    'transaction_reference': 'DEP20260716EC8F97',
    'mpesa_phone': '254728985079',
    'notes': 'deposit',
    'mpesa_checkout_request_id': 'ws_CO_16072026213252585728985079',
    'mpesa_merchant_request_id': '3562-4784-aa83-0330f61ef368173665',
    'mpesa_receipt_number': null,
    'mpesa_transaction_date': null,
    'approved_at': '2026-07-16T21:35:56.049492+03:00',
    'rejected_at': null,
    'rejection_reason': null,
    'created_at': '2026-07-16T21:30:34.627994+03:00',
    'updated_at': '2026-07-16T21:38:09.235276+03:00',
    'user': '471fd5b8-de88-4626-a998-2c6b2c6c0e74',
    'approved_by': '471fd5b8-de88-4626-a998-2c6b2c6c0e74',
    'rejected_by': null,
  };

  test('parses a real deposit payload without throwing', () {
    final deposit = DepositModel.fromJson(liveBackendJson);

    expect(deposit.id, '020dd59a-20ba-44b4-b7d9-5c4e8b5c5a88');
    expect(deposit.amount, 20000.0);
    expect(deposit.status, DepositStatus.approved); // 'completed' -> approved
    expect(deposit.userName, 'Peter Atito');
    expect(deposit.phoneNumber, '254728985079');
    expect(deposit.approvedBy, '471fd5b8-de88-4626-a998-2c6b2c6c0e74');
    expect(deposit.transactionReference, 'DEP20260716EC8F97');
  });

  test('falls back gracefully when uuid/id and amount are missing', () {
    final deposit = DepositModel.fromJson({'status': 'pending'});

    expect(deposit.id, '');
    expect(deposit.amount, 0.0);
    expect(deposit.status, DepositStatus.pending);
    expect(deposit.transactionReference, 'TXN-');
  });
}
