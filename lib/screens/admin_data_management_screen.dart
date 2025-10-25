import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/martyr.dart';
import '../models/injured.dart';
import '../models/prisoner.dart';
import '../services/database_service.dart';
import '../widgets/custom_dialogs.dart';

class AdminDataManagementScreen extends StatefulWidget {
  const AdminDataManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminDataManagementScreen> createState() => _AdminDataManagementScreenState();
}

class _AdminDataManagementScreenState extends State<AdminDataManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _dbService = DatabaseService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addSampleMartyrs() async {
    final confirmed = await CustomDialogs.showConfirmationDialog(
      context: context,
      title: 'إضافة بيانات تجريبية للشهداء',
      content: 'هل تريد إضافة 10 شهداء كبيانات تجريبية للاختبار؟',
      confirmText: 'إضافة',
      cancelText: 'إلغاء',
    );

    if (confirmed == true) {
      try {
        final sampleMartyrs = [
          Martyr(
            fullName: 'أحمد محمد الشهيد',
            nickname: 'أبو محمد',
            tribe: 'قبيلة الأنصار',
            birthDate: DateTime(1990, 5, 15),
            deathDate: DateTime(2023, 10, 7),
            deathPlace: 'غزة',
            causeOfDeath: 'قصف جوي',
            rankOrPosition: 'مقاتل',
            participationFronts: 'جبهة غزة',
            familyStatus: 'متزوج',
            numChildren: 3,
            contactFamily: '0599123456',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
          Martyr(
            fullName: 'فاطمة علي الشهيدة',
            nickname: 'أم يوسف',
            tribe: 'قبيلة الخزرج',
            birthDate: DateTime(1985, 8, 20),
            deathDate: DateTime(2023, 11, 15),
            deathPlace: 'الضفة الغربية',
            causeOfDeath: 'رصاص قناص',
            familyStatus: 'متزوجة',
            numChildren: 2,
            contactFamily: '0598765432',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
          Martyr(
            fullName: 'محمد أحمد الفدائي',
            nickname: 'أبو العز',
            tribe: 'قبيلة الأوس',
            birthDate: DateTime(1995, 2, 10),
            deathDate: DateTime(2024, 1, 3),
            deathPlace: 'القدس',
            causeOfDeath: 'عملية فدائية',
            rankOrPosition: 'مجاهد',
            participationFronts: 'جبهة القدس',
            familyStatus: 'أعزب',
            numChildren: 0,
            contactFamily: '0597654321',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
          Martyr(
            fullName: 'خديجة سالم الشهيدة',
            tribe: 'قبيلة بني هاشم',
            birthDate: DateTime(1992, 12, 5),
            deathDate: DateTime(2024, 2, 14),
            deathPlace: 'رفح',
            causeOfDeath: 'قصف مدفعي',
            familyStatus: 'متزوجة',
            numChildren: 1,
            contactFamily: '0596543210',
            addedByUserId: '1',
            status: 'قيد المراجعة',
            createdAt: DateTime.now(),
          ),
          Martyr(
            fullName: 'عبد الرحمن يوسف الشهيد',
            nickname: 'أبو يوسف',
            tribe: 'قبيلة قريش',
            birthDate: DateTime(1988, 7, 25),
            deathDate: DateTime(2024, 3, 20),
            deathPlace: 'خان يونس',
            causeOfDeath: 'انهيار منزل',
            rankOrPosition: 'طبيب',
            familyStatus: 'متزوج',
            numChildren: 4,
            contactFamily: '0595432109',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
          Martyr(
            fullName: 'نور الدين عبد الله',
            tribe: 'قبيلة الأزد',
            birthDate: DateTime(1993, 11, 30),
            deathDate: DateTime(2024, 4, 8),
            deathPlace: 'جنين',
            causeOfDeath: 'اشتباك مسلح',
            rankOrPosition: 'مهندس',
            participationFronts: 'جبهة الضفة',
            familyStatus: 'أعزب',
            numChildren: 0,
            contactFamily: '0594321098',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
          Martyr(
            fullName: 'أمينة حسن الشهيدة',
            tribe: 'قبيلة تميم',
            birthDate: DateTime(1987, 4, 18),
            deathDate: DateTime(2024, 5, 12),
            deathPlace: 'نابلس',
            causeOfDeath: 'قنبلة يدوية',
            familyStatus: 'متزوجة',
            numChildren: 3,
            contactFamily: '0593210987',
            addedByUserId: '1',
            status: 'قيد المراجعة',
            createdAt: DateTime.now(),
          ),
          Martyr(
            fullName: 'حسام الدين محمد',
            nickname: 'أبو حمزة',
            tribe: 'قبيلة كنانة',
            birthDate: DateTime(1991, 9, 8),
            deathDate: DateTime(2024, 6, 17),
            deathPlace: 'الخليل',
            causeOfDeath: 'صاروخ موجه',
            rankOrPosition: 'معلم',
            familyStatus: 'متزوج',
            numChildren: 2,
            contactFamily: '0592109876',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
          Martyr(
            fullName: 'زينب أحمد الشهيدة',
            tribe: 'قبيلة عدنان',
            birthDate: DateTime(1996, 1, 22),
            deathDate: DateTime(2024, 7, 25),
            deathPlace: 'بيت لحم',
            causeOfDeath: 'رصاص مطاطي',
            familyStatus: 'أعزب',
            numChildren: 0,
            contactFamily: '0591098765',
            addedByUserId: '1',
            status: 'مرفوض',
            createdAt: DateTime.now(),
          ),
          Martyr(
            fullName: 'إبراهيم سليم الشهيد',
            nickname: 'أبو سليم',
            tribe: 'قبيلة مضر',
            birthDate: DateTime(1989, 6, 14),
            deathDate: DateTime(2024, 8, 30),
            deathPlace: 'رام الله',
            causeOfDeath: 'تفجير سيارة',
            rankOrPosition: 'صحفي',
            participationFronts: 'جبهة الإعلام',
            familyStatus: 'متزوج',
            numChildren: 5,
            contactFamily: '0590987654',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
        ];

        for (final martyr in sampleMartyrs) {
          await _dbService.insertMartyr(martyr);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة 10 شهداء كبيانات تجريبية بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في إضافة البيانات: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _addSampleInjured() async {
    final confirmed = await CustomDialogs.showConfirmationDialog(
      context: context,
      title: 'إضافة بيانات تجريبية للجرحى',
      content: 'هل تريد إضافة 10 جرحى كبيانات تجريبية للاختبار؟',
      confirmText: 'إضافة',
      cancelText: 'إلغاء',
    );

    if (confirmed == true) {
      try {
        final sampleInjured = [
          Injured(
            fullName: 'سامر محمد الجريح',
            tribe: 'قبيلة الأنصار',
            injuryDate: DateTime(2024, 1, 15),
            injuryPlace: 'غزة',
            injuryType: 'شظايا',
            injuryDescription: 'إصابة بشظايا في الساق اليمنى',
            injuryDegree: 'متوسطة',
            currentStatus: 'في المستشفى',
            hospitalName: 'مستشفى الشفاء',
            contactFamily: '0599111222',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
          Injured(
            fullName: 'ليلى أحمد الجريحة',
            tribe: 'قبيلة الخزرج',
            injuryDate: DateTime(2024, 2, 20),
            injuryPlace: 'الضفة الغربية',
            injuryType: 'رصاص',
            injuryDescription: 'إصابة برصاص في الكتف',
            injuryDegree: 'خفيفة',
            currentStatus: 'تماثل للشفاء',
            contactFamily: '0598222333',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
          Injured(
            fullName: 'عمر يوسف الجريح',
            tribe: 'قبيلة الأوس',
            injuryDate: DateTime(2024, 3, 10),
            injuryPlace: 'القدس',
            injuryType: 'حروق',
            injuryDescription: 'حروق من الدرجة الثانية في الوجه',
            injuryDegree: 'خطيرة',
            currentStatus: 'تحت العلاج',
            hospitalName: 'مستشفى المقاصد',
            contactFamily: '0597333444',
            addedByUserId: '1',
            status: 'قيد المراجعة',
            createdAt: DateTime.now(),
          ),
          Injured(
            fullName: 'هدى سالم الجريحة',
            tribe: 'قبيلة بني هاشم',
            injuryDate: DateTime(2024, 4, 5),
            injuryPlace: 'رفح',
            injuryType: 'كسور',
            injuryDescription: 'كسر في عظم الفخذ',
            injuryDegree: 'متوسطة',
            currentStatus: 'في المنزل',
            contactFamily: '0596444555',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
          Injured(
            fullName: 'خالد عبد الله الجريح',
            tribe: 'قبيلة قريش',
            injuryDate: DateTime(2024, 5, 18),
            injuryPlace: 'خان يونس',
            injuryType: 'جروح',
            injuryDescription: 'جروح عميقة في الذراع',
            injuryDegree: 'متوسطة',
            currentStatus: 'تماثل للشفاء',
            hospitalName: 'مستشفى ناصر',
            contactFamily: '0595555666',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
          Injured(
            fullName: 'مريم حسن الجريحة',
            tribe: 'قبيلة الأزد',
            injuryDate: DateTime(2024, 6, 22),
            injuryPlace: 'جنين',
            injuryType: 'ارتجاج',
            injuryDescription: 'ارتجاج في المخ',
            injuryDegree: 'حرجة',
            currentStatus: 'في المستشفى',
            hospitalName: 'مستشفى جنين',
            contactFamily: '0594666777',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
          Injured(
            fullName: 'يوسف محمود الجريح',
            tribe: 'قبيلة تميم',
            injuryDate: DateTime(2024, 7, 8),
            injuryPlace: 'نابلس',
            injuryType: 'شظايا',
            injuryDescription: 'شظايا متعددة في الجسم',
            injuryDegree: 'خطيرة',
            currentStatus: 'تحت العلاج',
            hospitalName: 'مستشفى رفيديا',
            contactFamily: '0593777888',
            addedByUserId: '1',
            status: 'قيد المراجعة',
            createdAt: DateTime.now(),
          ),
          Injured(
            fullName: 'فاديا أحمد الجريحة',
            tribe: 'قبيلة كنانة',
            injuryDate: DateTime(2024, 8, 12),
            injuryPlace: 'الخليل',
            injuryType: 'رضوض',
            injuryDescription: 'رضوض في الصدر والبطن',
            injuryDegree: 'متوسطة',
            currentStatus: 'في المنزل',
            contactFamily: '0592888999',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
          Injured(
            fullName: 'محمود سليم الجريح',
            tribe: 'قبيلة عدنان',
            injuryDate: DateTime(2024, 9, 25),
            injuryPlace: 'بيت لحم',
            injuryType: 'حروق',
            injuryDescription: 'حروق من الدرجة الأولى',
            injuryDegree: 'خفيفة',
            currentStatus: 'تماثل للشفاء',
            contactFamily: '0591999000',
            addedByUserId: '1',
            status: 'مرفوض',
            createdAt: DateTime.now(),
          ),
          Injured(
            fullName: 'نادية عبد الرحمن الجريحة',
            tribe: 'قبيلة مضر',
            injuryDate: DateTime(2024, 10, 1),
            injuryPlace: 'رام الله',
            injuryType: 'كسور',
            injuryDescription: 'كسر في الضلوع',
            injuryDegree: 'متوسطة',
            currentStatus: 'في المستشفى',
            hospitalName: 'مستشفى رام الله',
            contactFamily: '0590000111',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
        ];

        for (final injured in sampleInjured) {
          await _dbService.insertInjured(injured);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة 10 جرحى كبيانات تجريبية بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في إضافة البيانات: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _addSamplePrisoners() async {
    final confirmed = await CustomDialogs.showConfirmationDialog(
      context: context,
      title: 'إضافة بيانات تجريبية للأسرى',
      content: 'هل تريد إضافة 10 أسرى كبيانات تجريبية للاختبار؟',
      confirmText: 'إضافة',
      cancelText: 'إلغاء',
    );

    if (confirmed == true) {
      try {
        final samplePrisoners = [
          Prisoner(
            fullName: 'أسامة محمد الأسير',
            tribe: 'قبيلة الأنصار',
            captureDate: DateTime(2023, 6, 15),
            capturePlace: 'القدس',
            capturedBy: 'قوات الاحتلال',
            currentStatus: 'محتجز',
            familyContact: '0599000111',
            detentionPlace: 'سجن عوفر',
            notes: 'مقاومة الاحتلال - 5 سنوات',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
          Prisoner(
            fullName: 'رانيا أحمد الأسيرة',
            tribe: 'قبيلة الخزرج',
            captureDate: DateTime(2024, 1, 10),
            capturePlace: 'رام الله',
            capturedBy: 'قوات الاحتلال',
            currentStatus: 'محتجزة',
            familyContact: '0598111222',
            detentionPlace: 'سجن الدامون',
            notes: 'مشاركة في مظاهرة - سنتان',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
          Prisoner(
            fullName: 'عبد الله يوسف الأسير',
            tribe: 'قبيلة الأوس',
            captureDate: DateTime(2023, 9, 22),
            capturePlace: 'الخليل',
            capturedBy: 'قوات الاحتلال',
            currentStatus: 'محتجز',
            familyContact: '0597222333',
            detentionPlace: 'سجن النقب',
            notes: 'انتماء لحركة مقاومة - 10 سنوات',
            addedByUserId: '1',
            status: 'قيد المراجعة',
            createdAt: DateTime.now(),
          ),
          Prisoner(
            fullName: 'سميرة حسن الأسيرة',
            tribe: 'قبيلة بني هاشم',
            captureDate: DateTime(2024, 3, 8),
            capturePlace: 'نابلس',
            capturedBy: 'قوات الاحتلال',
            currentStatus: 'محتجزة',
            familyContact: '0596333444',
            detentionPlace: 'سجن هشارون',
            notes: 'مساعدة المقاومين - 3 سنوات',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
          Prisoner(
            fullName: 'كريم سالم الأسير',
            tribe: 'قبيلة قريش',
            captureDate: DateTime(2024, 5, 12),
            capturePlace: 'جنين',
            capturedBy: 'قوات الاحتلال',
            currentStatus: 'محتجز',
            familyContact: '0595444555',
            detentionPlace: 'سجن مجدو',
            notes: 'حيازة أسلحة - 7 سنوات',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
          Prisoner(
            fullName: 'هالة عبد الله الأسيرة',
            tribe: 'قبيلة الأزد',
            captureDate: DateTime(2023, 12, 3),
            capturePlace: 'غزة',
            capturedBy: 'قوات الاحتلال',
            currentStatus: 'محتجزة',
            familyContact: '0594555666',
            detentionPlace: 'سجن نيتسان',
            notes: 'تهريب أدوية - 4 سنوات',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
          Prisoner(
            fullName: 'ماجد محمود الأسير',
            tribe: 'قبيلة تميم',
            captureDate: DateTime(2022, 8, 17),
            capturePlace: 'بيت لحم',
            capturedBy: 'قوات الاحتلال',
            currentStatus: 'محتجز',
            familyContact: '0593666777',
            detentionPlace: 'سجن ريمون',
            notes: 'عملية فدائية - مؤبد',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
          Prisoner(
            fullName: 'لبنى أحمد الأسيرة',
            tribe: 'قبيلة كنانة',
            captureDate: DateTime(2024, 7, 20),
            capturePlace: 'طولكرم',
            capturedBy: 'قوات الاحتلال',
            currentStatus: 'محتجزة',
            familyContact: '0592777888',
            detentionPlace: 'سجن الدامون',
            notes: 'تحريض على مواقع التواصل - سنة واحدة',
            addedByUserId: '1',
            status: 'قيد المراجعة',
            createdAt: DateTime.now(),
          ),
          Prisoner(
            fullName: 'طارق سليم الأسير',
            tribe: 'قبيلة عدنان',
            captureDate: DateTime(2024, 2, 14),
            capturePlace: 'قلقيلية',
            capturedBy: 'قوات الاحتلال',
            currentStatus: 'محتجز',
            familyContact: '0591888999',
            detentionPlace: 'سجن عوفر',
            notes: 'تمويل المقاومة - 6 سنوات',
            addedByUserId: '1',
            status: 'مرفوض',
            createdAt: DateTime.now(),
          ),
          Prisoner(
            fullName: 'علياء حسام الأسيرة',
            tribe: 'قبيلة مضر',
            captureDate: DateTime(2024, 4, 28),
            capturePlace: 'سلفيت',
            capturedBy: 'قوات الاحتلال',
            currentStatus: 'محتجزة',
            familyContact: '0590999000',
            detentionPlace: 'سجن هشارون',
            notes: 'مساعدة في الهروب - 8 سنوات',
            addedByUserId: '1',
            status: 'تم التوثيق',
            createdAt: DateTime.now(),
          ),
        ];

        for (final prisoner in samplePrisoners) {
          await _dbService.insertPrisoner(prisoner);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة 10 أسرى كبيانات تجريبية بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في إضافة البيانات: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إدارة البيانات',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryWhite,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: AppColors.primaryWhite),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryWhite,
          labelColor: AppColors.primaryWhite,
          unselectedLabelColor: AppColors.primaryWhite.withOpacity(0.7),
          tabs: const [
            Tab(text: 'الشهداء'),
            Tab(text: 'الجرحى'),
            Tab(text: 'الأسرى'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDataSection(
            title: 'إدارة بيانات الشهداء',
            description: 'إضافة بيانات تجريبية لقسم الشهداء لاختبار وظائف التطبيق',
            icon: Icons.person_off,
            color: AppColors.error,
            onAddData: _addSampleMartyrs,
            items: [
              'معلومات شخصية كاملة',
              'تواريخ الولادة والوفاة',
              'مكان وسبب الاستشهاد',
              'المنصب والجبهات',
              'الحالة العائلية',
              'بيانات التواصل',
              'حالة التوثيق',
            ],
          ),
          _buildDataSection(
            title: 'إدارة بيانات الجرحى',
            description: 'إضافة بيانات تجريبية لقسم الجرحى لاختبار وظائف التطبيق',
            icon: Icons.local_hospital,
            color: AppColors.warning,
            onAddData: _addSampleInjured,
            items: [
              'معلومات شخصية كاملة',
              'تاريخ ومكان الإصابة',
              'نوع ووصف الإصابة',
              'درجة الخطورة',
              'الحالة الصحية الحالية',
              'اسم المستشفى',
              'بيانات التواصل',
              'حالة التوثيق',
            ],
          ),
          _buildDataSection(
            title: 'إدارة بيانات الأسرى',
            description: 'إضافة بيانات تجريبية لقسم الأسرى لاختبار وظائف التطبيق',
            icon: Icons.gavel,
            color: AppColors.info,
            onAddData: _addSamplePrisoners,
            items: [
              'معلومات شخصية كاملة',
              'تاريخ ومكان الاعتقال',
              'سبب الاعتقال',
              'مدة الحكم',
              'اسم السجن',
              'الحالة الصحية',
              'الحالة العائلية',
              'بيانات التواصل',
              'حالة التوثيق',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onAddData,
    required List<String> items,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // قائمة العناصر المضافة
                  Text(
                    'البيانات المضافة تشمل:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
                  
                  const SizedBox(height: 24),
                  
                  // زر الإضافة
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onAddData,
                      icon: const Icon(Icons.add, color: AppColors.primaryWhite),
                      label: const Text(
                        'إضافة 10 عناصر تجريبية',
                        style: TextStyle(
                          color: AppColors.primaryWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // معلومات إضافية
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.info.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info),
                    const SizedBox(width: 8),
                    Text(
                      'ملاحظات مهمة',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• البيانات المضافة هي بيانات تجريبية للاختبار فقط\n'
                  '• يمكن حذف أو تعديل هذه البيانات من الشاشات المخصصة\n'
                  '• البيانات تحتوي على حالات مختلفة للتوثيق (معتمد، قيد المراجعة، مرفوض)\n'
                  '• يمكن إضافة البيانات عدة مرات لزيادة حجم قاعدة البيانات',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}