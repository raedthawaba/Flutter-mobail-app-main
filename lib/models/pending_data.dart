import 'package:cloud_firestore/cloud_firestore.dart';

class PendingData {
  final String? id;
  final String type; // 'martyr', 'injured', 'prisoner'
  final String status; // 'pending', 'approved', 'rejected', 'hidden'
  final Map<String, dynamic> data;
  final String? imageUrl;
  final String? resumeUrl;
  final String submittedBy;
  final DateTime submittedAt;
  final String? adminNotes;
  final String? adminAction;
  final DateTime? processedAt;
  final String? adminId;

  const PendingData({
    this.id,
    required this.type,
    required this.status,
    required this.data,
    this.imageUrl,
    this.resumeUrl,
    required this.submittedBy,
    required this.submittedAt,
    this.adminNotes,
    this.adminAction,
    this.processedAt,
    this.adminId,
  });

  factory PendingData.fromFirestore(Map<String, dynamic> data) {
    return PendingData(
      id: data['id'] as String?,
      type: data['type'] as String,
      status: data['status'] as String,
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      imageUrl: data['imageUrl'] as String?,
      resumeUrl: data['resumeUrl'] as String?,
      submittedBy: data['submittedBy'] as String,
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      adminNotes: data['adminNotes'] as String?,
      adminAction: data['adminAction'] as String?,
      processedAt: data['processedAt'] != null 
          ? (data['processedAt'] as Timestamp).toDate() 
          : null,
      adminId: data['adminId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': type,
      'status': status,
      'data': data,
      'imageUrl': imageUrl,
      'resumeUrl': resumeUrl,
      'submittedBy': submittedBy,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'adminNotes': adminNotes,
      'adminAction': adminAction,
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'adminId': adminId,
    };
  }

  // Copy with method for updates
  PendingData copyWith({
    String? id,
    String? type,
    String? status,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? resumeUrl,
    String? submittedBy,
    DateTime? submittedAt,
    String? adminNotes,
    String? adminAction,
    DateTime? processedAt,
    String? adminId,
  }) {
    return PendingData(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      submittedBy: submittedBy ?? this.submittedBy,
      submittedAt: submittedAt ?? this.submittedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      adminAction: adminAction ?? this.adminAction,
      processedAt: processedAt ?? this.processedAt,
      adminId: adminId ?? this.adminId,
    );
  }
}