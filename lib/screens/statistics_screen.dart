import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/statistics_service.dart';
import 'dart:math' as math;

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

// fl_chart data structures
class TimeSeriesPoint {
  final double x;
  final double y;
  TimeSeriesPoint(this.x, this.y);
}

class PieData {
  final String title;
  final double value;
  final Color color;
  PieData(this.title, this.value, this.color);
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  
  // الإحصائيات
  Map<String, dynamic> _quickStats = {};
  Map<String, dynamic> _timeStats = {};
  Map<String, dynamic> _geoStats = {};
  Map<String, dynamic> _analytics = {};
  
  bool _isLoading = true;
  String _selectedPeriod = 'month';
  String _selectedRegion = 'all';
  
  // الخدمات
  final StatisticsService _statisticsService = StatisticsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // تحميل الإحصائيات السريعة
      _quickStats = await _statisticsService.getQuickStats();
      
      // تحميل الإحصائيات الزمنية
      _timeStats = await _statisticsService.getTimeBasedStatistics(
        period: _selectedPeriod
      );
      
      // تحميل الإحصائيات الجغرافية
      _geoStats = await _statisticsService.getGeographicStatistics();
      
      // تحميل التحليل العميق
      _analytics = await _statisticsService.getDeepAnalytics();
      
    } catch (e) {
      print('خطأ في تحميل الإحصائيات: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      resizeToAvoidBottomInset: true, // لتجنب مشاكل التخطيط
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'الإحصائيات والتحليلات',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStatistics,
            tooltip: 'تحديث الإحصائيات',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('تصدير التقرير'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('إعدادات الإحصائيات'),
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
          isScrollable: true,
          tabs: const [
            Tab(text: 'نظرة عامة', icon: Icon(Icons.dashboard)),
            Tab(text: 'الزمن', icon: Icon(Icons.trending_up)),
            Tab(text: 'الجغرافيا', icon: Icon(Icons.map)),
            Tab(text: 'التحليل', icon: Icon(Icons.analytics)),
            Tab(text: 'التقارير', icon: Icon(Icons.bar_chart)),
          ],
        ),
      ),
      body: _isLoading 
          ? _buildLoadingView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTimeTab(),
                _buildGeographicTab(),
                _buildAnalyticsTab(),
                _buildReportsTab(),
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
            'جاري تحميل الإحصائيات...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickStatsGrid(),
            const SizedBox(height: 16),
            _buildTrendsCard(),
            const SizedBox(height: 16),
            _buildRecentActivityCard(),
            const SizedBox(height: 16),
            _buildStatusDistribution(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          'إجمالي السجلات',
          '${_quickStats['totalRecords'] ?? 0}',
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'أضيف اليوم',
          '${_quickStats['todayAdded'] ?? 0}',
          Icons.today,
          Colors.green,
        ),
        _buildStatCard(
          'في انتظار المراجعة',
          '${_quickStats['pendingReview'] ?? 0}',
          Icons.pending,
          Colors.orange,
        ),
        _buildStatCard(
          'المقبول',
          '${_quickStats['approved'] ?? 0}',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'الشهداء',
          '${_quickStats['martyrsCount'] ?? 0}',
          Icons.person,
          Colors.red,
        ),
        _buildStatCard(
          'الجرحى',
          '${_quickStats['injuredCount'] ?? 0}',
          Icons.healing,
          Colors.orange,
        ),
        _buildStatCard(
          'الأسرى',
          '${_quickStats['prisonersCount'] ?? 0}',
          Icons.lock,
          Colors.blue,
        ),
        _buildStatCard(
          'المفضلة',
          '${_quickStats['favoritesCount'] ?? 0}',
          Icons.favorite,
          Colors.pink,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsCard() {
    String trend = _timeStats['trend'] ?? 'stable';
    double growthRate = _timeStats['growthRate'] ?? 0.0;
    Color trendColor = _getTrendColor(trend);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTrendIcon(trend),
                  color: trendColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'اتجاه البيانات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${growthRate > 0 ? '+' : ''}${growthRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: trendColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getTrendDescription(trend),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: (growthRate.abs() * 10).round(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: trendColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'النشاط الحديث',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildRecentActivities(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecentActivities() {
    List<Widget> activities = [];
    
    // بيانات وهمية للعرض - في التطبيق الحقيقي ستأتي من قاعدة البيانات
    activities.addAll([
      _buildActivityItem('إضافة شهادة جديدة', 'أحمد محمد - عدن', 'منذ ساعتين'),
      _buildActivityItem('تحديث حالة', 'فاطمة علي - تعز', 'منذ 3 ساعات'),
      _buildActivityItem('موافقة على تسجيل', 'محمد أحمد - الحديدة', 'منذ 5 ساعات'),
    ]);
    
    return activities;
  }

  Widget _buildActivityItem(String title, String subtitle, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistribution() {
    int approved = _quickStats['approved'] ?? 0;
    int pending = _quickStats['pendingReview'] ?? 0;
    int rejected = _quickStats['rejected'] ?? 0;
    int total = approved + pending + rejected;
    
    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'توزيع الحالات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusBar('مقبول', approved, total, Colors.green),
            const SizedBox(height: 8),
            _buildStatusBar('في الانتظار', pending, total, Colors.orange),
            const SizedBox(height: 8),
            _buildStatusBar('مرفوض', rejected, total, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(String label, int count, int total, Color color) {
    double percentage = total > 0 ? (count / total) * 100 : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                flex: count,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Expanded(
                flex: total - count,
                child: const SizedBox(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          _buildTimeChart(),
          const SizedBox(height: 16),
          _buildTrendAnalysis(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر الفترة الزمنية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip('week', 'الأسبوع'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('month', 'الشهر'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('year', 'السنة'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('all', 'الكل'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String period, String label) {
    bool isSelected = _selectedPeriod == period;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPeriod = period;
        });
        _loadStatistics();
      },
      backgroundColor: Colors.grey[100],
      selectedColor: AppColors.primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryColor : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTimeChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'البيانات عبر الزمن',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    // بيانات وهمية للعرض - في التطبيق الحقيقي ستأتي من قاعدة البيانات
    final data = [
      TimeSeriesPoint(1, 10),
      TimeSeriesPoint(2, 25),
      TimeSeriesPoint(3, 15),
      TimeSeriesPoint(4, 30),
      TimeSeriesPoint(5, 20),
      TimeSeriesPoint(6, 35),
    ];

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: AxisSide.bottom,
                  child: Text('${value.toInt()}'),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: AxisSide.left,
                  child: Text('${value.toInt()}'),
                );
              },
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: AppColors.borderColor,
            width: 1,
          ),
        ),
        minX: 0,
        maxX: 7,
        minY: 0,
        maxY: 40,
        lineTouchData: LineTouchData(
          enabled: true,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data.map((point) => FlSpot(point.x, point.y)).toList(),
            isCurved: true,
            color: AppColors.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryColor.withOpacity(0.3),
                  AppColors.primaryColor.withOpacity(0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendAnalysis() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تحليل الاتجاه',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildTrendItem('الفترة الحالية', 'حالات جديدة', '45', Icons.arrow_upward, Colors.green),
            const SizedBox(height: 12),
            _buildTrendItem('من الشهر الماضي', 'مقارنة', '+12%', Icons.trending_up, Colors.blue),
            const SizedBox(height: 12),
            _buildTrendItem('التوقعات', 'الشهر القادم', '50 حالة', Icons.analytics, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(String title, String subtitle, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildGeographicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRegionSelector(),
          const SizedBox(height: 16),
          _buildGeographicChart(),
          const SizedBox(height: 16),
          _buildTopRegions(),
          const SizedBox(height: 16),
          _buildGeographicMap(),
        ],
      ),
    );
  }

  Widget _buildRegionSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.primaryColor),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'اختر المنطقة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            DropdownButton<String>(
              value: _selectedRegion,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('جميع المناطق')),
                DropdownMenuItem(value: 'gaza', child: Text('قطاع غزة')),
                DropdownMenuItem(value: 'west_bank', child: Text('الضفة الغربية')),
                DropdownMenuItem(value: 'jerusalem', child: Text('القدس الشريف')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRegion = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeographicChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'التوزيع الجغرافي',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 250,
              child: _buildPieChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    // بيانات وهمية للعرض
    final data = [
      PieData('عدن', 35, Colors.red),
      PieData('تعز', 25, Colors.blue),
      PieData('الحديدة', 20, Colors.green),
      PieData('محافظات أخرى', 20, Colors.orange),
    ];

    return PieChart(
      PieChartData(
        sections: data.map((item) => PieChartSectionData(
          color: item.color,
          value: item.value.toDouble(),
          title: '${item.value}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titlePositionPercentageOffset: 0.5,
        )).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        borderData: FlBorderData(
          show: false,
        ),
        pieTouchData: PieTouchData(
          enabled: true,
        ),
      ),
    );
  }

  Widget _buildTopRegions() {
    List<dynamic> topRegions = (_geoStats['topRegions'] ?? []) as List<dynamic>;
    
    if (topRegions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المناطق الأكثر تضرراً',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...topRegions.take(5).map((region) => 
              _buildRegionItem(
                region['region'] ?? 'غير محدد',
                region['count'] ?? 0,
                region['percentage'] ?? '0.0'
              )
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionItem(String name, int count, String percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$count حالة ($percentage%)',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeographicMap() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.map, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'الخريطة التفاعلية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'خريطة تفاعلية',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'سيتم عرض الخريطة التفاعلية هنا',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatternsCard(),
          const SizedBox(height: 16),
          _buildInsightsCard(),
          const SizedBox(height: 16),
          _buildPredictionsCard(),
          const SizedBox(height: 16),
          _buildCorrelationsCard(),
        ],
      ),
    );
  }

  Widget _buildPatternsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'الأنماط المكتشفة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPatternItem('الأنماط الزمنية', 'ذروة النشاط في أشهر معينة', 0.85),
            const SizedBox(height: 12),
            _buildPatternItem('الأنماط الجغرافية', 'تركيز في مناطق معينة', 0.72),
            const SizedBox(height: 12),
            _buildPatternItem('الأنماط الموسمية', 'تأثير الفصول على البيانات', 0.63),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternItem(String title, String description, double confidence) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Text(
              '${(confidence * 100).toInt()}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: (confidence * 60).round(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightsCard() {
    List<String> insights = _analytics['insights'] ?? [];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'رؤى ذكية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (insights.isEmpty)
              const Text('لا توجد رؤى متاحة حالياً')
            else
              ...insights.map((insight) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.arrow_right,
                        size: 16,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insight,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'التنبؤات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPredictionItem('الشهر القادم', 'زيادة متوقعة 15%', 0.75, Icons.trending_up),
            const SizedBox(height: 12),
            _buildPredictionItem('الربع القادم', 'استقرار متوقع', 0.68, Icons.trending_flat),
            const SizedBox(height: 12),
            _buildPredictionItem('النمو السنوي', 'زيادة 25% سنوياً', 0.82, Icons.analytics),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionItem(String period, String prediction, double confidence, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                period,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                prediction,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Text(
              '${(confidence * 100).toInt()}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: (confidence * 50).round(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCorrelationsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'الارتباطات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCorrelationItem('الموقع ↔ النوع', 0.65, 'ارتباط قوي'),
            const SizedBox(height: 12),
            _buildCorrelationItem('الوقت ↔ الموقع', 0.43, 'ارتباط متوسط'),
            const SizedBox(height: 12),
            _buildCorrelationItem('الخطورة ↔ الموقع', 0.58, 'ارتباط متوسط'),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrelationItem(String relation, double correlation, String strength) {
    Color color = correlation > 0.6 ? Colors.red : correlation > 0.4 ? Colors.orange : Colors.green;
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                relation,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                strength,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Text(
              (correlation * 100).toInt().toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: (correlation * 40).round(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportGenerator(),
          const SizedBox(height: 16),
          _buildCustomReports(),
          const SizedBox(height: 16),
          _buildScheduledReports(),
        ],
      ),
    );
  }

  Widget _buildReportGenerator() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'إنشاء تقرير مخصص',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'عنوان التقرير',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                hintText: 'نوع التقرير',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'summary', child: Text('تقرير شامل')),
                DropdownMenuItem(value: 'detailed', child: Text('تقرير مفصل')),
                DropdownMenuItem(value: 'analysis', child: Text('تقرير تحليلي')),
                DropdownMenuItem(value: 'comparison', child: Text('تقرير مقارن')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // إنشاء التقرير
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('إنشاء التقرير'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomReports() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'التقارير المحفوظة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildReportItem('تقرير شهري - أكتوبر 2025', 'منذ 3 أيام', Icons.pie_chart),
            const SizedBox(height: 8),
            _buildReportItem('تحليل المناطق -秋季 2025', 'منذ أسبوع', Icons.bar_chart),
            const SizedBox(height: 8),
            _buildReportItem('إحصائيات شهرية - سبتمبر', 'منذ شهر', Icons.analytics),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(String title, String date, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryColor),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(date),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleReportAction(value),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'view',
            child: ListTile(
              leading: Icon(Icons.visibility),
              title: Text('عرض'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'download',
            child: ListTile(
              leading: Icon(Icons.download),
              title: Text('تحميل'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete),
              title: Text('حذف'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledReports() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'التقارير المجدولة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('تقرير أسبوعي'),
              subtitle: const Text('يتم إرساله كل يوم أحد'),
              value: true,
              onChanged: (value) {},
              activeColor: AppColors.primaryColor,
            ),
            SwitchListTile(
              title: const Text('تقرير شهري'),
              subtitle: const Text('يتم إرساله في بداية كل شهر'),
              value: false,
              onChanged: (value) {},
              activeColor: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // وظائف مساعدة

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportStatistics();
        break;
      case 'settings':
        _showSettingsDialog();
        break;
    }
  }

  void _handleReportAction(String action) {
    switch (action) {
      case 'view':
        // عرض التقرير
        break;
      case 'download':
        // تحميل التقرير
        break;
      case 'delete':
        // حذف التقرير
        break;
    }
  }

  void _exportStatistics() {
    // تصدير الإحصائيات
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تصدير الإحصائيات بنجاح'),
        backgroundColor: AppColors.accentColor,
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعدادات الإحصائيات'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('تحديث تلقائي كل 30 دقيقة'),
              trailing: Switch(value: true, onChanged: null),
            ),
            ListTile(
              title: Text('إشعارات التحليلات الجديدة'),
              trailing: Switch(value: true, onChanged: null),
            ),
            ListTile(
              title: Text('تصدير تلقائي للتقارير'),
              trailing: Switch(value: false, onChanged: null),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'increasing':
        return Colors.green;
      case 'decreasing':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'increasing':
        return Icons.trending_up;
      case 'decreasing':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  String _getTrendDescription(String trend) {
    switch (trend) {
      case 'increasing':
        return 'معدل البيانات في زيادة';
      case 'decreasing':
        return 'معدل البيانات في انخفاض';
      default:
        return 'معدل البيانات مستقر';
    }
  }
}

// فئات البيانات المساعدة
