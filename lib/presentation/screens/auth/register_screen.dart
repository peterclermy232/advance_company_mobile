// lib/presentation/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../config/theme_config.dart';
import '../../widgets/common/custom_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _firstCtl = TextEditingController();
  final _lastCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    for (final c in [_emailCtl, _passCtl, _firstCtl, _lastCtl, _phoneCtl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });
    try {
      // authRepositoryProvider is a plain Provider — no await needed
      final repo = ref.read(authRepositoryProvider);
      await repo.register(
        email: _emailCtl.text.trim(),
        password: _passCtl.text,
        firstName: _firstCtl.text.trim(),
        lastName: _lastCtl.text.trim(),
        phoneNumber: _phoneCtl.text.isEmpty ? null : _phoneCtl.text.trim(),
      );
      setState(() => _success = 'Account created! Check your email to verify.');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_success != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 48),
                    const SizedBox(height: 8),
                    Text(_success!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    CustomButton(
                        gradient: true,
                        onPressed: () => context.go('/verify-email',
                            extra: _emailCtl.text.trim()),
                        child: const Text('Verify Email')),
                  ]),
                )
              else ...[
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Create Account',
                  style: theme.textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up to get started',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _field(_firstCtl, 'First Name', Icons.person_outlined,
                    TextInputAction.next),
                const SizedBox(height: 16),
                _field(_lastCtl, 'Last Name', Icons.person_outlined,
                    TextInputAction.next),
                const SizedBox(height: 16),
                _field(_emailCtl, 'Email', Icons.email_outlined,
                    TextInputAction.next, type: TextInputType.emailAddress,
                    validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v)) {
                    return 'Enter a valid email';
                  }
                  return null;
                }),
                const SizedBox(height: 16),
                _field(_phoneCtl, 'Phone (optional)', Icons.phone_outlined,
                    TextInputAction.next,
                    type: TextInputType.phone),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'Minimum 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(AppRadius.sm)),
                    child: Text(_error!,
                        style: const TextStyle(color: AppColors.error)),
                  ),
                  const SizedBox(height: 12),
                ],
                CustomButton(
                  onPressed: _isLoading ? null : _register,
                  isLoading: _isLoading,
                  gradient: true,
                  child: const Text('Create Account'),
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Already have an account?'),
                  TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Sign In')),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctl, String label, IconData icon,
      TextInputAction action,
      {TextInputType? type, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctl,
      keyboardType: type,
      textInputAction: action,
      decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon)),
      validator: validator ??
          (v) => (v == null || v.isEmpty) ? '$label is required' : null,
    );
  }
}
