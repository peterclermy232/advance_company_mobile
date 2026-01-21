import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/financial_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class DepositFormScreen extends ConsumerStatefulWidget {
  const DepositFormScreen({super.key});

  @override
  ConsumerState<DepositFormScreen> createState() => _DepositFormScreenState();
}

class _DepositFormScreenState extends ConsumerState<DepositFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedPaymentMethod = 'MPESA';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final financialRepository = await ref.read(financialRepositoryProvider.future);
      await financialRepository.createDeposit({
        'amount': _amountController.text,
        'payment_method': _selectedPaymentMethod,
        'mpesa_phone': _phoneController.text,
        'notes': _notesController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deposit submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
        ref.invalidate(depositsProvider);
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Deposit'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deposit Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: _amountController,
                        label: 'Amount (KES)',
                        hintText: 'Enter amount',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          final amount = double.tryParse(value!);
                          if (amount == null || amount <= 0) {
                            return 'Enter valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Payment Method',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedPaymentMethod,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: ['MPESA', 'BANK_TRANSFER', 'CASH']
                            .map((method) => DropdownMenuItem(
                                  value: method,
                                  child: Text(method.replaceAll('_', ' ')),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedPaymentMethod = value!);
                        },
                      ),
                      const SizedBox(height: 16),

                      if (_selectedPaymentMethod == 'MPESA')
                        CustomTextField(
                          controller: _phoneController,
                          label: 'M-PESA Phone Number',
                          hintText: '254712345678',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (_selectedPaymentMethod == 'MPESA' &&
                                (value?.isEmpty ?? true)) {
                              return 'Required for M-PESA';
                            }
                            return null;
                          },
                        ),
                      if (_selectedPaymentMethod == 'MPESA')
                        const SizedBox(height: 16),

                      CustomTextField(
                        controller: _notesController,
                        label: 'Notes (Optional)',
                        hintText: 'Add any notes',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              CustomButton(
                onPressed: _isLoading ? null : _handleSubmit,
                isLoading: _isLoading,
                child: const Text('Submit Deposit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}