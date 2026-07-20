import 'package:flutter_test/flutter_test.dart';
import 'package:saccoapp/data/models/financial_account_model.dart';

// Regression coverage for a real bug: this model assumed `id`/`user` were
// ints and read a `balance` field that the backend never actually sends —
// the real my_account/ payload has no `balance` key at all, only
// total_contributions/interest_earned as stringified decimals.
void main() {
  // Captured verbatim from a real /api/financial/accounts/my_account/ response.
  final liveBackendJson = {
    'uuid': 'e0b081f4-8b49-4725-a4c3-6766a906b885',
    'user_name': 'Peter Atito',
    'total_contributions': '60000.00',
    'interest_earned': '3000.00',
    'interest_rate': '5.00',
    'created_at': '2026-02-19T17:52:57.539020+03:00',
    'updated_at': '2026-07-16T21:38:09.372029+03:00',
    'user': '471fd5b8-de88-4626-a998-2c6b2c6c0e74',
  };

  test('parses a real account payload without throwing', () {
    final account = FinancialAccountModel.fromJson(liveBackendJson);

    expect(account.id, 'e0b081f4-8b49-4725-a4c3-6766a906b885');
    expect(account.userId, '471fd5b8-de88-4626-a998-2c6b2c6c0e74');
    expect(account.interestEarned, 3000.0);
    expect(account.interestRate, 5.0);
    // No `balance` field in the real payload — derived from
    // total_contributions + interest_earned instead of silently reading 0.
    expect(account.balance, 63000.0);
  });

  test('falls back to sensible defaults when fields are missing', () {
    final account = FinancialAccountModel.fromJson({});

    expect(account.id, '');
    expect(account.balance, 0.0);
    expect(account.monthlyDepositLimit, 20000.0);
  });
}
