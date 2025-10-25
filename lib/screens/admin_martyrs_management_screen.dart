import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/martyr.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_dialogs.dart';
import '../widgets/info_card.dart';

class AdminMartyrsManagementScreen extends StatefulWidget {
  const AdminMartyrsManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminMartyrsManagementScreen> createState() =>
      _AdminMartyrsManagementScreenState();
}

class _AdminMartyrsManagementScreenState
    extends State<AdminMartyrsManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Martyr> _martyrs = [];
  List<Martyr> _filteredMartyrs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'الكل';
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMartyrs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMartyrs() async {
    try {
      setState(() => _isLoading = true);
      final martyrs = await _firestoreService.getAllMartyrs();
      setState(() {
        _martyrs = martyrs;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredMartyrs = _martyrs.where((martyr) {
        final matchesSearch = martyr.fullName
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()) ||
            martyr.idNumber.contains(_searchQuery);
        
        final matchesStatus = _statusFilter == 'الكل' ||
            (_statusFilter == 'مؤكد' && martyr.isApproved) ||
            (_statusFilter == 'قيد المراجعة' && !martyr.isApproved);
            
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onStatusFilterChanged(String status) {
    setState(() {
      _statusFilter = status;
      _applyFilters();
    });
  }

  Future<void> _approveMartyr(Martyr martyr) async {
    final confirmed = await CustomDialogs.showConfirmationDialog(
      context: context,
      title: 'تأكيد توثيق الشهيد',
      content: 'هل تريد تأكيد وتوثيق بيانات الشهيد ${martyr.fullName}؟',
      confirmText: 'تأكيد',
      cancelText: 'إلغاء',
    );

    if (confirmed == true) {
      try {
        await _firestoreService.updateMartyrStatus(
          martyr.id!,
          AppConstants.statusApproved,
          null,
        );
        _loadMartyrs();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تأكيد وتوثيق الشهيد بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تأكيد الشهيد: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteMartyr(Martyr martyr) async {
    final confirmed = await CustomDialogs.showConfirmationDialog(
      context: context,
      title: 'حذف بيانات الشهيد',
      content: 'هل أنت متأكد من حذف بيانات الشهيد ${martyr.fullName}؟\n\nهذا الإجراء لا يمكن التراجع عنه!',
      confirmText: 'حذف',
      cancelText: 'إلغاء',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteMartyr(martyr.id!);
        _loadMartyrs();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف بيانات الشهيد'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في حذف الشهيد: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showMartyrDetails(Martyr martyr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'بيانات الشهيد',
          style: TextStyle(color: AppColors.primaryGreen),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              InfoCard(title: 'الاسم الكامل', value: martyr.fullName),
              InfoCard(title: 'رقم الهوية', value: martyr.idNumber),
              InfoCard(title: 'العمر', value: martyr.age.toString()),
              InfoCard(title: 'المنطقة', value: martyr.area),
              InfoCard(title: 'تاريخ الاستشهاد', value: _formatDate(martyr.dateOfMartyrdom)),
              InfoCard(title: 'مكان الاستشهاد', value: martyr.placeOfMartyrdom),
              InfoCard(title: 'سبب الاستشهاد', value: martyr.causeOfMartyrdom),
              InfoCard(
                title: 'حالة التوثيق',
                value: martyr.isApproved ? 'مؤكد ✅' : 'قيد المراجعة ⏳',
                valueColor: martyr.isApproved ? AppColors.success : AppColors.warning,
              ),
              if (martyr.notes?.isNotEmpty == true)
                InfoCard(title: 'ملاحظات', value: martyr.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          if (!martyr.isApproved)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _approveMartyr(martyr);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: const Text('تأكيد'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMartyr(martyr);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إدارة الشهداء',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryWhite,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: AppColors.primaryWhite),
        actions: [
          IconButton(
            onPressed: _loadMartyrs,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث والفلترة
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryWhite,
            child: Column(
              children: [
                // شريط البحث
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'البحث بالاسم أو رقم الهوية...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                
                // فلترة الحالة
                Row(
                  children: [
                    const Text(
                      'فلترة الحالة: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        isExpanded: true,
                        onChanged: (value) => _onStatusFilterChanged(value!),
                        items: ['الكل', 'مؤكد', 'قيد المراجعة']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // عداد النتائج
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primaryGreen.withOpacity(0.1),
            child: Text(
              'إجمالي النتائج: ${_filteredMartyrs.length}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          
          // قائمة الشهداء
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  )
                : _filteredMartyrs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'لا توجد بيانات شهداء'
                                  : 'لا توجد نتائج للبحث',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredMartyrs.length,
                        itemBuilder: (context, index) {
                          final martyr = _filteredMartyrs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: martyr.isApproved
                                    ? AppColors.success
                                    : AppColors.warning,
                                child: Icon(
                                  martyr.isApproved
                                      ? Icons.verified
                                      : Icons.pending,
                                  color: AppColors.primaryWhite,
                                ),
                              ),
                              title: Text(
                                martyr.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('رقم الهوية: ${martyr.idNumber}'),
                                  Text('المنطقة: ${martyr.area}'),
                                  Text(
                                    'تاريخ الاستشهاد: ${_formatDate(martyr.dateOfMartyrdom)}',
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: martyr.isApproved
                                          ? AppColors.success.withOpacity(0.1)
                                          : AppColors.warning.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      martyr.isApproved ? 'مؤكد ✅' : 'قيد المراجعة ⏳',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: martyr.isApproved
                                            ? AppColors.success
                                            : AppColors.warning,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) {
                                  switch (action) {
                                    case 'details':
                                      _showMartyrDetails(martyr);
                                      break;
                                    case 'approve':
                                      _approveMartyr(martyr);
                                      break;
                                    case 'delete':
                                      _deleteMartyr(martyr);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'details',
                                    child: ListTile(
                                      leading: Icon(Icons.info_outline),
                                      title: Text('التفاصيل'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  if (!martyr.isApproved)
                                    const PopupMenuItem(
                                      value: 'approve',
                                      child: ListTile(
                                        leading: Icon(Icons.check_circle_outline),
                                        title: Text('تأكيد'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.delete_outline,
                                        color: AppColors.error,
                                      ),
                                      title: Text(
                                        'حذف',
                                        style: TextStyle(color: AppColors.error),
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _showMartyrDetails(martyr),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
