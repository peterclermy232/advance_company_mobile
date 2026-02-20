import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/providers/beneficiary_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class BeneficiaryFormScreen extends ConsumerStatefulWidget {
  const BeneficiaryFormScreen({super.key});

  @override
  ConsumerState<BeneficiaryFormScreen> createState() =>
      _BeneficiaryFormScreenState();
}

class _BeneficiaryFormScreenState extends ConsumerState<BeneficiaryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _professionController = TextEditingController();

  String _selectedRelation = 'SPOUSE';
  String _selectedGender = 'MALE';
  String? _selectedSalaryRange;
  PlatformFile? _identityDocument;
  PlatformFile? _birthCertificate;

  bool _isLoading = false;

  final List<String> _relations = ['SPOUSE', 'CHILD', 'PARENT', 'SIBLING', 'OTHER'];
  final List<String> _genders = ['MALE', 'FEMALE', 'OTHER'];
  final List<String> _salaryRanges = ['BELOW_20K', '20K_50K', '50K_100K', 'ABOVE_100K'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String fileType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true, // ✅ Required for web: populates file.bytes
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

  /// ✅ Cross-platform: uses bytes on web, path on mobile/desktop.
  Future<MultipartFile> _toMultipartFile(PlatformFile file) async {
    if (file.bytes != null) {
      return MultipartFile.fromBytes(file.bytes!, filename: file.name);
    } else if (file.path != null) {
      return await MultipartFile.fromFile(file.path!, filename: file.name);
    }
    throw Exception('Cannot read file "${file.name}": no bytes or path available.');
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // ✅ Await all MultipartFile conversions BEFORE FormData.fromMap()
      final Map<String, dynamic> fields = {
        'name': _nameController.text.trim(),
        'relation': _selectedRelation,
        'age': _ageController.text,
        'gender': _selectedGender,
        'phone_number': _phoneController.text.trim(),
        'profession': _professionController.text.trim(),
        if (_selectedSalaryRange != null) 'salary_range': _selectedSalaryRange,
      };

      if (_identityDocument != null) {
        fields['identity_document'] = await _toMultipartFile(_identityDocument!);
      }
      if (_birthCertificate != null) {
        fields['birth_certificate'] = await _toMultipartFile(_birthCertificate!);
      }

      final formData = FormData.fromMap(fields);
      final repository = await ref.read(beneficiaryRepositoryProvider.future);
      await repository.createBeneficiary(formData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beneficiary added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
        ref.invalidate(beneficiariesProvider);
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
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Relation',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedRelation,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: _relations
                                .map((rel) => DropdownMenuItem(value: rel, child: Text(rel)))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedRelation = value!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _ageController,
                        label: 'Age',
                        hintText: 'Age',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          final age = int.tryParse(value!);
                          if (age == null || age <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gender',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: _genders
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedGender = value!),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 24),

              _buildSection('Contact Information', [
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hintText: '+254712345678',
                  keyboardType: TextInputType.phone,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _professionController,
                  label: 'Profession',
                  hintText: 'Enter profession',
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Salary Range (Optional)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSalaryRange,
                      hint: const Text('Select salary range'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: _salaryRanges
                          .map((r) => DropdownMenuItem(value: r, child: Text(r.replaceAll('_', ' '))))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedSalaryRange = value),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 24),

              _buildSection('Documents', [
                _buildFileUpload('Identity Document', _identityDocument, () => _pickFile('identity')),
                const SizedBox(height: 16),
                _buildFileUpload('Birth Certificate', _birthCertificate, () => _pickFile('birth')),
              ]),
              const SizedBox(height: 32),

              CustomButton(
                onPressed: _isLoading ? null : _handleSubmit,
                isLoading: _isLoading,
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

  Widget _buildFileUpload(String label, PlatformFile? file, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(
                  file != null ? Icons.check_circle : Icons.upload_file,
                  color: file != null ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file?.name ?? 'Tap to upload',
                    style: TextStyle(color: file != null ? Colors.black : Colors.grey),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}