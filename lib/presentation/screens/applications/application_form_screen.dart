import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
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
        backgroundColor: isError ? Colors.red : Colors.green,
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
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Submit applications for loans, withdrawals, or '
                              'membership changes. All applications are reviewed '
                              'by admin.',
                          style: TextStyle(
                              color: Colors.blue.shade900, fontSize: 13),
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
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Application Type',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
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
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Failed to load application types.',
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
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
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
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.help_outline,
                                          size: 16,
                                          color: Colors.grey.shade600),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          selected.description,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700),
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
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _isLoading ? null : _pickDocument,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _supportingDocument != null
                                  ? Colors.green
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: _supportingDocument != null
                                ? Colors.green.shade50
                                : Colors.grey[50],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _supportingDocument != null
                                    ? Icons.check_circle
                                    : Icons.upload_file,
                                size: 48,
                                color: _supportingDocument != null
                                    ? Colors.green
                                    : Colors.grey,
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
                                      ? Colors.green.shade900
                                      : Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_supportingDocument != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${(_supportingDocument!.size / 1024).toStringAsFixed(2)} KB',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
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
                              foregroundColor: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              CustomButton(
                onPressed: _isLoading ? null : _submitApplication,
                isLoading: _isLoading,
                child: const Text('Submit Application'),
              ),
              const SizedBox(height: 16),

              Text(
                'Your application will be reviewed by an administrator. '
                    'You will receive a notification once it has been processed.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}