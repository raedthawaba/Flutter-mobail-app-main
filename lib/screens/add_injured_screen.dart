import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/injured.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/file_service.dart';

class AddInjuredScreen extends StatefulWidget {
  const AddInjuredScreen({Key? key}) : super(key: key);

  @override
  State<AddInjuredScreen> createState() => _AddInjuredScreenState();
}

class _AddInjuredScreenState extends State<AddInjuredScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // المتحكمات
  final _fullNameController = TextEditingController();
  final _tribeController = TextEditingController();
  final _injuryPlaceController = TextEditingController();
  final _injuryTypeController = TextEditingController();
  final _injuryDescriptionController = TextEditingController();
  final _currentStatusController = TextEditingController();
  final _hospitalNameController = TextEditingController();
  final _contactFamilyController = TextEditingController();

  // درجة الإصابة
  String? _selectedInjuryDegree;

  // التواريخ
  DateTime? _injuryDate;

  // الملفات
  File? _photoFile;
  File? _cvFile;

  // الخدمات
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final FileService _fileService = FileService();

  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _tribeController.dispose();
    _injuryPlaceController.dispose();
    _injuryTypeController.dispose();
    _injuryDescriptionController.dispose();
    _currentStatusController.dispose();
    _hospitalNameController.dispose();
    _contactFamilyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectInjuryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        _injuryDate = picked;
      });
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختر مصدر الصورة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'الكاميرا',
                    source: ImageSource.camera,
                  ),
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'المعرض',
                    source: ImageSource.gallery,
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final File? image = await _fileService.pickImage(source: source);
        if (image != null) {
          setState(() {
            _photoFile = image;
          });
        }
      }
    } catch (e) {
      _showErrorMessage('خطأ في اختيار الصورة: $e');
    }
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required ImageSource source,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryWhite, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _pickCvFile() async {
    try {
      final File? file = await _fileService.pickDocument();
      if (file != null) {
        setState(() {
          _cvFile = file;
        });
      }
    } catch (e) {
      _showErrorMessage('خطأ في اختيار الملف: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // التحقق من الحقول المطلوبة
    if (_injuryDate == null) {
      _showErrorMessage('يرجى تحديد تاريخ الإصابة');
      return;
    }

    if (_selectedInjuryDegree == null) {
      _showErrorMessage('يرجى تحديد درجة الإصابة');
      return;
    }

    if (_photoFile == null) {
      _showErrorMessage('يرجى إضافة صورة الجريح');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String? userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('خطأ في تحديد المستخدم');
      }

      final injured = Injured(
        fullName: _fullNameController.text.trim(),
        tribe: _tribeController.text.trim(),
        injuryDate: _injuryDate!,
        injuryPlace: _injuryPlaceController.text.trim(),
        injuryType: _injuryTypeController.text.trim(),
        injuryDescription: _injuryDescriptionController.text.trim(),
        injuryDegree: _selectedInjuryDegree!,
        currentStatus: _currentStatusController.text.trim(),
        hospitalName: _hospitalNameController.text.trim().isEmpty ? null : _hospitalNameController.text.trim(),
        contactFamily: _contactFamilyController.text.trim(),
        addedByUserId: userId,
        photoPath: _photoFile!.path,
        cvFilePath: _cvFile?.path,
        status: AppConstants.statusPending,
        createdAt: DateTime.now(),
      );

      await _firestoreService.insertInjured(injured);

      _showSuccessMessage('تم إرسال بيانات الجريح بنجاح إلى السحابة! سيتم مراجعتها من قبل المسؤول.');

      // العودة للصفحة السابقة
      Navigator.of(context).pop();

    } catch (e) {
      _showErrorMessage('خطأ في حفظ البيانات: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إضافة جريح',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryWhite,
          ),
        ),
        backgroundColor: AppColors.warning,
        iconTheme: const IconThemeData(color: AppColors.primaryWhite),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            // بطاقة المعلومات الأساسية
            _buildSectionCard(
              title: 'المعلومات الأساسية',
              icon: Icons.person,
              children: [
                _buildTextField(
                  controller: _fullNameController,
                  label: 'الاسم الكامل *',
                  icon: Icons.person,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _tribeController,
                  label: 'القبيلة / المنطقة *',
                  icon: Icons.location_on,
                  required: true,
                ),
              ],
            ),

            // بطاقة تفاصيل الإصابة
            _buildSectionCard(
              title: 'تفاصيل الإصابة',
              icon: Icons.healing,
              children: [
                _buildDateField(
                  label: 'تاريخ الإصابة *',
                  date: _injuryDate,
                  onTap: _selectInjuryDate,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _injuryPlaceController,
                  label: 'مكان الإصابة *',
                  icon: Icons.place,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _injuryTypeController,
                  label: 'نوع الإصابة *',
                  icon: Icons.medical_services,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _injuryDescriptionController,
                  label: 'وصف تفصيلي للإصابة *',
                  icon: Icons.description,
                  required: true,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  label: 'درجة الإصابة *',
                  value: _selectedInjuryDegree,
                  items: AppConstants.injuryDegrees,
                  onChanged: (value) {
                    setState(() {
                      _selectedInjuryDegree = value;
                    });
                  },
                  icon: Icons.priority_high,
                ),
              ],
            ),

            // بطاقة الحالة الطبية
            _buildSectionCard(
              title: 'الحالة الطبية الحالية',
              icon: Icons.medical_information,
              children: [
                _buildTextField(
                  controller: _currentStatusController,
                  label: 'الحالة الحالية *',
                  icon: Icons.health_and_safety,
                  required: true,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _hospitalNameController,
                  label: 'اسم المستشفى أو الجهة التي عالجته',
                  icon: Icons.local_hospital,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _contactFamilyController,
                  label: 'رقم هاتف للتواصل *',
                  icon: Icons.phone,
                  required: true,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),

            // بطاقة الملفات
            _buildSectionCard(
              title: 'الملفات المرفقة',
              icon: Icons.attach_file,
              children: [
                _buildFileField(
                  label: 'صورة الجريح *',
                  file: _photoFile,
                  onTap: _pickPhoto,
                  icon: Icons.photo,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildFileField(
                  label: 'تقرير طبي أو ملف سيرة ذاتية (PDF أو DOCX)',
                  file: _cvFile,
                  onTap: _pickCvFile,
                  icon: Icons.description,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // زر الإرسال
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: AppColors.primaryWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: AppColors.primaryWhite)
                    : const Text(
                        'إرسال البيانات',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // ملاحظة
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'الحقول المطلوبة مميزة بعلامة (*). سيتم مراجعة البيانات من قبل المسؤول قبل التوثيق النهائي.',
                      style: TextStyle(color: AppColors.info, fontSize: 12),
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.textLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.warning),
        ),
      ),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
              ? 'هذا الحقل مطلوب'
              : null
          : null,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.textLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.warning),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'يرجى اختيار درجة الإصابة' : null,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    bool required = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    date != null
                        ? DateFormat('yyyy/MM/dd').format(date)
                        : 'اضغط لتحديد التاريخ',
                    style: TextStyle(
                      fontSize: 16,
                      color: date != null ? AppColors.textPrimary : AppColors.textLight,
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

  Widget _buildFileField({
    required String label,
    required File? file,
    required VoidCallback onTap,
    required IconData icon,
    bool required = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    file != null
                        ? file.path.split('/').last
                        : 'اضغط لاختيار ملف',
                    style: TextStyle(
                      fontSize: 16,
                      color: file != null ? AppColors.textPrimary : AppColors.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (file != null)
              IconButton(
                onPressed: () {
                  setState(() {
                    if (icon == Icons.photo) {
                      _photoFile = null;
                    } else {
                      _cvFile = null;
                    }
                  });
                },
                icon: const Icon(Icons.clear, color: AppColors.error),
              ),
          ],
        ),
      ),
    );
  }
}