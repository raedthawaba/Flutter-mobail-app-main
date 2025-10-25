import 'package:equatable/equatable.dart';
import '../constants/app_constants.dart';

class Prisoner extends Equatable {
  final String? id;
  final String fullName;
  final String tribe;
  final DateTime captureDate;
  final String capturePlace;
  final String capturedBy;
  final String currentStatus;
  final DateTime? releaseDate;
  final String familyContact;
  final String? detentionPlace;
  final String? notes;
  final String addedByUserId; // User ID from Firebase Auth (String UID)
  final String? photoPath;
  final String? cvFilePath;
  final String status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Prisoner({
    this.id,
    required this.fullName,
    required this.tribe,
    required this.captureDate,
    required this.capturePlace,
    required this.capturedBy,
    required this.currentStatus,
    this.releaseDate,
    required this.familyContact,
    this.detentionPlace,
    this.notes,
    required this.addedByUserId,
    this.photoPath,
    this.cvFilePath,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    this.updatedAt,
  });

  // Getters for compatibility with admin screens
  bool get isApproved => status == AppConstants.statusApproved;
  String get idNumber => id?.toString() ?? 'غير محدد';
  String get area => tribe;
  DateTime get dateOfArrest => captureDate;
  String get placeOfArrest => capturePlace;
  String get reasonForArrest => capturedBy;
  String? get currentPrison => detentionPlace;
  int get age => 0; // Age calculation would need birth date

  factory Prisoner.fromMap(Map<String, dynamic> map) {
    return Prisoner(
      id: map['id'],
      fullName: map['full_name'],
      tribe: map['tribe'],
      captureDate: DateTime.parse(map['capture_date']),
      capturePlace: map['capture_place'],
      capturedBy: map['captured_by'],
      currentStatus: map['current_status'],
      releaseDate: map['release_date'] != null ? DateTime.parse(map['release_date']) : null,
      familyContact: map['family_contact'],
      detentionPlace: map['detention_place'],
      notes: map['notes'],
      addedByUserId: map['added_by_user_id'],
      photoPath: map['photo_path'],
      cvFilePath: map['cv_file_path'],
      status: map['status'],
      adminNotes: map['admin_notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'tribe': tribe,
      'capture_date': captureDate.toIso8601String(),
      'capture_place': capturePlace,
      'captured_by': capturedBy,
      'current_status': currentStatus,
      'release_date': releaseDate?.toIso8601String(),
      'family_contact': familyContact,
      'detention_place': detentionPlace,
      'notes': notes,
      'added_by_user_id': addedByUserId,
      'photo_path': photoPath,
      'cv_file_path': cvFilePath,
      'status': status,
      'admin_notes': adminNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Prisoner copyWith({
    String? id,
    String? fullName,
    String? tribe,
    DateTime? captureDate,
    String? capturePlace,
    String? capturedBy,
    String? currentStatus,
    DateTime? releaseDate,
    String? familyContact,
    String? detentionPlace,
    String? notes,
    String? addedByUserId, // User ID from Firebase Auth (String UID)
    String? photoPath,
    String? cvFilePath,
    String? status,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Prisoner(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      tribe: tribe ?? this.tribe,
      captureDate: captureDate ?? this.captureDate,
      capturePlace: capturePlace ?? this.capturePlace,
      capturedBy: capturedBy ?? this.capturedBy,
      currentStatus: currentStatus ?? this.currentStatus,
      releaseDate: releaseDate ?? this.releaseDate,
      familyContact: familyContact ?? this.familyContact,
      detentionPlace: detentionPlace ?? this.detentionPlace,
      notes: notes ?? this.notes,
      addedByUserId: addedByUserId ?? this.addedByUserId,
      photoPath: photoPath ?? this.photoPath,
      cvFilePath: cvFilePath ?? this.cvFilePath,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        tribe,
        captureDate,
        capturePlace,
        capturedBy,
        currentStatus,
        releaseDate,
        familyContact,
        detentionPlace,
        notes,
        addedByUserId,
        photoPath,
        cvFilePath,
        status,
        adminNotes,
        createdAt,
        updatedAt,
      ];
}