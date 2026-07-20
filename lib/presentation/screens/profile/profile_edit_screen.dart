// lib/presentation/screens/profile/profile_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../config/theme_config.dart';
import '../../widgets/common/custom_button.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _professionCtrl;

  String? _selectedGender;
  String? _selectedMaritalStatus;
  bool _isLoading = false;

  static const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
  static const _maritalStatuses = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
  ];

  @override
  void initState() {
    super.initState();
    // Initialise from currentUserProvider — this is now available in auth_provider.dart
    final user = ref.read(currentUserProvider);
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
    _professionCtrl = TextEditingController(text: user?.profession ?? '');
    _selectedGender = user?.gender;
    _selectedMaritalStatus = user?.maritalStatus;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _professionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await ref.read(authProvider.notifier).updateProfile({
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'phone_number': _phoneCtrl.text.trim(),
      'profession': _professionCtrl.text.trim(),
      if (_selectedGender != null) 'gender': _selectedGender,
      if (_selectedMaritalStatus != null)
        'marital_status': _selectedMaritalStatus,
    });

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        final error = ref.read(authProvider).error ?? 'Update failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar header
              Container(
                color: AppColors.primary,
                padding: const EdgeInsets.only(bottom: 32),
                child: Center(
                  child: Stack(
                    children: [
                      user?.profilePhotoUrl != null
                          ? CircleAvatar(
                              radius: 50,
                              backgroundImage:
                                  NetworkImage(user!.profilePhotoUrl!),
                            )
                          : Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: AppColors.brandGradient,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 3),
                              ),
                              child: Center(
                                child: Text(
                                  (user?.firstName.isNotEmpty == true
                                      ? user!.firstName[0].toUpperCase()
                                      : '?'),
                                  style: const TextStyle(
                                    fontSize: 36,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Personal Information'),
                    _buildCard([
                      _textField(
                        controller: _firstNameCtrl,
                        label: 'First Name',
                        icon: Icons.person_outline,
                        validator: (v) =>
                        v!.isEmpty ? 'First name is required' : null,
                      ),
                      _divider(),
                      _textField(
                        controller: _lastNameCtrl,
                        label: 'Last Name',
                        icon: Icons.person_outline,
                        validator: (v) =>
                        v!.isEmpty ? 'Last name is required' : null,
                      ),
                      _divider(),
                      _textField(
                        controller: _phoneCtrl,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      _divider(),
                      _textField(
                        controller: _professionCtrl,
                        label: 'Profession / Occupation',
                        icon: Icons.work_outline,
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _sectionHeader('Additional Details'),
                    _buildCard([
                      _dropdownField(
                        label: 'Gender',
                        icon: Icons.wc_outlined,
                        value: _selectedGender,
                        items: _genders,
                        onChanged: (v) => setState(() => _selectedGender = v),
                      ),
                      _divider(),
                      _dropdownField(
                        label: 'Marital Status',
                        icon: Icons.favorite_outline,
                        value: _selectedMaritalStatus,
                        items: _maritalStatuses,
                        onChanged: (v) =>
                            setState(() => _selectedMaritalStatus = v),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // Email (read-only)
                    _sectionHeader('Account Information'),
                    _buildCard([
                      _readOnlyField(
                        label: 'Email Address',
                        value: user?.email ?? '',
                        icon: Icons.email_outlined,
                      ),
                      _divider(),
                      _readOnlyField(
                        label: 'Member ID',
                        value: user != null ? '#${user.uuid}' : '',
                        icon: Icons.badge_outlined,
                      ),
                    ]),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: CustomButton(
                        gradient: true,
                        isLoading: _isLoading,
                        onPressed: _save,
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _buildCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      boxShadow: AppColors.cardShadow,
    ),
    child: Column(children: children),
  );

  Widget _divider() => const Divider(height: 1, color: AppColors.divider);

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        border: InputBorder.none,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        border: InputBorder.none,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      items: items
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
    );
  }

  Widget _readOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}