import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_dialogs.dart';
import '../widgets/info_card.dart';

class AdminUsersManagementScreen extends StatefulWidget {
  const AdminUsersManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersManagementScreen> createState() =>
      _AdminUsersManagementScreenState();
}

class _AdminUsersManagementScreenState extends State<AdminUsersManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _userTypeFilter = 'الكل';
  
  // دالة تحويل نوع المستخدم من الإنجليزية للعربية
  String _getUserTypeInArabic(String userType) {
    switch (userType) {
      case 'admin':
        return 'مسؤول';
      case 'regular':
        return 'مستخدم';
      default:
        return userType;
    }
  }
  
  // دالة تحويل نوع المستخدم من العربية للإنجليزية
  String _getUserTypeInEnglish(String arabicUserType) {
    switch (arabicUserType) {
      case 'مسؤول':
        return 'admin';
      case 'مستخدم':
        return 'regular';
      default:
        return arabicUserType;
    }
  }
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      final users = await _firestoreService.getAllUsers();
      setState(() {
        _users = users;
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
      _filteredUsers = _users.where((user) {
        final matchesSearch = user.fullName
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()) ||
            user.username.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesUserType = _userTypeFilter == 'الكل' ||
            _getUserTypeInArabic(user.userType) == _userTypeFilter;
            
        return matchesSearch && matchesUserType;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onUserTypeFilterChanged(String userType) {
    setState(() {
      _userTypeFilter = userType;
      _applyFilters();
    });
  }

  Future<void> _changeUserType(User user) async {
    final currentUserTypeInArabic = _getUserTypeInArabic(user.userType);
    final newUserType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير نوع المستخدم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المستخدم: ${user.fullName}'),
            Text('النوع الحالي: $currentUserTypeInArabic'),
            const SizedBox(height: 16),
            const Text('اختر النوع الجديد:'),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: currentUserTypeInArabic,
              isExpanded: true,
              items: ['مسؤول', 'مستخدم']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );

    if (newUserType != null && newUserType != currentUserTypeInArabic) {
      final confirmed = await CustomDialogs.showConfirmationDialog(
        context: context,
        title: 'تأكيد تغيير نوع المستخدم',
        content: 'هل تريد تغيير نوع المستخدم ${user.fullName} من "$currentUserTypeInArabic" إلى "$newUserType"؟',
        confirmText: 'تأكيد',
        cancelText: 'إلغاء',
      );

      if (confirmed == true) {
        try {
          final newUserTypeInEnglish = _getUserTypeInEnglish(newUserType);
          final updatedUser = user.copyWith(userType: newUserTypeInEnglish);
          await _firestoreService.updateUser(updatedUser);
          _loadUsers();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم تغيير نوع المستخدم إلى "$newUserType" بنجاح'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('خطأ في تغيير نوع المستخدم: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await CustomDialogs.showConfirmationDialog(
      context: context,
      title: 'حذف المستخدم',
      content: 'هل أنت متأكد من حذف المستخدم ${user.fullName}؟\n\nهذا الإجراء لا يمكن التراجع عنه!',
      confirmText: 'حذف',
      cancelText: 'إلغاء',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteUser(user.uid!);
        _loadUsers();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف المستخدم'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في حذف المستخدم: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showUserDetails(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'بيانات المستخدم',
          style: TextStyle(color: AppColors.primaryGreen),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              InfoCard(title: 'الاسم الكامل', value: user.fullName),
              InfoCard(title: 'اسم المستخدم', value: user.username),
              InfoCard(
                title: 'نوع المستخدم',
                value: _getUserTypeInArabic(user.userType),
                valueColor: user.userType == 'admin' 
                    ? AppColors.primaryGreen 
                    : AppColors.info,
              ),
              if (user.phoneNumber?.isNotEmpty == true)
                InfoCard(title: 'رقم الهاتف', value: user.phoneNumber!),
              InfoCard(
                title: 'تاريخ التسجيل',
                value: _formatDate(user.createdAt),
              ),
              if (user.lastLogin != null)
                InfoCard(
                  title: 'آخر تسجيل دخول',
                  value: _formatDateTime(user.lastLogin!),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _changeUserType(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
            ),
            child: const Text('تغيير النوع'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user);
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

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إدارة المستخدمين',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryWhite,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: AppColors.primaryWhite),
        actions: [
          IconButton(
            onPressed: _loadUsers,
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
                    hintText: 'البحث بالاسم أو اسم المستخدم...',
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
                
                // فلترة نوع المستخدم
                Row(
                  children: [
                    const Text(
                      'فلترة النوع: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _userTypeFilter,
                        isExpanded: true,
                        onChanged: (value) => _onUserTypeFilterChanged(value!),
                        items: ['الكل', 'مسؤول', 'مستخدم']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
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
              'إجمالي النتائج: ${_filteredUsers.length}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          
          // قائمة المستخدمين
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  )
                : _filteredUsers.isEmpty
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
                                  ? 'لا توجد بيانات مستخدمين'
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
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: user.userType == 'admin'
                                    ? AppColors.primaryGreen
                                    : AppColors.info,
                                child: Icon(
                                  user.userType == 'admin'
                                      ? Icons.admin_panel_settings
                                      : Icons.person,
                                  color: AppColors.primaryWhite,
                                ),
                              ),
                              title: Text(
                                user.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('اسم المستخدم: ${user.username}'),
                                  if (user.phoneNumber?.isNotEmpty == true)
                                    Text('الهاتف: ${user.phoneNumber}'),
                                  Text('تاريخ التسجيل: ${_formatDate(user.createdAt)}'),
                                  if (user.lastLogin != null)
                                    Text('آخر دخول: ${_formatDateTime(user.lastLogin!)}'),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: user.userType == 'admin'
                                          ? AppColors.primaryGreen.withOpacity(0.1)
                                          : AppColors.info.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      user.userType == 'admin' ? 'مسؤول 🛡️' : 'مستخدم 👤',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: user.userType == 'admin'
                                            ? AppColors.primaryGreen
                                            : AppColors.info,
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
                                      _showUserDetails(user);
                                      break;
                                    case 'change_type':
                                      _changeUserType(user);
                                      break;
                                    case 'delete':
                                      _deleteUser(user);
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
                                  const PopupMenuItem(
                                    value: 'change_type',
                                    child: ListTile(
                                      leading: Icon(Icons.swap_horiz),
                                      title: Text('تغيير النوع'),
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
                              onTap: () => _showUserDetails(user),
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
