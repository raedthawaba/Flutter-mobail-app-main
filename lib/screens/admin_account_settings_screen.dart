import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dialogs.dart';

class AdminAccountSettingsScreen extends StatefulWidget {
  const AdminAccountSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAccountSettingsScreen> createState() =>
      _AdminAccountSettingsScreenState();
}

class _AdminAccountSettingsScreenState
    extends State<AdminAccountSettingsScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  // Controllers for user info
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // Controllers for password change
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // Form keys
  final _infoFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  
  User? _currentUser;
  bool _isLoading = true;
  bool _isUpdatingInfo = false;
  bool _isChangingPassword = false;
  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);
      final user = await _authService.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _fullNameController.text = user.fullName;
          _usernameController.text = user.username;
          _emailController.text = user.email;
          _phoneController.text = user.phoneNumber ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل بيانات المستخدم: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateUserInfo() async {
    if (!_infoFormKey.currentState!.validate() || _currentUser == null) return;

    final confirmed = await CustomDialogs.showConfirmationDialog(
      context: context,
      title: 'تحديث بيانات الحساب',
      content: 'هل تريد حفظ التغييرات في بيانات الحساب؟',
      confirmText: 'حفظ',
      cancelText: 'إلغاء',
    );

    if (confirmed != true) return;

    setState(() => _isUpdatingInfo = true);

    try {
      final updatedUser = _currentUser!.copyWith(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
      );

      await _firestoreService.updateUser(updatedUser);
      setState(() {
        _currentUser = updatedUser;
        _isUpdatingInfo = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث بيانات الحساب بنجاح ✅'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUpdatingInfo = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث البيانات: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate() || _currentUser == null) return;

    final confirmed = await CustomDialogs.showConfirmationDialog(
      context: context,
      title: 'تغيير كلمة المرور',
      content: 'هل تريد تغيير كلمة المرور؟',
      confirmText: 'تغيير',
      cancelText: 'إلغاء',
    );

    if (confirmed != true) return;

    setState(() => _isChangingPassword = true);

    try {
      // استخدام AuthService.changePassword
      final success = await _authService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (!success) {
        throw Exception('فشل تغيير كلمة المرور');
      }

      setState(() => _isChangingPassword = false);

      // مسح حقول كلمات المرور
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تغيير كلمة المرور بنجاح ✅'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isChangingPassword = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تغيير كلمة المرور: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال الاسم الكامل';
    }
    if (value.trim().length < 3) {
      return 'الاسم يجب أن يكون 3 أحرف على الأقل';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال اسم المستخدم';
    }
    if (value.trim().length < 3) {
      return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    if (!_authService.isValidEmail(value.trim())) {
      return 'البريد الإلكتروني غير صالح';
    }
    return null;
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كلمة المرور الحالية';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كلمة المرور الجديدة';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى تأكيد كلمة المرور';
    }
    if (value != _newPasswordController.text) {
      return 'كلمتا المرور غير متطابقتين';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إعدادات الحساب',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryWhite,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: AppColors.primaryWhite),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGreen,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // بيانات الحساب
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _infoFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: AppColors.primaryGreen,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'بيانات الحساب',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            CustomTextField(
                              controller: _fullNameController,
                              label: 'الاسم الكامل',
                              icon: Icons.person_outline,
                              validator: _validateFullName,
                            ),
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _usernameController,
                              label: 'اسم المستخدم',
                              icon: Icons.account_circle_outlined,
                              validator: _validateUsername,
                            ),
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _emailController,
                              label: 'البريد الإلكتروني',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _phoneController,
                              label: 'رقم الهاتف (اختياري)',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 24),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isUpdatingInfo ? null : _updateUserInfo,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isUpdatingInfo
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: AppColors.primaryWhite,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'حفظ التغييرات',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryWhite,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // تغيير كلمة المرور
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _passwordFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lock,
                                  color: AppColors.warning,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'تغيير كلمة المرور',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            CustomTextField(
                              controller: _currentPasswordController,
                              label: 'كلمة المرور الحالية',
                              icon: Icons.lock_outline,
                              obscureText: _hideCurrentPassword,
                              validator: _validateCurrentPassword,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _hideCurrentPassword = !_hideCurrentPassword;
                                  });
                                },
                                icon: Icon(
                                  _hideCurrentPassword 
                                      ? Icons.visibility 
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _newPasswordController,
                              label: 'كلمة المرور الجديدة',
                              icon: Icons.lock_outline,
                              obscureText: _hideNewPassword,
                              validator: _validateNewPassword,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _hideNewPassword = !_hideNewPassword;
                                  });
                                },
                                icon: Icon(
                                  _hideNewPassword 
                                      ? Icons.visibility 
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _confirmPasswordController,
                              label: 'تأكيد كلمة المرور',
                              icon: Icons.lock_outline,
                              obscureText: _hideConfirmPassword,
                              validator: _validateConfirmPassword,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _hideConfirmPassword = !_hideConfirmPassword;
                                  });
                                },
                                icon: Icon(
                                  _hideConfirmPassword 
                                      ? Icons.visibility 
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isChangingPassword ? null : _changePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.warning,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isChangingPassword
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: AppColors.primaryWhite,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'تغيير كلمة المرور',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryWhite,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // ملاحظة أمان
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'لأمان حسابك، استخدم كلمة مرور قوية تتضمن أرقام ورموز.',
                            style: TextStyle(
                              color: AppColors.info,
                              fontSize: 14,
                            ),
                          ),
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
