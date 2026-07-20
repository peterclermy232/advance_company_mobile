import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../config/theme_config.dart';
import '../../../data/models/application_type_model.dart';
import '../../../data/providers/application_providers.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class ApplicationFormScreen extends ConsumerStatefulWidget {
  const ApplicationFormScreen({super.key});

  @override
  ConsumerState<ApplicationFormScreen> createState() =>
      _ApplicationFormScreenState();
}

class _ApplicationFormScreenState
    extends ConsumerState<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String? _selectedType;
  PlatformFile? _supportingDocument;
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ── File picking ────────────────────────────────────────────────────────────

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _supportingDocument = result.files.first);
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', isError: true);
    }
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(applicationsProvider.notifier).submitApplication(
        applicationType: _selectedType!,
        reason: _reasonController.text.trim(),
        documentPath: _supportingDocument?.path,
        documentName: _supportingDocument?.name,
      );

      if (mounted) {
        _showSnackBar('Application submitted successfully!');
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(applicationTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Application')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Info banner
              const Card(
                color: AppColors.infoBg,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Submit applications for loans, withdrawals, or '
                              'membership changes. All applications are reviewed '
                              'by admin.',
                          style: TextStyle(
                              color: AppColors.infoText, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Application details card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Application Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Application Type',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),

                      typesAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, _) => Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.error),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Failed to load application types.',
                                  style: TextStyle(color: AppColors.errorText),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    ref.refresh(applicationChoicesProvider),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                        data: (types) {
                          // Auto-select first type
                          if (_selectedType == null && types.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(
                                        () => _selectedType = types.first.value);
                              }
                            });
                          }

                          final selected = types.cast<ApplicationTypeModel?>().firstWhere(
                                (t) => t?.value == _selectedType,
                            orElse: () =>
                            types.isNotEmpty ? types.first : null,
                          );

                          return Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedType,
                                items: types
                                    .map((t) => DropdownMenuItem(
                                  value: t.value,
                                  child: Text(t.label,
                                      style: const TextStyle(
                                          fontSize: 14)),
                                ))
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _selectedType = value),
                                validator: (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Please select an application type'
                                    : null,
                              ),
                              if (selected != null &&
                                  selected.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.divider,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.help_outline,
                                          size: 16,
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          selected.description,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: _reasonController,
                        label: 'Reason for Application',
                        hintText:
                        'Explain why you are submitting this application',
                        maxLines: 5,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please provide a reason';
                          }
                          if (value!.length < 20) {
                            return 'Please provide more details '
                                '(at least 20 characters)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Supporting document card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supporting Documents (Optional)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _DashedDropzone(
                        onTap: _isLoading ? null : _pickDocument,
                        borderColor: _supportingDocument != null
                            ? AppColors.success
                            : AppColors.border,
                        fillColor: _supportingDocument != null
                            ? AppColors.successBg
                            : AppColors.divider,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                _supportingDocument != null
                                    ? Icons.check_circle
                                    : Icons.upload_file,
                                size: 48,
                                color: _supportingDocument != null
                                    ? AppColors.success
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _supportingDocument != null
                                    ? _supportingDocument!.name
                                    : 'Tap to attach supporting document',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _supportingDocument != null
                                      ? AppColors.successText
                                      : AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_supportingDocument != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${(_supportingDocument!.size / 1024).toStringAsFixed(2)} KB',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (_supportingDocument != null) ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => setState(
                                  () => _supportingDocument = null),
                          icon: const Icon(Icons.close),
                          label: const Text('Remove document'),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              CustomButton(
                gradient: true,
                onPressed: _isLoading ? null : _submitApplication,
                isLoading: _isLoading,
                child: const Text('Submit Application'),
              ),
              const SizedBox(height: 16),

              Text(
                'Your application will be reviewed by an administrator. '
                    'You will receive a notification once it has been processed.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dashed upload dropzone ────────────────────────────────────────────────────

/// Lightweight dashed-border drop-zone container — mirrors the web app's
/// dashed file-upload panel without pulling in a new dependency.
class _DashedDropzone extends StatelessWidget {
  const _DashedDropzone({
    required this.child,
    required this.onTap,
    required this.borderColor,
    required this.fillColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color borderColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: borderColor,
          radius: AppRadius.sm,
        ),
        child: Material(
          color: fillColor,
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.primary.withOpacity(0.08),
            highlightColor: AppColors.primary.withOpacity(0.04),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashWidth = 6.0;
    const dashSpace = 4.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
