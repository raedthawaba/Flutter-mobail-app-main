import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/prisoner.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/file_service.dart';

class AddPrisonerScreen extends StatefulWidget {
  const AddPrisonerScreen({Key? key}) : super(key: key);

  @override
  State<AddPrisonerScreen> createState() => _AddPrisonerScreenState();
}

class _AddPrisonerScreenState extends State<AddPrisonerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // المتحكمات
  final _fullNameController = TextEditingController();
  final _tribeController = TextEditingController();
  final _capturePlaceController = TextEditingController();
  final _capturedByController = TextEditingController();
  final _currentStatusController = TextEditingController();
  final _familyContactController = TextEditingController();
  final _detentionPlaceController = TextEditingController();
  final _notesController = TextEditingController();

  // التواريخ
  DateTime? _captureDate;
  DateTime? _releaseDate;

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
    _capturePlaceController.dispose();
    _capturedByController.dispose();
    _currentStatusController.dispose();
    _familyContactController.dispose();
    _detentionPlaceController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectCaptureDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        _captureDate = picked;
      });
    }
  }

  Future<void> _selectReleaseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: _captureDate ?? DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        _releaseDate = picked;
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
              color: AppColors.earthBrown,
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
    if (_captureDate == null) {
      _showErrorMessage('يرجى تحديد تاريخ الأسر');
      return;
    }

    if (_photoFile == null) {
      _showErrorMessage('يرجى إضافة صورة الأسير');
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

      final prisoner = Prisoner(
        fullName: _fullNameController.text.trim(),
        tribe: _tribeController.text.trim(),
        captureDate: _captureDate!,
        capturePlace: _capturePlaceController.text.trim(),
        capturedBy: _capturedByController.text.trim(),
        currentStatus: _currentStatusController.text.trim(),
        releaseDate: _releaseDate,
        familyContact: _familyContactController.text.trim(),
        detentionPlace: _detentionPlaceController.text.trim().isEmpty ? null : _detentionPlaceController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        addedByUserId: userId,
        photoPath: _photoFile!.path,
        cvFilePath: _cvFile?.path,
        status: AppConstants.statusPending,
        createdAt: DateTime.now(),
      );

      await _firestoreService.insertPrisoner(prisoner);

      _showSuccessMessage('تم إرسال بيانات الأسير بنجاح إلى السحابة! سيتم مراجعتها من قبل المسؤول.');

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
          'إضافة أسير',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryWhite,
          ),
        ),
        backgroundColor: AppColors.earthBrown,
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

            // بطاقة تفاصيل الأسر
            _buildSectionCard(
              title: 'تفاصيل الأسر',
              icon: Icons.lock_person,
              children: [
                _buildDateField(
                  label: 'تاريخ الأسر *',
                  date: _captureDate,
                  onTap: _selectCaptureDate,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _capturePlaceController,
                  label: 'مكان الأسر *',
                  icon: Icons.place,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _capturedByController,
                  label: 'الجهة الآسرة *',
                  icon: Icons.group,
                  required: true,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _detentionPlaceController,
                  label: 'مكان الاحتجاز (إن وُجد)',
                  icon: Icons.account_balance,
                ),
              ],
            ),

            // بطاقة الحالة الحالية
            _buildSectionCard(
              title: 'الحالة الحالية',
              icon: Icons.info,
              children: [
                _buildTextField(
                  controller: _currentStatusController,
                  label: 'الحالة الحالية *',
                  icon: Icons.info_outline,
                  required: true,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _buildDateField(
                  label: 'تاريخ الإفراج (إن وُجد)',
                  date: _releaseDate,
                  onTap: _selectReleaseDate,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _notesController,
                  label: 'ملاحظات إضافية',
                  icon: Icons.note,
                  maxLines: 3,
                ),
              ],
            ),

            // بطاقة معلومات التواصل
            _buildSectionCard(
              title: 'معلومات التواصل',
              icon: Icons.contact_phone,
              children: [
                _buildTextField(
                  controller: _familyContactController,
                  label: 'رقم تواصل العائلة *',
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
                  label: 'صورة الأسير *',
                  file: _photoFile,
                  onTap: _pickPhoto,
                  icon: Icons.photo,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildFileField(
                  label: 'ملف سيرة ذاتية أو تقرير حالة الأسر (PDF أو DOCX)',
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
                  backgroundColor: AppColors.earthBrown,
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
                Icon(icon, color: AppColors.earthBrown),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.earthBrown,
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
          borderSide: BorderSide(color: AppColors.earthBrown),
        ),
      ),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
              ? 'هذا الحقل مطلوب'
              : null
          : null,
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
            Icon(Icons.calendar_today, color: AppColors.earthBrown),
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
            Icon(icon, color: AppColors.earthBrown),
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