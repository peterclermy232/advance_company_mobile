import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/financial_provider.dart';

class DepositFormScreen extends ConsumerStatefulWidget {
  const DepositFormScreen({super.key});

  @override
  ConsumerState<DepositFormScreen> createState() => _DepositFormScreenState();
}

class _DepositFormScreenState extends ConsumerState<DepositFormScreen> {
  static const double kMonthlyDepositAmount = 20000;

  String _paymentMethod = 'mpesa';
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _canDeposit = true;
  bool _showMpesaInstructions = false;
  bool _phoneValid = false;

  final _mpesaRegex = RegExp(r'^(\+?254|0)?[17]\d{8}$');

  @override
  void initState() {
    super.initState();
    _checkEligibility();
    _phoneController.addListener(() {
      setState(() {
        _phoneValid = _mpesaRegex.hasMatch(_phoneController.text.trim());
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkEligibility() async {
    try {
      final repo = await ref.read(financialRepositoryProvider.future);
      final result = await repo.canDeposit() as Map<String, dynamic>;
      if (mounted) {
        final canDep = result['can_deposit'] as bool? ?? true;
        final message = result['message'] as String? ?? '';
        setState(() => _canDeposit = canDep);
        if (!canDep && message.isNotEmpty) {
          _showSnackBar(message, Colors.orange);
        }
      }
    } catch (_) {}
  }

  String _formatPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('0')) return '254${cleaned.substring(1)}';
    if (cleaned.startsWith('7') || cleaned.startsWith('1')) return '254$cleaned';
    return cleaned;
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _onSubmit() async {
    if (!_canDeposit) {
      _showSnackBar('You have already made a deposit this month', Colors.orange);
      return;
    }
    if (_paymentMethod == 'mpesa' && !_phoneValid) {
      _showSnackBar('Please enter a valid Safaricom number', Colors.red);
      return;
    }

    setState(() {
      _isSubmitting = true;
      if (_paymentMethod == 'mpesa') _showMpesaInstructions = true;
    });

    final formData = {
      'payment_method': _paymentMethod,
      'notes': _notesController.text,
      if (_paymentMethod == 'mpesa')
        'mpesa_phone': _formatPhone(_phoneController.text.trim()),
    };

    try {
      final repo = await ref.read(financialRepositoryProvider.future);
      await repo.createDeposit(formData);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _canDeposit = false;
          _showMpesaInstructions = false;
          _phoneController.clear();
          _notesController.clear();
        });
        if (_paymentMethod == 'mpesa') {
          _showSnackBar(
              'M-Pesa STK Push sent! Enter your PIN to complete payment.',
              Colors.green);
        } else {
          _showSnackBar('Deposit of KES 20,000 initiated successfully!',
              Colors.green);
        }
        ref.invalidate(depositsProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _showMpesaInstructions = false;
        });
        _showSnackBar(
            e.toString().replaceAll('Exception: ', ''), Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDepositFormCard(),
            ],
          ),
        ),
        if (_showMpesaInstructions) _buildMpesaModal(),
      ],
    );
  }

  Widget _buildDepositFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade500, width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Make Monthly Deposit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Fixed Amount: KES 20,000',
                    style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cannot deposit warning
          if (!_canDeposit) ...[
            _buildWarningBanner(),
            const SizedBox(height: 12),
          ],

          // Info box
          _buildInfoBox(),
          const SizedBox(height: 16),

          // Fixed amount display
          _buildFixedAmountField(),
          const SizedBox(height: 16),

          // Payment method
          _buildPaymentMethodDropdown(),
          const SizedBox(height: 16),

          // M-Pesa phone field
          if (_paymentMethod == 'mpesa') ...[
            _buildPhoneField(),
            const SizedBox(height: 16),
          ],

          // Bank info
          if (_paymentMethod == 'bank') ...[
            _buildBankInfo(),
            const SizedBox(height: 16),
          ],

          // Notes
          _buildNotesField(),
          const SizedBox(height: 20),

          // Submit button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.yellow.shade50,
        border: Border.all(color: Colors.yellow.shade300, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.yellow.shade800, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Already Deposited This Month',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow.shade900)),
                const SizedBox(height: 4),
                Text(
                    'You can only make one deposit per month. Your next deposit will be available next month.',
                    style: TextStyle(
                        color: Colors.yellow.shade800, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: 'Important: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800)),
                TextSpan(
                    text:
                    'Monthly deposits are fixed at KES 20,000. You can only make one deposit per month.',
                    style: TextStyle(color: Colors.blue.shade800, fontSize: 13)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Amount (Fixed)',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            TextFormField(
              enabled: false,
              initialValue: 'KES 20,000',
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            Positioned(
              right: 8,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('FIXED',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Monthly deposit amount is fixed at KES 20,000',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Method *',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _paymentMethod,
          decoration: InputDecoration(
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: const [
            DropdownMenuItem(value: 'mpesa', child: Text('M-Pesa (Instant)')),
            DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
            DropdownMenuItem(value: 'mansa_x', child: Text('Mansa-X')),
          ],
          onChanged: (v) => setState(() => _paymentMethod = v!),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('M-Pesa Phone Number *',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 13,
          decoration: InputDecoration(
            hintText: '0712345678 or +254712345678',
            prefixIcon: const Icon(Icons.phone),
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            counterText: '',
          ),
        ),
        const SizedBox(height: 4),
        if (!_phoneValid && _phoneController.text.isNotEmpty)
          Row(
            children: const [
              Icon(Icons.error_outline, size: 14, color: Colors.red),
              SizedBox(width: 4),
              Text('Please enter a valid Safaricom number (07XX or 01XX)',
                  style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
          )
        else if (_phoneValid)
          Row(
            children: const [
              Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
              SizedBox(width: 4),
              Text("You'll receive a payment prompt on this number",
                  style: TextStyle(color: Colors.green, fontSize: 12)),
            ],
          ),
      ],
    );
  }

  Widget _buildBankInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bank Transfer Details:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ...[
            'Bank: Example Bank',
            'Account: 1234567890',
            'Amount: KES 20,000',
          ].map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(t,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          )),
          const SizedBox(height: 4),
          Text('Send confirmation to admin after transfer',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notes (Optional)',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add any notes about this payment...',
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final bool isDisabled =
        _isSubmitting || !_canDeposit || (_paymentMethod == 'mpesa' && !_phoneValid);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isDisabled ? null : _onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          disabledBackgroundColor: Colors.blue.shade200,
        ),
        icon: _isSubmitting
            ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.monetization_on),
        label: Text(
          _isSubmitting
              ? 'Processing Payment...'
              : _paymentMethod == 'mpesa'
              ? 'Pay KES 20,000 via M-Pesa'
              : 'Submit Deposit',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildMpesaModal() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.phone_android,
                    size: 40, color: Colors.green.shade600),
              ),
              const SizedBox(height: 16),
              const Text('Check Your Phone',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'An M-Pesa payment request has been sent to your phone',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildMpesaStep(1, 'Check for M-Pesa notification on your phone'),
                    const SizedBox(height: 8),
                    _buildMpesaStep(2, 'Enter your M-Pesa PIN'),
                    const SizedBox(height: 8),
                    _buildMpesaStep(3, 'Confirm payment of KES 20,000'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(
                              () => _showMpesaInstructions = false),
                      style: OutlinedButton.styleFrom(
                          padding:
                          const EdgeInsets.symmetric(vertical: 12)),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _showMpesaInstructions = false);
                        _checkEligibility();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("I've Paid"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Payment pending admin approval after successful M-Pesa payment',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMpesaStep(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('$number',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ),
      ],
    );
  }
}