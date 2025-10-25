import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/injured.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_dialogs.dart';
import '../widgets/info_card.dart';

class AdminInjuredManagementScreen extends StatefulWidget {
  const AdminInjuredManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminInjuredManagementScreen> createState() =>
      _AdminInjuredManagementScreenState();
}

class _AdminInjuredManagementScreenState
    extends State<AdminInjuredManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Injured> _injured = [];
  List<Injured> _filteredInjured = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'الكل';
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInjured();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInjured() async {
    try {
      setState(() => _isLoading = true);
      final injured = await _firestoreService.getAllInjured();
      setState(() {
        _injured = injured;
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
      _filteredInjured = _injured.where((injured) {
        final matchesSearch = injured.fullName
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()) ||
            injured.idNumber.contains(_searchQuery);
        
        final matchesStatus = _statusFilter == 'الكل' ||
            (_statusFilter == 'مؤكد' && injured.isApproved) ||
            (_statusFilter == 'قيد المراجعة' && !injured.isApproved);
            
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

  Future<void> _approveInjured(Injured injured) async {
    final confirmed = await CustomDialogs.showConfirmationDialog(
      context: context,
      title: 'تأكيد توثيق الجريح',
      content: 'هل تريد تأكيد وتوثيق بيانات الجريح ${injured.fullName}؟',
      confirmText: 'تأكيد',
      cancelText: 'إلغاء',
    );

    if (confirmed == true) {
      try {
        await _firestoreService.updateInjuredStatus(
          injured.id!,
          AppConstants.statusApproved,
          null,
        );
        _loadInjured();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تأكيد وتوثيق الجريح بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تأكيد الجريح: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteInjured(Injured injured) async {
    final confirmed = await CustomDialogs.showConfirmationDialog(
      context: context,
      title: 'حذف بيانات الجريح',
      content: 'هل أنت متأكد من حذف بيانات الجريح ${injured.fullName}؟\n\nهذا الإجراء لا يمكن التراجع عنه!',
      confirmText: 'حذف',
      cancelText: 'إلغاء',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteInjured(injured.id!);
        _loadInjured();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف بيانات الجريح'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في حذف الجريح: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showInjuredDetails(Injured injured) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'بيانات الجريح',
          style: TextStyle(color: AppColors.warning),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              InfoCard(title: 'الاسم الكامل', value: injured.fullName),
              InfoCard(title: 'رقم الهوية', value: injured.idNumber),
              InfoCard(title: 'العمر', value: injured.age.toString()),
              InfoCard(title: 'المنطقة', value: injured.area),
              InfoCard(title: 'تاريخ الإصابة', value: _formatDate(injured.dateOfInjury)),
              InfoCard(title: 'مكان الإصابة', value: injured.placeOfInjury),
              InfoCard(title: 'نوع الإصابة', value: injured.typeOfInjury),
              InfoCard(title: 'حالة الإصابة', value: injured.injurySeverity),
              InfoCard(
                title: 'حالة التوثيق',
                value: injured.isApproved ? 'مؤكد ✅' : 'قيد المراجعة ⏳',
                valueColor: injured.isApproved ? AppColors.success : AppColors.warning,
              ),
              if (injured.notes?.isNotEmpty == true)
                InfoCard(title: 'ملاحظات', value: injured.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          if (!injured.isApproved)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _approveInjured(injured);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: const Text('تأكيد'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteInjured(injured);
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
          'إدارة الجرحى',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryWhite,
          ),
        ),
        backgroundColor: AppColors.warning,
        iconTheme: const IconThemeData(color: AppColors.primaryWhite),
        actions: [
          IconButton(
            onPressed: _loadInjured,
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
            color: AppColors.warning.withOpacity(0.1),
            child: Text(
              'إجمالي النتائج: ${_filteredInjured.length}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ),
          
          // قائمة الجرحى
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.warning,
                    ),
                  )
                : _filteredInjured.isEmpty
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
                                  ? 'لا توجد بيانات جرحى'
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
                        itemCount: _filteredInjured.length,
                        itemBuilder: (context, index) {
                          final injured = _filteredInjured[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: injured.isApproved
                                    ? AppColors.success
                                    : AppColors.warning,
                                child: Icon(
                                  injured.isApproved
                                      ? Icons.verified
                                      : Icons.pending,
                                  color: AppColors.primaryWhite,
                                ),
                              ),
                              title: Text(
                                injured.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('رقم الهوية: ${injured.idNumber}'),
                                  Text('المنطقة: ${injured.area}'),
                                  Text('نوع الإصابة: ${injured.typeOfInjury}'),
                                  Text('حالة الإصابة: ${injured.injurySeverity}'),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: injured.isApproved
                                          ? AppColors.success.withOpacity(0.1)
                                          : AppColors.warning.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      injured.isApproved ? 'مؤكد ✅' : 'قيد المراجعة ⏳',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: injured.isApproved
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
                                      _showInjuredDetails(injured);
                                      break;
                                    case 'approve':
                                      _approveInjured(injured);
                                      break;
                                    case 'delete':
                                      _deleteInjured(injured);
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
                                  if (!injured.isApproved)
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
                              onTap: () => _showInjuredDetails(injured),
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
