import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/martyr.dart';
import '../models/injured.dart';
import '../models/prisoner.dart';
import '../services/firebase_database_service.dart';

class UserBrowseDataScreen extends StatefulWidget {
  final String dataType; // 'martyrs', 'injured', 'prisoners'
  
  const UserBrowseDataScreen({
    Key? key,
    required this.dataType,
  }) : super(key: key);

  @override
  State<UserBrowseDataScreen> createState() => _UserBrowseDataScreenState();
}

class _UserBrowseDataScreenState extends State<UserBrowseDataScreen> {
  final FirebaseDatabaseService _firebaseService = FirebaseDatabaseService();
  List<dynamic> _dataList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      List<dynamic> data = await _firebaseService.getAllApprovedData(widget.dataType);
      
      setState(() {
        _dataList = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('خطأ في تحميل البيانات: ${e.toString()}');
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

  void _showDataDetails(dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getIconForType(widget.dataType),
              color: _getColorForType(widget.dataType),
            ),
            const SizedBox(width: 8),
            Text(_getTitleForType(widget.dataType)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildDataDetails(item),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDataDetails(dynamic item) {
    List<Widget> widgets = [];

    // إضافة صورة إذا وجدت
    if (item is Martyr && item.photoUrl?.isNotEmpty == true) {
      widgets.add(
        Center(
          child: Container(
            width: 120,
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getColorForType(widget.dataType),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: Image.network(
                item.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    size: 60,
                    color: AppColors.textSecondary,
                  );
                },
              ),
            ),
          ),
        ),
      );
    } else if (item is Injured && item.photoUrl?.isNotEmpty == true) {
      widgets.add(
        Center(
          child: Container(
            width: 120,
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getColorForType(widget.dataType),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: Image.network(
                item.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    size: 60,
                    color: AppColors.textSecondary,
                  );
                },
              ),
            ),
          ),
        ),
      );
    } else if (item is Prisoner && item.photoUrl?.isNotEmpty == true) {
      widgets.add(
        Center(
          child: Container(
            width: 120,
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getColorForType(widget.dataType),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: Image.network(
                item.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    size: 60,
                    color: AppColors.textSecondary,
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    if (item is Martyr) {
      widgets.addAll([
        _buildDetailRow('الاسم الكامل', item.fullName),
        _buildDetailRow('تاريخ الوفاة', item.deathDate),
        _buildDetailRow('مكان الوفاة', item.deathPlace),
        _buildDetailRow('السبب', item.deathReason),
        _buildDetailRow('العمر', '${item.age ?? 'غير محدد'} سنة'),
        _buildDetailRow('الجنس', item.gender),
        _buildDetailRow('رقم الهاتف', item.phoneNumber ?? 'غير متوفر'),
        _buildDetailRow('العنوان', item.address ?? 'غير متوفر'),
        if (item.notes?.isNotEmpty == true)
          _buildDetailRow('ملاحظات', item.notes!),
      ]);
    } else if (item is Injured) {
      widgets.addAll([
        _buildDetailRow('الاسم الكامل', item.fullName),
        _buildDetailRow('تاريخ الإصابة', item.injuryDate),
        _buildDetailRow('مكان الإصابة', item.injuryPlace),
        _buildDetailRow('نوع الإصابة', item.injuryType),
        _buildDetailRow('الدرجة', item.degree),
        _buildDetailRow('العمر', '${item.age ?? 'غير محدد'} سنة'),
        _buildDetailRow('الجنس', item.gender),
        _buildDetailRow('رقم الهاتف', item.phoneNumber ?? 'غير متوفر'),
        _buildDetailRow('العنوان', item.address ?? 'غير متوفر'),
        if (item.notes?.isNotEmpty == true)
          _buildDetailRow('ملاحظات', item.notes!),
      ]);
    } else if (item is Prisoner) {
      widgets.addAll([
        _buildDetailRow('الاسم الكامل', item.fullName),
        _buildDetailRow('تاريخ الأسر', item.captureDate),
        _buildDetailRow('مكان الأسر', item.capturePlace),
        _buildDetailRow('مكان الاعتقال', item.detentionPlace ?? 'غير محدد'),
        _buildDetailRow('العمر', '${item.age ?? 'غير محدد'} سنة'),
        _buildDetailRow('الجنس', item.gender),
        _buildDetailRow('رقم الهاتف', item.phoneNumber ?? 'غير متوفر'),
        _buildDetailRow('العنوان', item.address ?? 'غير متوفر'),
        if (item.notes?.isNotEmpty == true)
          _buildDetailRow('ملاحظات', item.notes!),
      ]);
    }

    return widgets;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? 'غير محدد' : value,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const Divider(height: 20),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'martyrs':
        return Icons.person_off_outlined;
      case 'injured':
        return Icons.healing_outlined;
      case 'prisoners':
        return Icons.lock_person_outlined;
      default:
        return Icons.data_object;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'martyrs':
        return AppColors.primaryRed;
      case 'injured':
        return AppColors.warning;
      case 'prisoners':
        return AppColors.earthBrown;
      default:
        return AppColors.primaryGreen;
    }
  }

  String _getTitleForType(String type) {
    switch (type) {
      case 'martyrs':
        return 'بيانات الشهيد';
      case 'injured':
        return 'بيانات الجريح';
      case 'prisoners':
        return 'بيانات الأسير';
      default:
        return 'البيانات';
    }
  }

  String _getSubtitleForItem(dynamic item) {
    if (item is Martyr) {
      return item.deathPlace ?? 'غير محدد';
    } else if (item is Injured) {
      return item.injuryPlace ?? 'غير محدد';
    } else if (item is Prisoner) {
      return item.capturePlace ?? 'غير محدد';
    }
    return 'غير محدد';
  }

  List<dynamic> get _filteredData {
    if (_searchQuery.isEmpty) {
      return _dataList;
    }
    
    return _dataList.where((item) {
      String query = _searchQuery.toLowerCase();
      if (item is Martyr) {
        return item.fullName.toLowerCase().contains(query) ||
               (item.deathPlace?.toLowerCase().contains(query) ?? false);
      } else if (item is Injured) {
        return item.fullName.toLowerCase().contains(query) ||
               (item.injuryPlace?.toLowerCase().contains(query) ?? false);
      } else if (item is Prisoner) {
        return item.fullName.toLowerCase().contains(query) ||
               (item.capturePlace?.toLowerCase().contains(query) ?? false);
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تصفح ${_getTitleForType(widget.dataType)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryWhite,
          ),
        ),
        centerTitle: true,
        backgroundColor: _getColorForType(widget.dataType),
        elevation: 4,
        iconTheme: const IconThemeData(
          color: AppColors.primaryWhite,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getColorForType(widget.dataType).withOpacity(0.1),
              AppColors.primaryWhite,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // شريط البحث
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getColorForType(widget.dataType).withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: _getColorForType(widget.dataType),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'ابحث بالاسم أو المكان...',
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // قائمة البيانات
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _filteredData.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty 
                                      ? 'لا توجد بيانات متاحة'
                                      : 'لا توجد نتائج مطابقة للبحث',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredData.length,
                            itemBuilder: (context, index) {
                              final item = _filteredData[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () => _showDataDetails(item),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // صورة المستخدم أو أيقونة
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: _getColorForType(widget.dataType).withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: ClipOval(
                                            child: (() {
                                              // عرض الصورة إذا وجدت
                                              String? photoUrl;
                                              if (item is Martyr && item.photoUrl?.isNotEmpty == true) {
                                                photoUrl = item.photoUrl;
                                              } else if (item is Injured && item.photoUrl?.isNotEmpty == true) {
                                                photoUrl = item.photoUrl;
                                              } else if (item is Prisoner && item.photoUrl?.isNotEmpty == true) {
                                                photoUrl = item.photoUrl;
                                              }
                                              
                                              if (photoUrl != null) {
                                                return Image.network(
                                                  photoUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Icon(
                                                      _getIconForType(widget.dataType),
                                                      color: _getColorForType(widget.dataType),
                                                      size: 24,
                                                    );
                                                  },
                                                );
                                              } else {
                                                return Icon(
                                                  _getIconForType(widget.dataType),
                                                  color: _getColorForType(widget.dataType),
                                                  size: 24,
                                                );
                                              }
                                            })(),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // معلومات البيانات
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.fullName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _getSubtitleForItem(item),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // أيقونة التفاصيل
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}