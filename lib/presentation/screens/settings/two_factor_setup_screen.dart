import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme_config.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';

class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() =>
      _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen> {
  final List<TextEditingController> _codeCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoadingSetup = true;
  bool _isVerifying = false;
  String? _qrUrl;
  String? _secretKey;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initiate2FA();
  }

  @override
  void dispose() {
    for (final c in _codeCtrl) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  Future<void> _initiate2FA() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.enable2FA();
      final data = result['data'] ?? result;
      setState(() {
        _qrUrl = data['qr_code_url'] as String? ?? data['qr_url'] as String?;
        _secretKey = data['secret_key'] as String? ?? data['secret'] as String?;
        _isLoadingSetup = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoadingSetup = false;
      });
    }
  }

  String get _code => _codeCtrl.map((c) => c.text).join();

  Future<void> _confirm() async {
    final code = _code.trim();
    if (code.length < 6) {
      setState(() => _error = 'Please enter the 6-digit code');
      return;
    }
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.confirm2FA(code);
      await ref.read(authProvider.notifier).refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Two-factor authentication enabled'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isVerifying = false;
      });
    }
  }

  void _onDigitChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Setup Two-Factor Auth',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoadingSetup
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _qrUrl == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoadingSetup = true;
                              _error = null;
                            });
                            _initiate2FA();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _stepCard(
                        step: '1',
                        title: 'Install an authenticator app',
                        body:
                            'Download Google Authenticator, Authy, or any TOTP-compatible app on your phone.',
                      ),
                      const SizedBox(height: 16),
                      _stepCard(
                        step: '2',
                        title: 'Scan the QR code',
                        body: _qrUrl != null
                            ? null
                            : 'QR code unavailable. Use the secret key below.',
                        child: _qrUrl != null
                            ? Column(
                                children: [
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Image.network(
                                      _qrUrl!,
                                      width: 180,
                                      height: 180,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 180,
                                        height: 180,
                                        color: AppColors.divider,
                                        child: const Center(
                                            child:
                                                Text('QR failed to load')),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                      if (_secretKey != null) ...[
                        const SizedBox(height: 16),
                        _stepCard(
                          step: '2b',
                          title: 'Or enter this key manually',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: SelectableText(
                                      _secretKey!,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              fontFamily: 'monospace',
                                              letterSpacing: 2),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy,
                                        color: AppColors.primary),
                                    onPressed: () {
                                      Clipboard.setData(
                                          ClipboardData(text: _secretKey!));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content:
                                                  Text('Key copied')));
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _stepCard(
                        step: '3',
                        title: 'Enter the 6-digit code',
                        body: 'Type the code shown in your authenticator app.',
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                  6, (i) => _digitField(i)),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.errorContainer,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: theme.colorScheme.error,
                                        size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(_error!,
                                          style: TextStyle(
                                              color:
                                                  theme.colorScheme.error,
                                              fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: CustomButton(
                                gradient: true,
                                isLoading: _isVerifying,
                                onPressed: _confirm,
                                child: const Text(
                                  'Enable 2FA',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _stepCard({
    required String step,
    required String title,
    String? body,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary,
                child: Text(step,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
            ],
          ),
          if (body != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(body,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),
          ],
          if (child != null) child,
        ],
      ),
    );
  }

  Widget _digitField(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextFormField(
        controller: _codeCtrl[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style:
            const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          filled: true,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (v) => _onDigitChanged(v, index),
      ),
    );
  }
}
