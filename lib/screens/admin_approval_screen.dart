import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pending_data.dart';
import '../models/martyr.dart';
import '../models/injured.dart';
import '../models/prisoner.dart';
import '../services/firebase_database_service.dart';
import '../constants/app_constants.dart';
import '../constants/app_colors.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({Key? key}) : super(key: key);

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();
  
  List<PendingData> _pendingData = [];
  bool _isLoading = true;
  String _selectedStatus = 'all'; // all, pending, approved, rejected, hidden
  String _selectedType = 'all'; // all, martyr, injured, prisoner
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadPendingData();
  }

  Future<void> _loadPendingData() async {
    try {
      setState(() => _isLoading = true);
      
      final data = await _dbService.getPendingData(
        statusFilter: _selectedStatus == 'all' ? null : _selectedStatus,
        typeFilter: _selectedType == 'all' ? null : _selectedType,
      );
      
      setState(() {
        _pendingData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
      );
    }
  }

  List<PendingData> get _filteredData {
    List<PendingData> filtered = _pendingData;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final data = item.data.toString().toLowerCase();
        return data.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة البيانات المرسلة'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildDataList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط البحث
          TextField(
            decoration: const InputDecoration(
              hintText: 'البحث في البيانات...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 12),
          // فلاتر الحالة والنوع
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'الحالة',
                    prefixIcon: Icon(Icons.filter_list),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('جميع الحالات')),
                    DropdownMenuItem(value: 'pending', child: Text('في الانتظار')),
                    DropdownMenuItem(value: 'approved', child: Text('معتمد')),
                    DropdownMenuItem(value: 'rejected', child: Text('مرفوض')),
                    DropdownMenuItem(value: 'hidden', child: Text('مخفي')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                      _loadPendingData();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'النوع',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('جميع الأنواع')),
                    DropdownMenuItem(value: 'martyr', child: Text('شهداء')),
                    DropdownMenuItem(value: 'injured', child: Text('جرحى')),
                    DropdownMenuItem(value: 'prisoner', child: Text('أسرى')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                      _loadPendingData();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataList() {
    if (_filteredData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا توجد بيانات',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredData.length,
      itemBuilder: (context, index) {
        final item = _filteredData[index];
        return _buildDataCard(item);
      },
    );
  }

  Widget _buildDataCard(PendingData item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(
          _getItemTitle(item),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_getTypeText(item.type)} - ${_getStatusText(item.status)} - ${DateFormat('yyyy/MM/dd').format(item.submittedAt)}',
        ),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(item.status),
          child: Text(
            _getTypeIcon(item.type),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الصور والملفات
                if (item.imageUrl != null || item.resumeUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        if (item.imageUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton.icon(
                              onPressed: () => _viewImage(item.imageUrl!),
                              icon: const Icon(Icons.image),
                              label: const Text('عرض الصورة'),
                            ),
                          ),
                        if (item.resumeUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton.icon(
                              onPressed: () => _viewFile(item.resumeUrl!),
                              icon: const Icon(Icons.description),
                              label: const Text('عرض السيرة'),
                            ),
                          ),
                      ],
                    ),
                  ),
                // البيانات الأساسية
                ..._buildDataDetails(item.data),
                const SizedBox(height: 12),
                // أزرار التحكم
                _buildActionButtons(item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDataDetails(Map<String, dynamic> data) {
    List<Widget> widgets = [];
    
    data.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    '$key:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(value.toString()),
                ),
              ],
            ),
          ),
        );
      }
    });
    
    return widgets;
  }

  Widget _buildActionButtons(PendingData item) {
    if (item.status == 'pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () => _approveData(item),
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('موافقة'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          ElevatedButton.icon(
            onPressed: () => _rejectData(item),
            icon: const Icon(Icons.close, color: Colors.white),
            label: const Text('رفض'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
          ElevatedButton.icon(
            onPressed: () => _hideData(item),
            icon: const Icon(Icons.visibility_off, color: Colors.white),
            label: const Text('إخفاء'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (item.status == 'approved' || item.status == 'hidden')
            ElevatedButton.icon(
              onPressed: () => _hideData(item),
              icon: const Icon(Icons.visibility_off, color: Colors.white),
              label: const Text('إخفاء'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ElevatedButton.icon(
            onPressed: () => _deleteData(item),
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text('حذف'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      );
    }
  }

  String _getItemTitle(PendingData item) {
    if (item.data['fullName'] != null) {
      return item.data['fullName'];
    }
    if (item.data['name'] != null) {
      return item.data['name'];
    }
    return 'بيانات ${_getTypeText(item.type)}';
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'martyr':
        return 'شهيد';
      case 'injured':
        return 'جريح';
      case 'prisoner':
        return 'أسير';
      default:
        return type;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'في الانتظار';
      case 'approved':
        return 'معتمد';
      case 'rejected':
        return 'مرفوض';
      case 'hidden':
        return 'مخفي';
      default:
        return status;
    }
  }

  String _getTypeIcon(String type) {
    switch (type) {
      case 'martyr':
        return '✟';
      case 'injured':
        return '🏥';
      case 'prisoner':
        return '🔒';
      default:
        return '📄';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'hidden':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  void _viewImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('عرض الصورة')),
          body: Center(
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }

  void _viewFile(String fileUrl) {
    // يمكن إضافة PDF viewer أو file viewer هنا
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم فتح الملف قريباً...')),
    );
  }

  Future<void> _approveData(PendingData item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الموافقة'),
        content: Text('هل تريد الموافقة على هذه البيانات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('موافقة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // إضافة البيانات إلى المجموعة الرئيسية مع status = 'approved'
        await _insertApprovedData(item);
        
        // تحديث حالة البيانات في pending_data
        await _dbService.approveData(item.id!);
        
        _loadPendingData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت الموافقة على البيانات بنجاح')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في الموافقة: $e')),
          );
        }
      }
    }
  }

  Future<void> _rejectData(PendingData item) async {
    final TextEditingController reasonController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الرفض'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('يرجى إدخال سبب الرفض:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'سبب الرفض',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('رفض', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && reasonController.text.trim().isNotEmpty) {
      try {
        await _dbService.rejectData(item.id!, reason: reasonController.text);
        _loadPendingData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفض البيانات')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في الرفض: $e')),
          );
        }
      }
    }
  }

  Future<void> _hideData(PendingData item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الإخفاء'),
        content: const Text('هل تريد إخفاء هذه البيانات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('إخفاء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _dbService.hideData(item.id!);
        _loadPendingData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إخفاء البيانات')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في الإخفاء: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteData(PendingData item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذه البيانات نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _dbService.deleteData(item.id!);
        _loadPendingData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف البيانات نهائياً')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في الحذف: $e')),
          );
        }
      }
    }
  }

  /// إضافة البيانات المعتمدة إلى المجموعة الرئيسية
  Future<void> _insertApprovedData(PendingData item) async {
    try {
      // إضافة البيانات المطلوبة للـ models الأصلية
      final approvedData = Map<String, dynamic>.from(item.data);
      
      // تحويل أسماء الحقول لتطابق النماذج الأصلية
      approvedData['status'] = 'approved';
      approvedData['created_at'] = DateTime.now().toIso8601String();
      approvedData['added_by_user_id'] = 'admin'; // UID افتراضي للمسؤول
      approvedData['contact_family'] = approvedData['contact_family'] ?? '';
      
      // تحديد اسم المؤسسة للـ tribe
      if (!approvedData.containsKey('tribe')) {
        approvedData['tribe'] = 'غير محدد';
      }
      
      // إضافة URLs للصور وملفات السيرة (أسماء الحقول الصحيحة)
      if (item.imageUrl != null) {
        approvedData['photo_path'] = item.imageUrl;
      }
      if (item.resumeUrl != null) {
        approvedData['cv_file_path'] = item.resumeUrl;
      }

      switch (item.type) {
        case 'martyr':
          final martyr = Martyr.fromMap(approvedData);
          await _dbService.insertMartyr(martyr);
          break;
        case 'injured':
          final injured = Injured.fromMap(approvedData);
          await _dbService.insertInjured(injured);
          break;
        case 'prisoner':
          final prisoner = Prisoner.fromMap(approvedData);
          await _dbService.insertPrisoner(prisoner);
          break;
      }
    } catch (e) {
      throw Exception('خطأ في إدراج البيانات المعتمدة: $e');
    }
  }
}