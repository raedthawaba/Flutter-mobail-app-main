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

  // Helper function to format dates
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      List<dynamic> data = [];
      
      switch (widget.dataType) {
        case 'martyrs':
          data = await _firebaseService.getAllApprovedMartyrs();
          break;
        case 'injured':
          data = await _firebaseService.getAllApprovedInjured();
          break;
        case 'prisoners':
          data = await _firebaseService.getAllApprovedPrisoners();
          break;
      }
      
      setState(() {
        _dataList = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _dataList = [];
        _isLoading = false;
      });
      
      // معالجة أفضل للأخطاء
      String errorMessage = 'خطأ في تحميل البيانات';
      String errorDescription = 'يرجى المحاولة مرة أخرى لاحقاً';
      
      if (e.toString().contains('failed-precondition')) {
        errorMessage = 'خطأ في الاتصال بقاعدة البيانات';
        errorDescription = 'يتطلب إعداد فهارس قاعدة البيانات';
      } else if (e.toString().contains('permission-denied')) {
        errorMessage = 'لا تملك صلاحية للوصول للبيانات';
        errorDescription = 'يرجى التواصل مع الإدارة';
      } else if (e.toString().contains('not-found')) {
        errorMessage = 'قاعدة البيانات غير متوفرة';
        errorDescription = 'يرجى المحاولة لاحقاً';
      }
      
      // عرض رسالة خطأ ودية
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(errorMessage),
          content: Text(errorDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('فهمت'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadData(); // إعادة المحاولة
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  List<dynamic> get _filteredData {
    if (_searchQuery.isEmpty) {
      return _dataList;
    }
    
    return _dataList.where((item) {
      String name = '';
      String location = '';
      
      if (item is Martyr) {
        name = item.fullName.toLowerCase();
        location = item.deathPlace.toLowerCase();
      } else if (item is Injured) {
        name = item.fullName.toLowerCase();
        location = item.injuryPlace.toLowerCase();
      } else if (item is Prisoner) {
        name = item.fullName.toLowerCase();
        location = item.capturePlace.toLowerCase();
      }
      
      return name.contains(_searchQuery.toLowerCase()) ||
             location.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _getImagePath(dynamic item) {
    if (item is Martyr && item.photoPath?.isNotEmpty == true) {
      return item.photoPath!;
    } else if (item is Injured && item.photoPath?.isNotEmpty == true) {
      return item.photoPath!;
    } else if (item is Prisoner && item.photoPath?.isNotEmpty == true) {
      return item.photoPath!;
    }
    return '';
  }

  Color _getTypeColor() {
    switch (widget.dataType) {
      case 'martyrs':
        return AppColors.primaryRed;
      case 'injured':
        return AppColors.primaryGreen;
      case 'prisoners':
        return AppColors.earthBrown;
      default:
        return AppColors.primaryGreen;
    }
  }

  String _getTypeTitle() {
    switch (widget.dataType) {
      case 'martyrs':
        return 'الشهداء';
      case 'injured':
        return 'الجرحى';
      case 'prisoners':
        return 'الأسرى';
      default:
        return 'البيانات';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تصفح ${_getTypeTitle()} المعتمدين',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryWhite,
          ),
        ),
        centerTitle: true,
        backgroundColor: _getTypeColor(),
        elevation: 4,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(
              Icons.refresh,
              color: AppColors.primaryWhite,
            ),
            tooltip: 'تحديث البيانات',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.primaryWhite,
            ),
            tooltip: 'العودة',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'البحث بالاسم أو المكان...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          
          // Content
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
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد بيانات',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty 
                                  ? 'لا توجد نتائج للبحث عن "$_searchQuery"'
                                  : 'لم يتم إضافة أي بيانات بعد',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
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
                          return _buildDataCard(_filteredData[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 200,
              width: double.infinity,
              color: _getTypeColor().withOpacity(0.1),
              child: _buildImageWidget(item),
            ),
          ),
          
          // Content section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(item),
                const SizedBox(height: 12),
                _buildDetailsSection(item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(dynamic item) {
    String imagePath = _getImagePath(item);
    
    if (imagePath.isNotEmpty) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildNoImageWidget();
        },
      );
    } else {
      return _buildNoImageWidget();
    }
  }

  Widget _buildNoImageWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 64,
            color: _getTypeColor(),
          ),
          const SizedBox(height: 8),
          Text(
            'لا توجد صورة',
            style: TextStyle(
              color: _getTypeColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(dynamic item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.fullName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlack,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getTypeColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getDataTypeLabel(item),
                style: const TextStyle(
                  color: AppColors.primaryWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'ID: ${item.idNumber}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(dynamic item) {
    List<Widget> widgets = [];
    
    if (item is Martyr) {
      widgets.addAll([
        _buildDetailRow('الاسم الكامل', item.fullName),
        _buildDetailRow('تاريخ الوفاة', _formatDate(item.deathDate)),
        _buildDetailRow('القبيلة/المنطقة', item.tribe),
        _buildDetailRow('مكان الوفاة', item.deathPlace),
        _buildDetailRow('السبب', item.causeOfDeath),
        _buildDetailRow('العمر', '${item.age} سنة'),
        if (item.notes?.isNotEmpty == true)
          _buildDetailRow('ملاحظات', item.notes!),
      ]);
    } else if (item is Injured) {
      widgets.addAll([
        _buildDetailRow('الاسم الكامل', item.fullName),
        _buildDetailRow('تاريخ الإصابة', _formatDate(item.injuryDate)),
        _buildDetailRow('القبيلة/المنطقة', item.tribe),
        _buildDetailRow('مكان الإصابة', item.injuryPlace),
        _buildDetailRow('نوع الإصابة', item.injuryType),
        _buildDetailRow('درجة الإصابة', item.injuryDegree),
        _buildDetailRow('الوصف', item.injuryDescription),
        if (item.notes?.isNotEmpty == true)
          _buildDetailRow('ملاحظات', item.notes!),
      ]);
    } else if (item is Prisoner) {
      widgets.addAll([
        _buildDetailRow('الاسم الكامل', item.fullName),
        _buildDetailRow('تاريخ الأسر', _formatDate(item.captureDate)),
        _buildDetailRow('القبيلة/المنطقة', item.tribe),
        _buildDetailRow('مكان الأسر', item.capturePlace),
        _buildDetailRow('جهة الأسر', item.capturedBy),
        _buildDetailRow('الحالة الحالية', item.currentStatus),
        if (item.notes?.isNotEmpty == true)
          _buildDetailRow('ملاحظات', item.notes!),
      ]);
    }
    
    return Column(
      children: widgets,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlack,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.primaryBlack,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDataTypeLabel(dynamic item) {
    if (item is Martyr) return 'شهيد';
    if (item is Injured) return 'جريح';
    if (item is Prisoner) return 'أسير';
    return 'غير محدد';
  }
}