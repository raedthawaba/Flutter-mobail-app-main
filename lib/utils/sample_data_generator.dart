import 'dart:math' as math;
import 'package:faker/faker.dart';
import '../constants/app_constants.dart';
import '../services/firebase_database_service.dart';
import '../models/martyr.dart';
import '../models/injured.dart';
import '../models/prisoner.dart';

class SampleDataGenerator {
  static final SampleDataGenerator _instance = SampleDataGenerator._internal();
  factory SampleDataGenerator() => _instance;
  SampleDataGenerator._internal();

  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();
  final Faker _faker = Faker();

  // أسماء يمنية تجريبية
  final List<String> yemeniNames = [
    'أحمد محمد علي',
    'فاطمة أحمد حسن',
    'محمد عبدالله سعيد',
    'زينب علي محمود',
    'علي حسن أحمد',
    'مريم سالم يوسف',
    'خالد عبدالرحمن محمد',
    'نورا محمد عبدالله',
    'عبدالله أحمد علي',
    'أمل سعد أحمد',
    'يوسف محمد علي',
    'رانيا حسن علي',
    'حسن أحمد محمد',
    'سارة علي عبدالله',
    'عبدالرحمن سعيد محمد',
    'ليلى أحمد حسن',
    'صالح محمد علي',
    'هدى عبدالله محمد',
    'فهد حسن أحمد',
    'دينا محمد علي',
    'محمود أحمد حسن',
    'آمنة علي محمد',
    'راشد سالم علي',
    'ريم محمد عبدالله',
    'عادل حسن محمد',
    'أسماء أحمد علي',
    'طارق محمد حسن',
    'سلمى علي أحمد',
    'كريم عبدالله محمد',
    'رفيف حسن علي',
  ];

  // أسماء القبائل اليمنية
  final List<String> yemeniTribes = [
    'بكيل',
    'حاشد',
    'أخمد',
    'بني صريم',
    'صدام',
    '房白',
    'الغلف',
    '房د',
    'العنود',
    '马赫',
    'دهمان',
    '房主人的',
    '都德',
    'الربيعة',
    '阿加',
    'الشبابيح',
    '阿尔夫',
    'القحطاني',
    '房ك',
    '阿加尼'
  ];

  // أسباب death/injury
  final List<String> deathCauses = [
    'القصف الجوي',
    'الهجمات البرية',
    'الغارات الصاروخية',
    'الاشتبكات المسلحة',
    'الحوادث العسكرية',
    'الانفجارات',
    'الألغام',
    'النيران المباشرة'
  ];

  final List<String> injuryTypes = [
    'إصابات بالرصاص',
    'الانفجارات',
    'القصف المدفعي',
    'الحروق',
    'الاصطدام',
    'السقوط',
    'الإصابات الطعنية',
    'الالتهابات'
  ];

  // توليد بيانات تجريبية
  Future<void> generateSampleData() async {
    try {
      print('بدء توليد البيانات التجريبية...');
      
      // توليد 50 شهيد
      for (int i = 0; i < 50; i++) {
        Martyr martyr = _generateRandomMartyr();
        await _dbService.insertMartyr(martyr);
      }
      
      // توليد 75 جريح
      for (int i = 0; i < 75; i++) {
        Injured injured = _generateRandomInjured();
        await _dbService.insertInjured(injured);
      }
      
      // توليد 30 أسير
      for (int i = 0; i < 30; i++) {
        Prisoner prisoner = _generateRandomPrisoner();
        await _dbService.insertPrisoner(prisoner);
      }
      
      print('تم توليد البيانات التجريبية بنجاح!');
      
    } catch (e) {
      print('خطأ في توليد البيانات التجريبية: $e');
    }
  }

  // توليد شهيد عشوائي
  Martyr _generateRandomMartyr() {
    String fullName = yemeniNames[math.Random().nextInt(yemeniNames.length)];
    String tribe = yemeniTribes[math.Random().nextInt(yemeniTribes.length)];
    String deathPlace = AppConstants.yemenGovernorates[math.Random().nextInt(AppConstants.yemenGovernorates.length)];
    String causeOfDeath = deathCauses[math.Random().nextInt(deathCauses.length)];
    
    // تاريخ الوفاة عشوائي خلال السنوات الثلاث الماضية
    DateTime now = DateTime.now();
    DateTime deathDate = now.subtract(Duration(
      days: math.Random().nextInt(1095) // 3 سنوات
    ));
    
    // الحالة عشوائية
    List<String> statuses = [AppConstants.statusApproved, AppConstants.statusPending, AppConstants.statusRejected];
    String status = statuses[math.Random().nextInt(3)];
    
    return Martyr(
      fullName: fullName,
      nickname: math.Random().nextBool() ? 'الكنية' : null,
      tribe: tribe,
      birthDate: _generateRandomBirthDate(),
      deathDate: deathDate,
      deathPlace: deathPlace,
      causeOfDeath: causeOfDeath,
      rankOrPosition: math.Random().nextBool() ? 'مدني' : 'مقاتل',
      participationFronts: math.Random().nextBool() ? 'الجبهة الجنوبية' : null,
      familyStatus: ['متزوج', 'عزب', 'أرمل'][math.Random().nextInt(3)],
      numChildren: math.Random().nextBool() ? math.Random().nextInt(8) + 1 : 0,
      contactFamily: '+967777123456',
      addedByUserId: '1',
      photoPath: null,
      cvFilePath: null,
      status: status,
      adminNotes: math.Random().nextBool() ? 'تم مراجعة الوثائق' : null,
      createdAt: deathDate,
      updatedAt: null,
    );
  }

