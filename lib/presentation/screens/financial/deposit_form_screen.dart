import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/financial_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_indicator.dart';

class DepositFormScreen extends ConsumerStatefulWidget {
  const DepositFormScreen({super.key});

  @override
  ConsumerState<DepositFormScreen> createState() => _DepositFormScreenState();
}

class _DepositFormScreenState extends ConsumerState<DepositFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _paymentMethod = 'mpesa';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_paymentMethod == 'mpesa') {
      // Show M-Pesa PIN prompt bottom sheet AFTER phone number is confirmed
      final confirmed = await _showMpesaBottomSheet();
      if (confirmed != true) return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = await ref.read(financialRepositoryProvider.future);
      await repo.createDeposit({
        'amount': double.parse(_amountCtrl.text.replaceAll(',', '')),
        'payment_method': _paymentMethod,
        'phone_number': _phoneCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Deposit request submitted! Check your phone for M-Pesa prompt.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Shows the M-Pesa confirmation bottom sheet that tells the user
  /// to check their phone for the STK Push PIN prompt.
  Future<bool?> _showMpesaBottomSheet() {
    final phone = _phoneCtrl.text.trim();
    final amount = _amountCtrl.text.trim();

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MpesaPinBottomSheet(
        phone: phone,
        amount: amount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Make a Deposit')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Amount ─────────────────────────────────────────────────
            const Text('Amount (KES)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: 'KES ',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter an amount';
                final amount = double.tryParse(v.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return 'Enter a valid amount';
                }
                if (amount < 100) return 'Minimum deposit is KES 100';
                return null;
              },
            ),

            const SizedBox(height: 20),

            // ── Payment Method ──────────────────────────────────────────
            const Text('Payment Method',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PaymentMethodCard(
                    label: 'M-Pesa',
                    icon: Icons.phone_android,
                    color: const Color(0xFF00A651),
                    selected: _paymentMethod == 'mpesa',
                    onTap: () => setState(() => _paymentMethod = 'mpesa'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PaymentMethodCard(
                    label: 'Bank',
                    icon: Icons.account_balance,
                    color: Colors.blue,
                    selected: _paymentMethod == 'bank',
                    onTap: () => setState(() => _paymentMethod = 'bank'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PaymentMethodCard(
                    label: 'Cash',
                    icon: Icons.money,
                    color: Colors.orange,
                    selected: _paymentMethod == 'cash',
                    onTap: () => setState(() => _paymentMethod = 'cash'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Phone Number (M-Pesa only) ──────────────────────────────
            if (_paymentMethod == 'mpesa') ...[
              const Text('M-Pesa Phone Number',
                  style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                decoration: InputDecoration(
                  hintText: '0712345678 or 254712345678',
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF00A651)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  helperText:
                  'You will receive an M-Pesa PIN prompt on this number',
                  helperStyle: TextStyle(color: Colors.grey.shade600),
                ),
                onChanged: (_) => setState(() {}), // rebuild to enable button
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your M-Pesa number';
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 9 || digits.length > 12) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // M-Pesa info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A651).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF00A651).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Color(0xFF00A651), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'After tapping "Proceed", you\'ll be asked to enter your M-Pesa PIN on your phone to complete the payment.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF007A3D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Notes ───────────────────────────────────────────────────
            const Text('Notes (optional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Monthly contribution',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),

            const SizedBox(height: 32),

            // ── Submit ──────────────────────────────────────────────────
            CustomButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _paymentMethod == 'mpesa'
                        ? Icons.phone_android
                        : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _paymentMethod == 'mpesa'
                        ? 'Proceed to M-Pesa'
                        : 'Submit Deposit',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payment Method Selector Card ───────────────────────────────────────────────
class _PaymentMethodCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── M-Pesa PIN Bottom Sheet ────────────────────────────────────────────────────
class _MpesaPinBottomSheet extends StatelessWidget {
  final String phone;
  final String amount;

  const _MpesaPinBottomSheet({
    required this.phone,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    // Format phone for display
    String displayPhone = phone;
    if (phone.startsWith('0') && phone.length == 10) {
      displayPhone = '+254${phone.substring(1)}';
    } else if (phone.startsWith('254')) {
      displayPhone = '+$phone';
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // M-Pesa logo area
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF00A651).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.phone_android,
                color: Color(0xFF00A651),
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'M-Pesa Payment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'An M-Pesa STK Push has been sent to',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            displayPhone,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00A651),
            ),
          ),
          const SizedBox(height: 24),

          // Step-by-step instructions
          _InstructionStep(
            step: '1',
            text: 'Check your phone for the M-Pesa prompt',
            color: const Color(0xFF00A651),
          ),
          const SizedBox(height: 12),
          _InstructionStep(
            step: '2',
            text: 'Enter your M-Pesa PIN to authorize KES $amount',
            color: const Color(0xFF00A651),
          ),
          const SizedBox(height: 12),
          _InstructionStep(
            step: '3',
            text: 'Tap "I\'ve Entered My PIN" once done',
            color: const Color(0xFF00A651),
          ),

          const SizedBox(height: 28),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A651),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                "I've Entered My PIN ✓",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Instruction Step Widget ────────────────────────────────────────────────────
class _InstructionStep extends StatelessWidget {
  final String step;
  final String text;
  final Color color;

  const _InstructionStep({
    required this.step,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ),
      ],
    );
  }
}