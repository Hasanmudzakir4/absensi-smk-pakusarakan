class UserModel {
  final String uid;
  final String email;
  final String? name;
  final String? phone;
  final String? dateOfBirth;
  final String? idNumber;
  final String? role;
  final String? photoUrl;

  // Student-specific fields
  final String? studentClass;

  UserModel({
    required this.uid,
    required this.email,
    this.name,
    this.idNumber,
    this.studentClass,
    this.phone,
    this.dateOfBirth,
    this.role,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'idNumber': idNumber,
      'studentClass': studentClass,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'role': role,
      'photoUrl': photoUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'],
      idNumber: map['idNumber'],
      studentClass: map['studentClass'],
      phone: map['phone'],
      dateOfBirth: map['dateOfBirth'],
      role: map['role'],
      photoUrl: map['photoUrl'],
    );
  }

  factory UserModel.fromFirebaseUser(dynamic user) {
    return UserModel(uid: user.uid, email: user.email ?? '');
  }
}
