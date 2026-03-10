import 'dart:typed_data';

class UserModel {
  final int? id;
  final String? name;
  final String? email;
  final String? password;
  final DateTime? dateRegistration;
  final Uint8List? avatar;
  final bool? status;
  final DateTime? lastEntry;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.password,
    this.dateRegistration,
    this.avatar,
    this.status,
    this.lastEntry,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      dateRegistration: json['date_registration'] != null 
          ? DateTime.parse(json['date_registration']) 
          : null,
      avatar: null, // Теперь аватар всегда null
      status: json['status'],
      lastEntry: json['last_entry'] != null 
          ? DateTime.parse(json['last_entry']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (password != null) 'password': password,
      if (dateRegistration != null) 
        'date_registration': dateRegistration!.toIso8601String().split('T')[0],
      // avatar больше не отправляем
      if (status != null) 'status': status,
      if (lastEntry != null) 
        'last_entry': lastEntry!.toIso8601String().split('T')[0],
    };
  }
}