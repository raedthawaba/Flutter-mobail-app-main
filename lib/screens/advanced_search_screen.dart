import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/advanced_search_service.dart';
import '../services/favorites_service.dart';
import '../models/martyr.dart';
import '../models/injured.dart';
import '../models/prisoner.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({Key? key}) : super(key: key);

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  
  // متغيرات البحث
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  
  // الفلاتر
  String? _selectedType;
  String? _selectedStatus;
  String? _selectedInjuryDegree;
  bool _includeFavorites = false;
  bool _showAdvancedFilters = false;
  
  // النتائج
  Map<String, dynamic> _searchResults = {};
  List<String> _recentSearches = [];
  List<String> _searchSuggestions = [];
  bool _isLoading = false;
  bool _hasResults = false;
  
  // الخدمات
  final AdvancedSearchService _searchService = AdvancedSearchService();
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await _searchService.initialize();
    await _favoritesService.initialize();
    _loadRecentSearches();
  }

  void _loadRecentSearches() {
    setState(() {
      _recentSearches = _searchService.getRecentSearches();
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
          'البحث المتقدم',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'البحث', icon: Icon(Icons.search)),
            Tab(text: 'النتائج', icon: Icon(Icons.list_alt)),
            Tab(text: 'الاحصائيات', icon: Icon(Icons.analytics)),
            Tab(text: 'الفلاتر', icon: Icon(Icons.filter_list)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildResultsTab(),
          _buildStatisticsTab(),
          _buildFiltersTab(),
        ],
      ),
      floatingActionButton: _hasResults ? _buildFloatingActionButton() : null,
    );
  }

  Widget _buildSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchCard(),
          const SizedBox(height: 16),
          _buildQuickFilters(),
          const SizedBox(height: 16),
          _buildRecentSearches(),
          const SizedBox(height: 16),
          _buildPopularSuggestions(),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'البحث السريع',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن الأسماء، الأماكن، التاريخ...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
                ),
              ),
              textDirection: TextDirection.rtl,
              onChanged: (value) {
                if (value.length > 2) {
                  _updateSuggestions(value);
                } else {
                  setState(() {
                    _searchSuggestions.clear();
                  });
                }
              },
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _performSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('بحث', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showAdvancedFilters ? null : () {
                      _tabController.animateTo(3); // انتقل لتبويب الفلاتر
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('فلاتر متقدمة', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
            if (_searchSuggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSearchSuggestions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_alt, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'فلاتر سريعة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickFilterChip(AppConstants.sectionMartyrs, Icons.person, 'martyrs'),
                _buildQuickFilterChip(AppConstants.sectionInjured, Icons.healing, 'injured'),
                _buildQuickFilterChip(AppConstants.sectionPrisoners, Icons.lock, 'prisoners'),
                _buildQuickFilterChip(AppConstants.sectionFavorites, Icons.favorite, 'favorites'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, IconData icon, String type) {
    bool isSelected = _selectedType == type;
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primaryColor),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = selected ? type : null;
        });
        _performSearch();
      },
      backgroundColor: Colors.grey[100],
      selectedColor: AppColors.primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryColor : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: AppColors.primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'عمليات البحث الأخيرة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.clear_all, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchService.clearRecentSearches();
                    _loadRecentSearches();
                  },
                  tooltip: 'مسح جميع عمليات البحث',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.take(5).map((search) {
                return ActionChip(
                  label: Text(search),
                  onPressed: () {
                    _searchController.text = search;
                    _performSearch();
                  },
                  backgroundColor: Colors.grey[100],
                  labelStyle: const TextStyle(color: AppColors.textPrimary),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularSuggestions() {
    List<String> popularTerms = AppConstants.yemenGovernorates.take(6).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'البحثات الشائعة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: popularTerms.map((term) {
                return ActionChip(
                  label: Text(term),
                  onPressed: () {
                    _searchController.text = term;
                    _performSearch();
                  },
                  backgroundColor: Colors.blue[50],
                  labelStyle: const TextStyle(color: Colors.blue),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _searchSuggestions.map((suggestion) {
          return ListTile(
            leading: const Icon(Icons.search, color: AppColors.textSecondary),
            title: Text(suggestion),
            onTap: () {
              _searchController.text = suggestion;
              setState(() {
                _searchSuggestions.clear();
              });
              _performSearch();
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري البحث...'),
          ],
        ),
      );
    }

    if (!_hasResults) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد نتائج',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'استخدم علامات البحث أو الفلاتر للعثور على النتائج',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _performSearch();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsSummary(),
          const SizedBox(height: 16),
          _buildResultsTabs(),
        ],
      ),
    );
  }

  Widget _buildResultsSummary() {
    int totalResults = _searchResults['total'] ?? 0;
    
    return Card(
      color: AppColors.primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.analytics, color: AppColors.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalResults نتيجة',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  Text(
                    'تم العثور على النتائج في ${_searchResults['searchTime'] ?? '0.1'} ثانية',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.sort, color: AppColors.primaryColor),
              onPressed: () => _showSortDialog(),
              tooltip: 'ترتيب النتائج',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsTabs() {
    return Column(
      children: [
        TabBar(
          controller: TabController(length: 3, vsync: this),
          indicatorColor: AppColors.primaryColor,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'الشهداء'),
            Tab(text: 'الجرحى'),
            Tab(text: 'الأسرى'),
          ],
        ),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: TabController(length: 3, vsync: this),
            children: [
              _buildResultsList('martyrs'),
              _buildResultsList('injured'),
              _buildResultsList('prisoners'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsList(String type) {
    List<dynamic> results = _searchResults[type] ?? [];
    
    if (results.isEmpty) {
      return const Center(
        child: Text('لا توجد نتائج'),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return _buildResultCard(results[index], type);
      },
    );
  }

  Widget _buildResultCard(dynamic result, String type) {
    String title = 'غير محدد';
    String subtitle = 'غير محدد';
    String status = '';
    dynamic itemId;
    
    // تحديد نوع البيانات والوصول للحقول المناسبة
    if (result is Martyr) {
      title = result.fullName ?? 'غير محدد';
      subtitle = result.deathPlace ?? 'غير محدد';
      status = result.status ?? '';
      itemId = result.id;
    } else if (result is Injured) {
      title = result.fullName ?? 'غير محدد';
      subtitle = result.injuryPlace ?? 'غير محدد';
      status = result.status ?? '';
      itemId = result.id;
    } else if (result is Prisoner) {
      title = result.fullName ?? 'غير محدد';
      subtitle = result.capturePlace ?? 'غير محدد';
      status = result.status ?? '';
      itemId = result.id;
    }
    
    Color statusColor = _getStatusColor(status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(type),
          child: Icon(
            _getTypeIcon(type),
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: () => _toggleFavorite(itemId, type),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () => _viewDetails(result, type),
            ),
          ],
        ),
        onTap: () => _viewDetails(result, type),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 64,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'إحصائيات البحث',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ستظهر هنا إحصائيات مفصلة عن نتائج البحث',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterSection('نوع السجل', _buildTypeFilter()),
          const SizedBox(height: 16),
          _buildFilterSection('الموقع', _buildLocationFilter()),
          const SizedBox(height: 16),
          _buildFilterSection('التاريخ', _buildDateFilter()),
          const SizedBox(height: 16),
          _buildFilterSection('الحالة', _buildStatusFilter()),
          const SizedBox(height: 16),
          _buildFilterSection('درجة الإصابة', _buildInjuryDegreeFilter()),
          const SizedBox(height: 16),
          _buildAdvancedOptions(),
          const SizedBox(height: 24),
          _buildApplyFiltersButton(),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget child) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: InputDecoration(
        hintText: 'اختر نوع السجل',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: [
        DropdownMenuItem(value: null, child: const Text('جميع الأنواع')),
        DropdownMenuItem(value: 'martyrs', child: const Text(AppConstants.sectionMartyrs)),
        DropdownMenuItem(value: 'injured', child: const Text(AppConstants.sectionInjured)),
        DropdownMenuItem(value: 'prisoners', child: const Text(AppConstants.sectionPrisoners)),
      ],
      onChanged: (value) {
        setState(() {
          _selectedType = value;
        });
      },
    );
  }

  Widget _buildLocationFilter() {
    return TextFormField(
      controller: _locationController,
      decoration: InputDecoration(
        hintText: 'ادخل الموقع',
        prefixIcon: const Icon(Icons.location_on, color: AppColors.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textDirection: TextDirection.rtl,
    );
  }

  Widget _buildDateFilter() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _dateFromController,
            decoration: InputDecoration(
              hintText: 'من تاريخ',
              prefixIcon: const Icon(Icons.date_range, color: AppColors.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            readOnly: true,
            onTap: () => _selectDate('from'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _dateToController,
            decoration: InputDecoration(
              hintText: 'إلى تاريخ',
              prefixIcon: const Icon(Icons.date_range, color: AppColors.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            readOnly: true,
            onTap: () => _selectDate('to'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: InputDecoration(
        hintText: 'اختر الحالة',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: [
        DropdownMenuItem(value: null, child: const Text('جميع الحالات')),
        DropdownMenuItem(value: AppConstants.statusPending, child: const Text(AppConstants.statusPending)),
        DropdownMenuItem(value: AppConstants.statusApproved, child: const Text(AppConstants.statusApproved)),
        DropdownMenuItem(value: AppConstants.statusRejected, child: const Text(AppConstants.statusRejected)),
      ],
      onChanged: (value) {
        setState(() {
          _selectedStatus = value;
        });
      },
    );
  }

  Widget _buildInjuryDegreeFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedInjuryDegree,
      decoration: InputDecoration(
        hintText: 'اختر درجة الإصابة',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: [
        DropdownMenuItem(value: null, child: const Text('جميع الدرجات')),
        ...AppConstants.injuryDegrees.map((degree) =>
          DropdownMenuItem(value: degree, child: Text(degree))),
      ],
      onChanged: (value) {
        setState(() {
          _selectedInjuryDegree = value;
        });
      },
    );
  }

  Widget _buildAdvancedOptions() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'خيارات متقدمة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('تضمين المفضلة فقط'),
              value: _includeFavorites,
              onChanged: (value) {
                setState(() {
                  _includeFavorites = value;
                });
              },
              activeColor: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyFiltersButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _applyFilters,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('تطبيق الفلاتر', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showExportDialog,
      backgroundColor: AppColors.accentColor,
      child: const Icon(Icons.download, color: Colors.white),
      tooltip: 'تصدير النتائج',
    );
  }

  // الوظائف الأساسية
  
  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty && 
        _selectedType == null && 
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال كلمات البحث أو اختيار فلاتر'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final startTime = DateTime.now();
      
      _searchResults = await _searchService.searchWithFilters(
        query: _searchController.text.trim(),
        type: _selectedType,
        location: _locationController.text.trim(),
        dateFrom: _dateFromController.text.isNotEmpty ? _dateFromController.text : null,
        dateTo: _dateToController.text.isNotEmpty ? _dateToController.text : null,
        status: _selectedStatus,
        injuryDegree: _selectedInjuryDegree,
        isFavorite: _includeFavorites,
      );

      final endTime = DateTime.now();
      final searchTime = (endTime.difference(startTime).inMilliseconds / 1000).toStringAsFixed(2);
      
      setState(() {
        _searchResults['searchTime'] = searchTime;
        _hasResults = _searchResults['hasResults'] ?? false;
        _isLoading = false;
      });

      // حفظ البحث في العمليات الحديثة
      if (_searchController.text.isNotEmpty) {
        await _searchService.saveRecentSearch(_searchController.text.trim());
        _loadRecentSearches();
      }

      // الانتقال لتبويب النتائج إذا كانت هناك نتائج
      if (_hasResults) {
        _tabController.animateTo(1);
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في البحث: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateSuggestions(String query) {
    setState(() {
      _searchSuggestions = _searchService.getSearchSuggestions(query);
    });
  }

  void _applyFilters() {
    _performSearch();
    _tabController.animateTo(1);
  }

  Future<void> _selectDate(String type) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ar', 'SA'),
    );

    if (picked != null) {
      String formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      
      setState(() {
        if (type == 'from') {
          _dateFromController.text = formatted;
        } else {
          _dateToController.text = formatted;
        }
      });
    }
  }

  Future<void> _toggleFavorite(String id, String type) async {
    bool isFav = _favoritesService.isFavorite(type, id);
    bool success;
    
    if (isFav) {
      success = await _favoritesService.removeFromFavorites(type, id);
    } else {
      success = await _favoritesService.addToFavorites(type, id);
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFav ? 'تم الحذف من المفضلة' : 'تم الإضافة للمفضلة'),
          backgroundColor: AppColors.accentColor,
        ),
      );
    }
  }

  void _viewDetails(dynamic result, String type) {
    // فتح تفاصيل السجل
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('عرض تفاصيل: ${result['name']}')),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ترتيب النتائج'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('الاسم'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('التاريخ'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('الموقع'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدير النتائج'),
        content: const Text('هل تريد تصدير النتائج في ملف؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportResults();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('تصدير'),
          ),
        ],
      ),
    );
  }

  void _exportResults() {
    // تصدير النتائج
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تصدير النتائج بنجاح'),
        backgroundColor: AppColors.accentColor,
      ),
    );
  }

  // وظائف مساعدة
  
  Color _getTypeColor(String type) {
    switch (type) {
      case 'martyrs':
        return Colors.red;
      case 'injured':
        return Colors.orange;
      case 'prisoners':
        return Colors.blue;
      default:
        return AppColors.primaryColor;
    }
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

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusApproved:
        return Colors.green;
      case AppConstants.statusPending:
        return Colors.orange;
      case AppConstants.statusRejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
