import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/prisoner.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_dialogs.dart';
import '../widgets/info_card.dart';

class AdminPrisonersManagementScreen extends StatefulWidget {
  const AdminPrisonersManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminPrisonersManagementScreen> createState() =>
      _AdminPrisonersManagementScreenState();
}

class _AdminPrisonersManagementScreenState
    extends State<AdminPrisonersManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Prisoner> _prisoners = [];
  List<Prisoner> _filteredPrisoners = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'الكل';
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrisoners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrisoners() async {
    try {
      setState(() => _isLoading = true);
      final prisoners = await _firestoreService.getAllPrisoners();
      setState(() {
        _prisoners = prisoners;
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
      _filteredPrisoners = _prisoners.where((prisoner) {
        final matchesSearch = prisoner.fullName
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()) ||
            prisoner.idNumber.contains(_searchQuery);
        
        final matchesStatus = _statusFilter == 'الكل' ||
            (_statusFilter == 'مؤكد' && prisoner.isApproved) ||
            (_statusFilter == 'قيد المراجعة' && !prisoner.isApproved);
            
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

  Future<void> _approvePrisoner(Prisoner prisoner) async {
    final confirmed = await CustomDialogs.showConfirmationDialog(
      context: context,
      title: 'تأكيد توثيق الأسير',
      content: 'هل تريد تأكيد وتوثيق بيانات الأسير ${prisoner.fullName}؟',
      confirmText: 'تأكيد',
      cancelText: 'إلغاء',
    );

    if (confirmed == true) {
      try {
        await _firestoreService.updatePrisonerStatus(
          prisoner.id!,
          AppConstants.statusApproved,
          null,
        );
        _loadPrisoners();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تأكيد وتوثيق الأسير بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تأكيد الأسير: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deletePrisoner(Prisoner prisoner) async {
    final confirmed = await CustomDialogs.showConfirmationDialog(
      context: context,
      title: 'حذف بيانات الأسير',
      content: 'هل أنت متأكد من حذف بيانات الأسير ${prisoner.fullName}؟\n\nهذا الإجراء لا يمكن التراجع عنه!',
      confirmText: 'حذف',
      cancelText: 'إلغاء',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deletePrisoner(prisoner.id!);
        _loadPrisoners();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف بيانات الأسير'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في حذف الأسير: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showPrisonerDetails(Prisoner prisoner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'بيانات الأسير',
          style: TextStyle(color: AppColors.earthBrown),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              InfoCard(title: 'الاسم الكامل', value: prisoner.fullName),
              InfoCard(title: 'رقم الهوية', value: prisoner.idNumber),
              InfoCard(title: 'العمر', value: prisoner.age.toString()),
              InfoCard(title: 'المنطقة', value: prisoner.area),
              InfoCard(title: 'تاريخ الاعتقال', value: _formatDate(prisoner.dateOfArrest)),
              InfoCard(title: 'مكان الاعتقال', value: prisoner.placeOfArrest),
              InfoCard(title: 'سبب الاعتقال', value: prisoner.reasonForArrest),
              if (prisoner.currentPrison?.isNotEmpty == true)
                InfoCard(title: 'السجن الحالي', value: prisoner.currentPrison!),
              InfoCard(
                title: 'حالة التوثيق',
                value: prisoner.isApproved ? 'مؤكد ✅' : 'قيد المراجعة ⏳',
                valueColor: prisoner.isApproved ? AppColors.success : AppColors.warning,
              ),
              if (prisoner.notes?.isNotEmpty == true)
                InfoCard(title: 'ملاحظات', value: prisoner.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          if (!prisoner.isApproved)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _approvePrisoner(prisoner);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: const Text('تأكيد'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePrisoner(prisoner);
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
          'إدارة الأسرى',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryWhite,
          ),
        ),
        backgroundColor: AppColors.earthBrown,
        iconTheme: const IconThemeData(color: AppColors.primaryWhite),
        actions: [
          IconButton(
            onPressed: _loadPrisoners,
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
            color: AppColors.earthBrown.withOpacity(0.1),
            child: Text(
              'إجمالي النتائج: ${_filteredPrisoners.length}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.earthBrown,
              ),
            ),
          ),
          
          // قائمة الأسرى
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.earthBrown,
                    ),
                  )
                : _filteredPrisoners.isEmpty
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
                                  ? 'لا توجد بيانات أسرى'
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
                        itemCount: _filteredPrisoners.length,
                        itemBuilder: (context, index) {
                          final prisoner = _filteredPrisoners[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: prisoner.isApproved
                                    ? AppColors.success
                                    : AppColors.warning,
                                child: Icon(
                                  prisoner.isApproved
                                      ? Icons.verified
                                      : Icons.pending,
                                  color: AppColors.primaryWhite,
                                ),
                              ),
                              title: Text(
                                prisoner.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('رقم الهوية: ${prisoner.idNumber}'),
                                  Text('المنطقة: ${prisoner.area}'),
                                  Text('تاريخ الاعتقال: ${_formatDate(prisoner.dateOfArrest)}'),
                                  if (prisoner.currentPrison?.isNotEmpty == true)
                                    Text('السجن الحالي: ${prisoner.currentPrison}'),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: prisoner.isApproved
                                          ? AppColors.success.withOpacity(0.1)
                                          : AppColors.warning.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      prisoner.isApproved ? 'مؤكد ✅' : 'قيد المراجعة ⏳',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: prisoner.isApproved
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
                                      _showPrisonerDetails(prisoner);
                                      break;
                                    case 'approve':
                                      _approvePrisoner(prisoner);
                                      break;
                                    case 'delete':
                                      _deletePrisoner(prisoner);
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
                                  if (!prisoner.isApproved)
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
                              onTap: () => _showPrisonerDetails(prisoner),
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
