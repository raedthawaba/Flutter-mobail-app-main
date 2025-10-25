import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../constants/app_constants.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  // اختيار صورة من الكاميرا أو المعرض
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        
        // التحقق من حجم الملف
        final fileSizeInMB = await imageFile.length() / (1024 * 1024);
        if (fileSizeInMB > AppConstants.maxImageSizeMB) {
          throw Exception('حجم الصورة كبير جداً. الحد الأقصى ${AppConstants.maxImageSizeMB} ميجابايت');
        }

        // حفظ الصورة في مجلد التطبيق
        return await _saveImageToAppDirectory(imageFile);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في اختيار الصورة: $e');
    }
  }

  // اختيار ملف مستند
  Future<File?> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.supportedDocumentTypes,
      );

      if (result != null && result.files.single.path != null) {
        final File documentFile = File(result.files.single.path!);
        
        // التحقق من حجم الملف
        final fileSizeInMB = await documentFile.length() / (1024 * 1024);
        if (fileSizeInMB > AppConstants.maxDocumentSizeMB) {
          throw Exception('حجم الملف كبير جداً. الحد الأقصى ${AppConstants.maxDocumentSizeMB} ميجابايت');
        }

        // حفظ الملف في مجلد التطبيق
        return await _saveDocumentToAppDirectory(documentFile);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في اختيار الملف: $e');
    }
  }

  // حفظ الصورة في مجلد التطبيق
  Future<File> _saveImageToAppDirectory(File sourceFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = path.join(appDir.path, 'images');
      
      // إنشاء مجلد الصور إذا لم يكن موجوداً
      await Directory(imagesDir).create(recursive: true);

      // إنشاء اسم ملف فريد
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.${path.extension(sourceFile.path).substring(1)}';
      final String newPath = path.join(imagesDir, fileName);

      // نسخ الملف
      return await sourceFile.copy(newPath);
    } catch (e) {
      throw Exception('خطأ في حفظ الصورة: $e');
    }
  }

  // حفظ المستند في مجلد التطبيق
  Future<File> _saveDocumentToAppDirectory(File sourceFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String documentsDir = path.join(appDir.path, 'documents');
      
      // إنشاء مجلد المستندات إذا لم يكن موجوداً
      await Directory(documentsDir).create(recursive: true);

      // إنشاء اسم ملف فريد
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.${path.extension(sourceFile.path).substring(1)}';
      final String newPath = path.join(documentsDir, fileName);

      // نسخ الملف
      return await sourceFile.copy(newPath);
    } catch (e) {
      throw Exception('خطأ في حفظ المستند: $e');
    }
  }

  // حذف ملف
  Future<bool> deleteFile(String filePath) async {
    try {
      final File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // التحقق من وجود ملف
  Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  // الحصول على حجم الملف بالميجابايت
  Future<double> getFileSizeInMB(String filePath) async {
    try {
      final File file = File(filePath);
      final int bytes = await file.length();
      return bytes / (1024 * 1024);
    } catch (e) {
      return 0.0;
    }
  }

  // الحصول على نوع الملف
  String getFileType(String filePath) {
    return path.extension(filePath).toLowerCase().substring(1);
  }

  // التحقق من أن الملف صورة
  bool isImageFile(String filePath) {
    final String extension = getFileType(filePath);
    return AppConstants.supportedImageTypes.contains(extension);
  }

  // التحقق من أن الملف مستند
  bool isDocumentFile(String filePath) {
    final String extension = getFileType(filePath);
    return AppConstants.supportedDocumentTypes.contains(extension);
  }

  // تنظيف الملفات القديمة (اختياري - لإدارة المساحة)
  Future<void> cleanOldFiles({int daysOld = 30}) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      // تنظيف الصور القديمة
      final Directory imagesDir = Directory(path.join(appDir.path, 'images'));
      if (await imagesDir.exists()) {
        await _cleanDirectoryFiles(imagesDir, cutoffDate);
      }

      // تنظيف المستندات القديمة
      final Directory documentsDir = Directory(path.join(appDir.path, 'documents'));
      if (await documentsDir.exists()) {
        await _cleanDirectoryFiles(documentsDir, cutoffDate);
      }
    } catch (e) {
      // تجاهل الأخطاء في التنظيف
    }
  }

  Future<void> _cleanDirectoryFiles(Directory directory, DateTime cutoffDate) async {
    final List<FileSystemEntity> files = directory.listSync();
    for (FileSystemEntity file in files) {
      if (file is File) {
        final FileStat stat = await file.stat();
        if (stat.modified.isBefore(cutoffDate)) {
          try {
            await file.delete();
          } catch (e) {
            // تجاهل أخطاء الحذف
          }
        }
      }
    }
  }

  // الحصول على مسار مجلد الصور
  Future<String> getImagesDirectory() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'images');
  }

  // الحصول على مسار مجلد المستندات
  Future<String> getDocumentsDirectory() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'documents');
  }
}