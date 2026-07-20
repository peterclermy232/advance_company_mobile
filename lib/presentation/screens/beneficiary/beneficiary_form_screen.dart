import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../config/theme_config.dart';
import '../../../data/providers/beneficiary_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class BeneficiaryFormScreen extends ConsumerStatefulWidget {
  const BeneficiaryFormScreen({super.key});

  @override
  ConsumerState<BeneficiaryFormScreen> createState() =>
      _BeneficiaryFormScreenState();
}

class _BeneficiaryFormScreenState
    extends ConsumerState<BeneficiaryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _professionController = TextEditingController();
  final _allocationController = TextEditingController(text: '0');

  // Backend expects lowercase relation choices
  String _selectedRelation = 'spouse';
  // Backend gender field maps to User.GENDER_CHOICES — typically 'M'/'F'/'O'
  String _selectedGender = 'M';
  String? _selectedSalaryRange;
  PlatformFile? _identityDocument;
  PlatformFile? _birthCertificate;

  bool _isLoading = false;

  // Values MUST match backend model choices exactly
  final List<Map<String, String>> _relations = [
    {'value': 'spouse',  'label': 'Spouse'},
    {'value': 'child',   'label': 'Child'},
    {'value': 'parent',  'label': 'Parent'},
    {'value': 'sibling', 'label': 'Sibling'},
    {'value': 'other',   'label': 'Other'},
  ];

  final List<Map<String, String>> _genders = [
    {'value': 'M', 'label': 'Male'},
    {'value': 'F', 'label': 'Female'},
    {'value': 'O', 'label': 'Other'},
  ];

  final List<String> _salaryRanges = [
    'BELOW_20K',
    '20K_50K',
    '50K_100K',
    'ABOVE_100K',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _professionController.dispose();
    _allocationController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String fileType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true, // required on web
    );
    if (result != null) {
      setState(() {
        if (fileType == 'identity') {
          _identityDocument = result.files.first;
        } else {
          _birthCertificate = result.files.first;
        }
      });
    }
  }

  /// Cross-platform: use bytes on web, path on mobile/desktop.
  Future<MultipartFile> _toMultipartFile(PlatformFile file) async {
    if (file.bytes != null) {
      return MultipartFile.fromBytes(file.bytes!, filename: file.name);
    } else if (file.path != null) {
      return await MultipartFile.fromFile(file.path!, filename: file.name);
    }
    throw Exception(
        'Cannot read file "${file.name}": no bytes or path available.');
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Identity document is required by backend model
    if (_identityDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identity document is required'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> fields = {
        'name': _nameController.text.trim(),
        'relation': _selectedRelation,   // lowercase: 'spouse', 'child', etc.
        'age': _ageController.text,
        'gender': _selectedGender,       // 'M', 'F', or 'O'
        'phone_number': _phoneController.text.trim(),
        'profession': _professionController.text.trim(),
        'percentage_allocation':
        double.tryParse(_allocationController.text) ?? 0.0,
        if (_selectedSalaryRange != null) 'salary_range': _selectedSalaryRange,
      };

      // Await all file conversions before building FormData
      fields['identity_document'] =
      await _toMultipartFile(_identityDocument!);
      if (_birthCertificate != null) {
        fields['birth_certificate'] =
        await _toMultipartFile(_birthCertificate!);
      }

      final formData = FormData.fromMap(fields);
      await ref
          .read(beneficiariesProvider.notifier)
          .addBeneficiary(formData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beneficiary added successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Beneficiary')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSection('Personal Information', [
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hintText: 'Enter full name',
                  validator: (v) =>
                  v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Relation',
                        value: _selectedRelation,
                        items: _relations,
                        onChanged: (v) =>
                            setState(() => _selectedRelation = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _ageController,
                        label: 'Age',
                        hintText: 'Age',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Required';
                          final age = int.tryParse(v!);
                          if (age == null || age <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Gender',
                  value: _selectedGender,
                  items: _genders,
                  onChanged: (v) =>
                      setState(() => _selectedGender = v!),
                ),
              ]),

              const SizedBox(height: 24),

              _buildSection('Contact & Financial', [
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hintText: '+254712345678',
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                  v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _professionController,
                  label: 'Profession',
                  hintText: 'Enter profession',
                ),
                const SizedBox(height: 16),
                // Salary range dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Salary Range (Optional)',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSalaryRange,
                      hint: const Text('Select salary range'),
                      items: _salaryRanges
                          .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                              r.replaceAll('_', ' '))))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedSalaryRange = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Percentage allocation
                CustomTextField(
                  controller: _allocationController,
                  label: 'Allocation Percentage (%)',
                  hintText: 'e.g. 25',
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final val = double.tryParse(v);
                    if (val == null) return 'Enter a valid number';
                    if (val < 0 || val > 100) {
                      return 'Must be between 0 and 100';
                    }
                    return null;
                  },
                ),
              ]),

              const SizedBox(height: 24),

              _buildSection('Documents', [
                _buildFileUpload(
                  'Identity Document *',
                  _identityDocument,
                      () => _pickFile('identity'),
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildFileUpload(
                  'Birth Certificate (Optional)',
                  _birthCertificate,
                      () => _pickFile('birth'),
                ),
              ]),

              const SizedBox(height: 32),

              CustomButton(
                onPressed: _isLoading ? null : _handleSubmit,
                isLoading: _isLoading,
                gradient: true,
                child: const Text('Add Beneficiary'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem(
            value: item['value'],
            child: Text(item['label']!),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildFileUpload(
      String label,
      PlatformFile? file,
      VoidCallback onTap, {
        bool required = false,
      }) {
    final hasError = required && file == null;
    final borderColor = hasError
        ? AppColors.error
        : (file != null ? AppColors.success : AppColors.border);
    final fillColor = file != null ? AppColors.successBg : AppColors.background;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(AppRadius.md),
              color: fillColor,
            ),
            child: Row(
              children: [
                Icon(
                  file != null ? Icons.check_circle : Icons.upload_file,
                  color: file != null ? AppColors.success : AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file?.name ?? 'Tap to upload',
                    style: TextStyle(
                        color: file != null
                            ? AppColors.textPrimary
                            : AppColors.textMuted),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}