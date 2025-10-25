import 'package:equatable/equatable.dart';
import '../constants/app_constants.dart';

class Martyr extends Equatable {
  final String? id;
  final String fullName;
  final String? nickname;
  final String tribe;
  final DateTime? birthDate;
  final DateTime deathDate;
  final String deathPlace;
  final String causeOfDeath;
  final String? rankOrPosition;
  final String? participationFronts;
  final String? familyStatus;
  final int? numChildren;
  final String contactFamily;
  final String addedByUserId; // User ID from Firebase Auth (String UID)
  final String? photoPath;
  final String? cvFilePath;
  final String status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Martyr({
    this.id,
    required this.fullName,
    this.nickname,
    required this.tribe,
    this.birthDate,
    required this.deathDate,
    required this.deathPlace,
    required this.causeOfDeath,
    this.rankOrPosition,
    this.participationFronts,
    this.familyStatus,
    this.numChildren,
    required this.contactFamily,
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
  DateTime get dateOfMartyrdom => deathDate;
  String get placeOfMartyrdom => deathPlace;
  String get causeOfMartyrdom => causeOfDeath;
  String? get notes => adminNotes;
  int get age {
    if (birthDate != null) {
      return deathDate.year - birthDate!.year;
    }
    return 0;
  }

  factory Martyr.fromMap(Map<String, dynamic> map) {
    return Martyr(
      id: map['id'],
      fullName: map['full_name'],
      nickname: map['nickname'],
      tribe: map['tribe'],
      birthDate: map['birth_date'] != null ? DateTime.parse(map['birth_date']) : null,
      deathDate: DateTime.parse(map['death_date']),
      deathPlace: map['death_place'],
      causeOfDeath: map['cause_of_death'],
      rankOrPosition: map['rank_or_position'],
      participationFronts: map['participation_fronts'],
      familyStatus: map['family_status'],
      numChildren: map['num_children'],
      contactFamily: map['contact_family'],
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
      'nickname': nickname,
      'tribe': tribe,
      'birth_date': birthDate?.toIso8601String(),
      'death_date': deathDate.toIso8601String(),
      'death_place': deathPlace,
      'cause_of_death': causeOfDeath,
      'rank_or_position': rankOrPosition,
      'participation_fronts': participationFronts,
      'family_status': familyStatus,
      'num_children': numChildren,
      'contact_family': contactFamily,
      'added_by_user_id': addedByUserId,
      'photo_path': photoPath,
      'cv_file_path': cvFilePath,
      'status': status,
      'admin_notes': adminNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Martyr copyWith({
    String? id,
    String? fullName,
    String? nickname,
    String? tribe,
    DateTime? birthDate,
    DateTime? deathDate,
    String? deathPlace,
    String? causeOfDeath,
    String? rankOrPosition,
    String? participationFronts,
    String? familyStatus,
    int? numChildren,
    String? contactFamily,
    String? addedByUserId, // User ID from Firebase Auth (String UID)
    String? photoPath,
    String? cvFilePath,
    String? status,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Martyr(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      nickname: nickname ?? this.nickname,
      tribe: tribe ?? this.tribe,
      birthDate: birthDate ?? this.birthDate,
      deathDate: deathDate ?? this.deathDate,
      deathPlace: deathPlace ?? this.deathPlace,
      causeOfDeath: causeOfDeath ?? this.causeOfDeath,
      rankOrPosition: rankOrPosition ?? this.rankOrPosition,
      participationFronts: participationFronts ?? this.participationFronts,
      familyStatus: familyStatus ?? this.familyStatus,
      numChildren: numChildren ?? this.numChildren,
      contactFamily: contactFamily ?? this.contactFamily,
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
        nickname,
        tribe,
        birthDate,
        deathDate,
        deathPlace,
        causeOfDeath,
        rankOrPosition,
        participationFronts,
        familyStatus,
        numChildren,
        contactFamily,
        addedByUserId,
        photoPath,
        cvFilePath,
        status,
        adminNotes,
        createdAt,
        updatedAt,
      ];
}