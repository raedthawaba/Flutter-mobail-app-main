import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/favorites_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  
  // البيانات
  Map<String, int> _favoritesCount = {};
  Map<String, List<String>> _favorites = {
    'martyrs': [],
    'injured': [],
    'prisoners': [],
  };
  
  // حالة الواجهة
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'name', 'type'
  bool _isGridView = false;
  
  // الخدمات
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _favoritesService.initialize();
      _favoritesCount = _favoritesService.getFavoritesCount();
      _favorites = {
        'martyrs': _favoritesService.getFavorites('martyrs'),
        'injured': _favoritesService.getFavorites('injured'),
        'prisoners': _favoritesService.getFavorites('prisoners'),
      };
    } catch (e) {
      print('خطأ في تحميل المفضلة: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'المفضلة السريع',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
            tooltip: 'بحث في المفضلة',
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'عرض القائمة' : 'عرض الشبكة',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sort_date',
                child: ListTile(
                  leading: Icon(Icons.date_range),
                  title: Text('ترتيب حسب التاريخ'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'sort_name',
                child: ListTile(
                  leading: Icon(Icons.sort_by_alpha),
                  title: Text('ترتيب حسب الاسم'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('تصدير المفضلة'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep),
                  title: Text('مسح جميع المفضلة'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            _buildFavoriteTab('الكل', Icons.favorite, _getTotalFavorites(), 0),
            _buildFavoriteTab(AppConstants.sectionMartyrs, Icons.person, _favoritesCount['martyrs'] ?? 0, 1),
            _buildFavoriteTab(AppConstants.sectionInjured, Icons.healing, _favoritesCount['injured'] ?? 0, 2),
            _buildFavoriteTab(AppConstants.sectionPrisoners, Icons.lock, _favoritesCount['prisoners'] ?? 0, 3),
          ],
        ),
      ),
      body: _isLoading 
          ? _buildLoadingView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllFavoritesTab(),
                _buildFavoritesTab('martyrs', AppConstants.sectionMartyrs, Icons.person, Colors.red),
                _buildFavoritesTab('injured', AppConstants.sectionInjured, Icons.healing, Colors.orange),
                _buildFavoritesTab('prisoners', AppConstants.sectionPrisoners, Icons.lock, Colors.blue),
              ],
            ),
      floatingActionButton: _hasAnyFavorites() ? _buildFloatingActionButton() : null,
    );
  }

  Widget _buildFavoriteTab(String title, IconData icon, int count, int index) {
    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (count > 0) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
          const SizedBox(height: 16),
          const Text(
            'جاري تحميل المفضلة...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllFavoritesTab() {
    if (!_hasAnyFavorites()) {
      return _buildEmptyView('لا توجد عناصر مفضلة', 'اضغط على زر المفضلة في أي سجل لإضافته هنا');
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildQuickStats(),
          const SizedBox(height: 16),
          ..._buildAllFavoritesSections(),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab(String type, String title, IconData icon, Color color) {
    List<String> items = _favorites[type] ?? [];
    
    if (items.isEmpty) {
      return _buildEmptyView('لا توجد عناصر مفضلة', 'لا يوجد $title في المفضلة بعد');
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: _isGridView 
          ? _buildGridView(items, type, color)
          : _buildListView(items, type, icon, color),
    );
  }

  Widget _buildQuickStats() {
    int total = _getTotalFavorites();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor.withOpacity(0.1),
              AppColors.accentColor.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$total عنصر مفضل',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تم حفظهم لسهولة الوصول السريع',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'VIP',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAllFavoritesSections() {
    List<Widget> sections = [];
    
    // قسم الشهداء
    if ((_favorites['martyrs'] ?? []).isNotEmpty) {
      sections.add(_buildSectionHeader(AppConstants.sectionMartyrs, Icons.person, Colors.red, _favorites['martyrs']!.length));
      sections.add(const SizedBox(height: 8));
      sections.addAll(_buildFavoritesPreview('martyrs', _favorites['martyrs']!, Colors.red));
      sections.add(const SizedBox(height: 16));
    }
    
    // قسم الجرحى
    if ((_favorites['injured'] ?? []).isNotEmpty) {
      sections.add(_buildSectionHeader(AppConstants.sectionInjured, Icons.healing, Colors.orange, _favorites['injured']!.length));
      sections.add(const SizedBox(height: 8));
      sections.addAll(_buildFavoritesPreview('injured', _favorites['injured']!, Colors.orange));
      sections.add(const SizedBox(height: 16));
    }
    
    // قسم الأسرى
    if ((_favorites['prisoners'] ?? []).isNotEmpty) {
      sections.add(_buildSectionHeader(AppConstants.sectionPrisoners, Icons.lock, Colors.blue, _favorites['prisoners']!.length));
      sections.add(const SizedBox(height: 8));
      sections.addAll(_buildFavoritesPreview('prisoners', _favorites['prisoners']!, Colors.blue));
      sections.add(const SizedBox(height: 16));
    }
    
    return sections;
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, int count) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFavoritesPreview(String type, List<String> items, Color color) {
    return items.take(3).map((item) => 
      _buildFavoritePreviewItem(type, item, color)
    ).toList();
  }

  Widget _buildFavoritePreviewItem(String type, String id, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(
            _getTypeIcon(type),
            color: Colors.white,
          ),
        ),
        title: Text(_getSampleName(id)),
        subtitle: Text(_getSampleLocation(id)),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle, color: Colors.red),
          onPressed: () => _removeFromFavorites(type, id),
          tooltip: 'إزالة من المفضلة',
        ),
        onTap: () => _viewDetails(type, id),
      ),
    );
  }

  Widget _buildListView(List<String> items, String type, IconData icon, Color color) {
    List<String> filteredItems = items.where((id) => 
      _searchQuery.isEmpty || _getSampleName(id).toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        String id = filteredItems[index];
        return _buildFavoriteItem(id, type, icon, color);
      },
    );
  }

  Widget _buildGridView(List<String> items, String type, Color color) {
    List<String> filteredItems = items.where((id) => 
      _searchQuery.isEmpty || _getSampleName(id).toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        String id = filteredItems[index];
        return _buildFavoriteGridItem(id, type, color);
      },
    );
  }

  Widget _buildFavoriteItem(String id, String type, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          _getSampleName(id),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _getSampleLocation(id),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _getSampleDate(id),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          onSelected: (value) => _handleItemAction(value, type, id),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('عرض التفاصيل'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: ListTile(
                leading: Icon(Icons.remove_circle, color: Colors.red),
                title: Text('إزالة من المفضلة'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _viewDetails(type, id),
      ),
    );
  }

  Widget _buildFavoriteGridItem(String id, String type, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _viewDetails(type, id),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTypeIcon(type),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _getSampleName(id),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                _getSampleLocation(id),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getSampleStatus(id),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: AppColors.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('إضافة عناصر'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _shareFavorites(),
      backgroundColor: AppColors.accentColor,
      icon: const Icon(Icons.share),
      label: const Text('مشاركة'),
      tooltip: 'مشاركة المفضلة',
    );
  }

  // الوظائف الأساسية

  Future<void> _removeFromFavorites(String type, String id) async {
    bool success = await _favoritesService.removeFromFavorites(type, id);
    
    if (success) {
      setState(() {
        _favorites[type]!.remove(id);
        _favoritesCount = _favoritesService.getFavoritesCount();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف العنصر من المفضلة'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _viewDetails(String type, String id) {
    // فتح تفاصيل السجل
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('عرض تفاصيل: ${_getSampleName(id)}')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'sort_date':
        _sortFavorites('date');
        break;
      case 'sort_name':
        _sortFavorites('name');
        break;
      case 'export':
        _exportFavorites();
        break;
      case 'clear_all':
        _clearAllFavorites();
        break;
    }
  }

  void _handleItemAction(String action, String type, String id) {
    switch (action) {
      case 'view':
        _viewDetails(type, id);
        break;
      case 'remove':
        _removeFromFavorites(type, id);
        break;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بحث في المفضلة'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'ابحث بالاسم أو الموقع...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text('مسح'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('بحث'),
          ),
        ],
      ),
    );
  }

  void _sortFavorites(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
    
    // منطق الترتيب
    // في التطبيق الحقيقي ستربط بقاعدة البيانات
  }

  void _exportFavorites() {
    // تصدير المفضلة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تصدير المفضلة بنجاح'),
        backgroundColor: AppColors.accentColor,
      ),
    );
  }

  Future<void> _clearAllFavorites() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح جميع المفضلة'),
        content: const Text('هل أنت متأكد من حذف جميع العناصر من المفضلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _favoritesService.clearAllFavorites();
      setState(() {
        _favorites = {
          'martyrs': [],
          'injured': [],
          'prisoners': [],
        };
        _favoritesCount = _favoritesService.getFavoritesCount();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم مسح جميع المفضلة'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareFavorites() {
    // مشاركة المفضلة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم مشاركة المفضلة بنجاح'),
        backgroundColor: AppColors.accentColor,
      ),
    );
  }

  // وظائف مساعدة

  int _getTotalFavorites() {
    return _favoritesCount.values.fold(0, (sum, count) => sum + count);
  }

  bool _hasAnyFavorites() {
    return _getTotalFavorites() > 0;
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'martyrs':
        return Icons.person;
      case 'injured':
        return Icons.healing;
      case 'prisoners':
        return Icons.lock;
      default:
        return Icons.help;
    }
  }

  // بيانات وهمية للعرض - في التطبيق الحقيقي ستأتي من قاعدة البيانات
  String _getSampleName(String id) {
    Map<String, String> sampleNames = {
      'martyr_1': 'أحمد محمد',
      'martyr_2': 'فاطمة علي',
      'injured_1': 'محمد أحمد',
      'injured_2': 'عائشة محمد',
      'prisoner_1': 'خالد أحمد',
      'prisoner_2': 'نورا علي',
    };
    return sampleNames[id] ?? 'غير محدد';
  }

  String _getSampleLocation(String id) {
    Map<String, String> sampleLocations = {
      'martyr_1': 'القدس الشريف',
      'martyr_2': 'قطاع غزة',
      'injured_1': 'طولكرم',
      'injured_2': 'نابلس',
      'prisoner_1': 'بيت لحم',
      'prisoner_2': 'قلقيلية',
    };
    return sampleLocations[id] ?? 'غير محدد';
  }

  String _getSampleDate(String id) {
    Map<String, String> sampleDates = {
      'martyr_1': '2025-01-15',
      'martyr_2': '2025-02-20',
      'injured_1': '2025-03-10',
      'injured_2': '2025-04-05',
      'prisoner_1': '2025-05-12',
      'prisoner_2': '2025-06-18',
    };
    return sampleDates[id] ?? '2025-01-01';
  }

  String _getSampleStatus(String id) {
    Map<String, String> sampleStatuses = {
      'martyr_1': AppConstants.statusApproved,
      'martyr_2': AppConstants.statusPending,
      'injured_1': AppConstants.statusApproved,
      'injured_2': AppConstants.statusPending,
      'prisoner_1': AppConstants.statusApproved,
      'prisoner_2': AppConstants.statusRejected,
    };
    return sampleStatuses[id] ?? AppConstants.statusPending;
  }
}
