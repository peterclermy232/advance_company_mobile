import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/financial_provider.dart';
import '../../../data/providers/auth_provider.dart';

class DepositFormScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const DepositFormScreen({super.key, this.embedded = false});

  @override
  ConsumerState<DepositFormScreen> createState() => _DepositFormScreenState();
}

class _DepositFormScreenState extends ConsumerState<DepositFormScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _amountCtl = TextEditingController();
  final _phoneCtl  = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(depositsProvider.notifier).createDeposit(
        amount:      double.parse(_amountCtl.text.replaceAll(',', '')),
        method:      'mpesa',
        phoneNumber: _phoneCtl.text.trim(),
      );

      if (!success) {
        final error = ref.read(depositsProvider).error;
        setState(() => _errorMessage = error ?? 'Failed to create deposit');
        return;
      }

      // Refresh account
      ref.read(financialAccountProvider.notifier).refresh();

      if (mounted) {
        _showSuccess();
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Deposit Initiated'),
        content: const Text(
          'An M-Pesa STK Push has been sent to your phone.\n'
              'Enter your PIN to complete the transaction.\n\n'
              'Your deposit will be reflected after admin approval.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (!widget.embedded) Navigator.pop(context);
              _amountCtl.clear();
              _phoneCtl.clear();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme        = Theme.of(context);
    final accountAsync = ref.watch(financialAccountProvider);
    final user         = ref.watch(currentUserProvider);
    final phoneNumber  = user?.phoneNumber ?? '';

    if (phoneNumber.isNotEmpty && _phoneCtl.text.isEmpty) {
      _phoneCtl.text = phoneNumber;
    }

    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Monthly limit card
            accountAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (account) => _LimitCard(account: account),
            ),

            const SizedBox(height: 24),

            // Amount field
            TextFormField(
              controller: _amountCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount (KES)',
                prefixIcon: Icon(Icons.attach_money),
                hintText: 'e.g. 5,000',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Amount is required';
                final amount = double.tryParse(v.replaceAll(',', ''));
                if (amount == null || amount <= 0) return 'Enter a valid amount';
                if (amount < 100) return 'Minimum deposit is KES 100';

                final account = accountAsync.valueOrNull;
                if (account != null && amount > account.remainingMonthlyLimit) {
                  return 'Exceeds monthly limit. Remaining: '
                      'KES ${account.remainingMonthlyLimit.toStringAsFixed(0)}';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Phone number
            TextFormField(
              controller: _phoneCtl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'M-Pesa Phone Number',
                prefixIcon: Icon(Icons.phone),
                hintText: '07XXXXXXXX',
                border: OutlineInputBorder(),
                helperText: 'You will receive an STK Push on this number',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone number required';
                final cleaned = v.replaceAll(RegExp(r'\D'), '');
                if (cleaned.length < 9 || cleaned.length > 12) {
                  return 'Enter a valid Kenyan phone number';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),

            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.send),
              label: Text(_isLoading ? 'Processing...' : 'Send STK Push'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Make a Deposit'),
        centerTitle: true,
      ),
      body: body,
    );
  }
}

class _LimitCard extends StatelessWidget {
  final dynamic account;

  const _LimitCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final percent   = (account.limitUsagePercent as double);
    final remaining = account.remainingMonthlyLimit as double;
    final limit     = account.monthlyDepositLimit as double;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Deposit Limit', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: percent > 0.8 ? Colors.orange : theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'KES ${remaining.toStringAsFixed(0)} remaining',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: remaining < 1000 ? Colors.orange : null,
                  ),
                ),
                Text(
                  'Limit: KES ${limit.toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}