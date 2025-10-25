import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String? uid; // Firebase Auth UID
  final int? id; // Local ID (for backward compatibility)
  final String email;
  final String username;
  final String? password; // Optional for Firebase Auth users
  final String fullName;
  final String userType;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const User({
    this.uid,
    this.id,
    required this.email,
    required this.username,
    this.password,
    required this.fullName,
    required this.userType,
    this.phoneNumber,
    required this.createdAt,
    this.lastLogin,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    // قراءة userType من عدة مصادر محتملة مع معالجة القيم القديمة
    String userTypeValue = '';
    if (map['user_type'] != null && map['user_type'].toString().isNotEmpty) {
      userTypeValue = map['user_type'].toString();
    } else if (map['userType'] != null && map['userType'].toString().isNotEmpty) {
      userTypeValue = map['userType'].toString();
    } else if (map['role'] != null && map['role'].toString().isNotEmpty) {
      // للتوافق مع البيانات القديمة التي كانت تستخدم 'role'
      userTypeValue = map['role'].toString();
    }
    
    // تحويل القيم القديمة إلى القيم الجديدة
    if (userTypeValue.toLowerCase() == 'admin') {
      userTypeValue = 'admin';
    } else if (userTypeValue.toLowerCase() == 'regular' || userTypeValue.toLowerCase() == 'user') {
      userTypeValue = 'regular';
    } else if (userTypeValue.isEmpty) {
      // إذا كان فارغاً، استخدم القيمة الافتراضية
      userTypeValue = 'regular';
    }

    return User(
      uid: map['uid'],
      id: map['id'],
      email: map['email'] ?? '',
      username: map['username'] ?? map['email']?.split('@')[0] ?? '',
      password: map['password'],
      fullName: map['full_name'] ?? map['fullName'] ?? '',
      userType: userTypeValue,
      phoneNumber: map['phone_number'] ?? map['phoneNumber'],
      createdAt: map['created_at'] != null 
          ? (map['created_at'] is String 
              ? DateTime.parse(map['created_at']) 
              : DateTime.fromMillisecondsSinceEpoch(map['created_at']))
          : (map['createdAt'] != null
              ? (map['createdAt'] is String
                  ? DateTime.parse(map['createdAt'])
                  : DateTime.fromMillisecondsSinceEpoch(map['createdAt']))
              : DateTime.now()),
      lastLogin: map['last_login'] != null 
          ? (map['last_login'] is String
              ? DateTime.parse(map['last_login'])
              : DateTime.fromMillisecondsSinceEpoch(map['last_login']))
          : (map['lastLogin'] != null
              ? (map['lastLogin'] is String
                  ? DateTime.parse(map['lastLogin'])
                  : DateTime.fromMillisecondsSinceEpoch(map['lastLogin']))
              : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'id': id,
      'email': email,
      'username': username,
      'password': password,
      'full_name': fullName,
      'user_type': userType,
      'phone_number': phoneNumber,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_login': lastLogin?.millisecondsSinceEpoch,
    };
  }

  // Firestore-friendly map (without null values and using camelCase)
  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'email': email,
      'username': username,
      'fullName': fullName,
      'userType': userType,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
    
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (lastLogin != null) data['lastLogin'] = lastLogin!.millisecondsSinceEpoch;
    
    return data;
  }

  User copyWith({
    String? uid,
    int? id,
    String? email,
    String? username,
    String? password,
    String? fullName,
    String? userType,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      uid: uid ?? this.uid,
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      userType: userType ?? this.userType,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        id,
        email,
        username,
        password,
        fullName,
        userType,
        phoneNumber,
        createdAt,
        lastLogin,
      ];
}