  // توليد جريح عشوائي
  Injured _generateRandomInjured() {
    String fullName = yemeniNames[math.Random().nextInt(yemeniNames.length)];
    String tribe = yemeniTribes[math.Random().nextInt(yemeniTribes.length)];
    String injuryPlace = AppConstants.yemenGovernorates[math.Random().nextInt(AppConstants.yemenGovernorates.length)];
    String injuryType = injuryTypes[math.Random().nextInt(injuryTypes.length)];
    
    // تاريخ الإصابة عشوائي
    DateTime now = DateTime.now();
    DateTime injuryDate = now.subtract(Duration(
      days: math.Random().nextInt(1095) // 3 سنوات
    ));
    
    // درجة الإصابة
    List<String> degrees = AppConstants.injuryDegrees;
    String injuryDegree = degrees[math.Random().nextInt(degrees.length)];
    
    // الحالة
    List<String> statuses = [AppConstants.statusApproved, AppConstants.statusPending, AppConstants.statusRejected];
    String status = statuses[math.Random().nextInt(3)];
    
    return Injured(
      fullName: fullName,
      tribe: tribe,
      injuryDate: injuryDate,
      injuryPlace: injuryPlace,
      injuryType: injuryType,
      injuryDescription: 'إصابة $injuryType في $injuryPlace',
      injuryDegree: injuryDegree,
      currentStatus: ['جاري العلاج', 'تم الشفاء', 'مازال في المستشفى'][math.Random().nextInt(3)],
      hospitalName: math.Random().nextBool() ? 'مستشفى العدين' : null,
      contactFamily: '+967777123456',
      addedByUserId: '1',
      photoPath: null,
      cvFilePath: null,
      status: status,
      adminNotes: math.Random().nextBool() ? 'تم مراجعة الحالة' : null,
      createdAt: injuryDate,
      updatedAt: null,
    );
  }

  // توليد أسير عشوائي
  Prisoner _generateRandomPrisoner() {
    String fullName = yemeniNames[math.Random().nextInt(yemeniNames.length)];
    String tribe = yemeniTribes[math.Random().nextInt(yemeniTribes.length)];
    String capturePlace = AppConstants.yemenGovernorates[math.Random().nextInt(AppConstants.yemenGovernorates.length)];
    
    // تاريخ الأسر عشوائي
    DateTime now = DateTime.now();
    DateTime captureDate = now.subtract(Duration(
      days: math.Random().nextInt(1095) // 3 سنوات
    ));
    
    // الحالة
    List<String> statuses = [AppConstants.statusApproved, AppConstants.statusPending, AppConstants.statusRejected];
    String status = statuses[math.Random().nextInt(3)];
    
    String currentStatus = math.Random().nextBool() ? 'مازال محتجز' : 'تم الإفراج';
    DateTime? releaseDate;
    
    if (currentStatus == 'تم الإفراج') {
      releaseDate = captureDate.add(Duration(
        days: math.Random().nextInt(365) + 30 // بين شهر وسنة
      ));
    }
    
    return Prisoner(
      fullName: fullName,
      tribe: tribe,
      captureDate: captureDate,
      capturePlace: capturePlace,
      capturedBy: math.Random().nextBool() ? 'القوات الحكومية' : 'المليشيات',
      currentStatus: currentStatus,
      releaseDate: releaseDate,
      familyContact: '+967777123456',
      detentionPlace: math.Random().nextBool() ? 'سجن الأمن المركزي' : null,
      notes: math.Random().nextBool() ? 'تم الإفراج بموجب صفقة تبادل' : null,
      addedByUserId: '1',
      photoPath: null,
      cvFilePath: null,
      status: status,
      adminNotes: math.Random().nextBool() ? 'تم مراجعة ملف الأسير' : null,
      createdAt: captureDate,
      updatedAt: null,
    );
  }

  // توليد تاريخ ميلاد عشوائي
  DateTime _generateRandomBirthDate() {
    DateTime now = DateTime.now();
    DateTime birthDate = DateTime(
      now.year - (math.Random().nextInt(50) + 18), // بين 18 و 68 سنة
      math.Random().nextInt(12) + 1,
      math.Random().nextInt(28) + 1,
    );
    
    return birthDate;
  }
}
