import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme_config.dart';
import '../../../data/providers/financial_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';

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
        icon: const Icon(Icons.check_circle_rounded,
            color: AppColors.success, size: 48),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
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
      padding: const EdgeInsets.all(20),
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

            const SizedBox(height: 20),

            // Form section card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Deposit Details', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),

                  // Amount field
                  TextFormField(
                    controller: _amountCtl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Amount (KES)',
                      prefixIcon: Icon(Icons.attach_money),
                      hintText: 'e.g. 5,000',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Amount is required';
                      }
                      final amount = double.tryParse(v.replaceAll(',', ''));
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount';
                      }
                      if (amount < 100) return 'Minimum deposit is KES 100';

                      final account = accountAsync.valueOrNull;
                      if (account != null &&
                          amount > account.remainingMonthlyLimit) {
                        return 'Exceeds monthly limit. Remaining: '
                            'KES ${account.remainingMonthlyLimit.toStringAsFixed(0)}';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Phone number
                  TextFormField(
                    controller: _phoneCtl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'M-Pesa Phone Number',
                      prefixIcon: Icon(Icons.phone),
                      hintText: '07XXXXXXXX',
                      helperText: 'You will receive an STK Push on this number',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Phone number required';
                      }
                      final cleaned = v.replaceAll(RegExp(r'\D'), '');
                      if (cleaned.length < 9 || cleaned.length > 12) {
                        return 'Enter a valid Kenyan phone number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // M-Pesa instructions callout
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.infoText, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You will receive an M-Pesa STK Push prompt on your '
                      'phone. Enter your PIN to complete the transaction. '
                      'Your deposit reflects in your account once an admin '
                      'approves it.',
                      style: TextStyle(
                          color: AppColors.infoText,
                          fontSize: 13,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.errorText),
                      ),
                    ),
                  ],
                ),
              ),

            CustomButton(
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
              gradient: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(_isLoading ? 'Processing...' : 'Send STK Push',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ],
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Deposit Limit', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              color: percent > 0.8 ? AppColors.warning : AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KES ${remaining.toStringAsFixed(0)} remaining',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: remaining < 1000 ? AppColors.warning : null,
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
    );
  }
}