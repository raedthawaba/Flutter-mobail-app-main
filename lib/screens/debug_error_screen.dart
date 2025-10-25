import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class DebugErrorScreen extends StatelessWidget {
  final String errorMessage;
  final String stackTrace;
  final List<String> debugLogs;

  const DebugErrorScreen({
    Key? key,
    required this.errorMessage,
    required this.stackTrace,
    required this.debugLogs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fullLog = _buildFullLog();

    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        title: const Text('🐛 خطأ في التطبيق'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // أيقونة الخطأ
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade700,
            ),
            const SizedBox(height: 16),

            // العنوان
            const Text(
              'عذراً، حدث خطأ!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // رسالة توضيحية
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: const Text(
                'هذه المعلومات مهمة لحل المشكلة.\n'
                'الرجاء نسخها وإرسالها للمطور.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // رسالة الخطأ
            _buildSection(
              title: '📌 رسالة الخطأ:',
              content: errorMessage,
              color: Colors.red.shade100,
            ),
            const SizedBox(height: 16),

            // آخر الخطوات
            _buildSection(
              title: '📋 آخر الخطوات الناجحة:',
              content: debugLogs.isEmpty 
                  ? 'لا توجد معلومات'
                  : debugLogs.join('\n'),
              color: Colors.green.shade100,
            ),
            const SizedBox(height: 16),

            // Stack Trace
            if (stackTrace.isNotEmpty)
              _buildSection(
                title: '🔍 تفاصيل تقنية:',
                content: stackTrace,
                color: Colors.orange.shade100,
              ),
            const SizedBox(height: 24),

            // زر نسخ
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: fullLog));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ تم نسخ معلومات الخطأ!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text(
                'نسخ معلومات الخطأ',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // تعليمات
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'كيف أرسل هذه المعلومات؟',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1️⃣ اضغط زر "نسخ معلومات الخطأ" أعلاه\n'
                    '2️⃣ افتح WhatsApp أو Telegram\n'
                    '3️⃣ الصق المعلومات وأرسلها للمطور\n'
                    '4️⃣ أو خذ Screenshot لهذه الشاشة',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // زر إغلاق
            OutlinedButton(
              onPressed: () {
                // محاولة الخروج من التطبيق
                SystemNavigator.pop();
              },
              child: const Text(
                'إغلاق التطبيق',
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SelectableText(
            content,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  String _buildFullLog() {
    final buffer = StringBuffer();
    buffer.writeln('=' * 50);
    buffer.writeln('تقرير الخطأ - تطبيق توثيق الشهداء');
    buffer.writeln('=' * 50);
    buffer.writeln();
    buffer.writeln('📌 رسالة الخطأ:');
    buffer.writeln(errorMessage);
    buffer.writeln();
    buffer.writeln('📋 آخر الخطوات الناجحة:');
    if (debugLogs.isEmpty) {
      buffer.writeln('لا توجد معلومات');
    } else {
      for (var log in debugLogs) {
        buffer.writeln('  • $log');
      }
    }
    if (stackTrace.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('🔍 Stack Trace:');
      buffer.writeln(stackTrace);
    }
    buffer.writeln();
    buffer.writeln('=' * 50);
    return buffer.toString();
  }
}
