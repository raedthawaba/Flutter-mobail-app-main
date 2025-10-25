import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_test_service.dart';

class FirebaseTestScreen extends StatefulWidget {
  @override
  _FirebaseTestScreenState createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  Map<String, dynamic>? _testResults;
  bool _isTesting = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // اختبار تلقائي عند فتح الشاشة
    _runFirebaseTest();
  }

  Future<void> _runFirebaseTest() async {
    setState(() {
      _isTesting = true;
      _testResults = null;
    });

    try {
      final results = await FirebaseTestService.fullFirebaseTest();
      setState(() {
        _testResults = results;
      });

      // التمرير إلى الأسفل لرؤية النتائج
      Future.delayed(Duration(milliseconds: 500), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(seconds: 1),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في اختبار Firebase: $e')),
      );
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اختبار Firebase'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isTesting ? null : _runFirebaseTest,
            tooltip: 'إعادة الاختبار',
          ),
        ],
      ),
      body: _isTesting ? _buildLoadingWidget() : _buildTestResults(),
      floatingActionButton: FloatingActionButton(
        onPressed: _isTesting ? null : _runFirebaseTest,
        child: Icon(Icons.play_arrow),
        tooltip: 'تشغيل الاختبار',
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'جاري اختبار Firebase...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'قد يستغرق هذا بضع ثوانٍ',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResults() {
    if (_testResults == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 20),
            Text(
              'لا توجد نتائج اختبار',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _runFirebaseTest,
              icon: Icon(Icons.play_arrow),
              label: Text('بدء الاختبار'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          SizedBox(height: 20),
          _buildConnectionTestCard(),
          SizedBox(height: 20),
          _buildRoleTestCard(),
          SizedBox(height: 20),
          _buildCRUDTestCard(),
          SizedBox(height: 20),
          _buildSecurityTestCard(),
          SizedBox(height: 20),
          _buildRecommendationsCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _testResults!['summary'];
    final isWorking = summary['connection_working'];
    final errorCount = summary['total_errors'] ?? 0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isWorking ? Icons.check_circle : Icons.error,
                  color: isWorking ? Colors.green : Colors.red,
                  size: 32,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ملخص Firebase',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  color: summary['connection_working'] ? Colors.green : Colors.red,
                  size: 12,
                ),
                SizedBox(width: 8),
                Text('اتصال Firebase: ${summary['connection_working'] ? 'يعمل' : 'لا يعمل'}'),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  color: summary['auth_working'] ? Colors.green : Colors.red,
                  size: 12,
                ),
                SizedBox(width: 8),
                Text('Authentication: ${summary['auth_working'] ? 'يعمل' : 'لا يعمل'}'),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  color: summary['security_working'] ? Colors.green : Colors.red,
                  size: 12,
                ),
                SizedBox(width: 8),
                Text('Security Rules: ${summary['security_working'] ? 'يعمل' : 'لا يعمل'}'),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: errorCount == 0 ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    errorCount == 0 ? Icons.emoji_events : Icons.warning,
                    color: errorCount == 0 ? Colors.green : Colors.orange,
                  ),
                  SizedBox(width: 8),
                  Text(
                    errorCount == 0 ? '🎉 جميع الاختبارات نجحت!' : '⚠️ يوجد $errorCount أخطاء',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: errorCount == 0 ? Colors.green : Colors.orange,
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

  Widget _buildConnectionTestCard() {
    final connectionTest = _testResults!['connection_test'];
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔗 اختبار الاتصال',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildTestResult('Firebase initialized', connectionTest['firebase_initialized']),
            _buildTestResult('Auth working', connectionTest['auth_working']),
            _buildTestResult('Firestore working', connectionTest['firestore_working']),
            if (connectionTest['errors'].isNotEmpty) ...[
              SizedBox(height: 8),
              Text('الأخطاء:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ...connectionTest['errors'].map((error) => 
                Padding(
                  padding: EdgeInsets.only(left: 16, top: 4),
                  child: Text('❌ $error', style: TextStyle(color: Colors.red[600])),
                )
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTestCard() {
    final roleTest = _testResults!['role_test'];
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '👤 اختبار دور المستخدم',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildTestResult('User logged in', roleTest['user_logged_in']),
            if (roleTest['user_role'] != 'unknown')
              Text('📋 دور المستخدم: ${roleTest['user_role']}'),
            if (roleTest['has_admin_permission'])
              Text('🔐 صلاحيات Admin: متوفرة'),
            if (roleTest['has_moderator_permission'])
              Text('🔐 صلاحيات Moderator: متوفرة'),
          ],
        ),
      ),
    );
  }

  Widget _buildCRUDTestCard() {
    final crudTest = _testResults!['crud_test'];
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💾 اختبار CRUD Operations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            if (crudTest['test_results'].isNotEmpty)
              ...crudTest['test_results'].map((result) => 
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(result),
                )
              ),
            if (crudTest['errors'].isNotEmpty) ...[
              SizedBox(height: 8),
              Text('الأخطاء:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ...crudTest['errors'].map((error) => 
                Padding(
                  padding: EdgeInsets.only(left: 16, top: 4),
                  child: Text('❌ $error', style: TextStyle(color: Colors.red[600])),
                )
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTestCard() {
    final securityTest = _testResults!['security_test'];
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔒 اختبار Security Rules',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildTestResult('Unauthenticated read', securityTest['unauthenticated_read']),
            _buildTestResult('Authenticated read', securityTest['authenticated_read']),
            _buildTestResult('Admin write', securityTest['admin_write']),
            if (securityTest['errors'].isNotEmpty) ...[
              SizedBox(height: 8),
              Text('الأخطاء:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ...securityTest['errors'].map((error) => 
                Padding(
                  padding: EdgeInsets.only(left: 16, top: 4),
                  child: Text('❌ $error', style: TextStyle(color: Colors.red[600])),
                )
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final connectionTest = _testResults!['connection_test'];
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💡 التوصيات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            if (connectionTest['recommendations'].isEmpty)
              Text('✅ لا توجد توصيات خاصة - كل شيء يعمل بشكل صحيح!')
            else
              ...connectionTest['recommendations'].map((rec) => 
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                )
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResult(String testName, bool result) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            result ? Icons.check_circle : Icons.cancel,
            color: result ? Colors.green : Colors.red,
            size: 16,
          ),
          SizedBox(width: 8),
          Text('$testName: ${result ? 'نجح' : 'فشل'}'),
        ],
      ),
    );
  }
}