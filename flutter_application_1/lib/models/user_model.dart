



class UserModel {
  final int? id;
  final String? name;
  final String? email;
  final String? password;
  final DateTime? dateRegistration;
  final String? avatarUrl;
  final bool? status;
  final DateTime? lastEntry;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.password,
    this.dateRegistration,
    this.avatarUrl,
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
      avatarUrl: json['avatar'], // Теперь читаем URL из базы
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
      if (avatarUrl != null) 'avatar': avatarUrl,
      if (status != null) 'status': status,
      if (lastEntry != null) 
        'last_entry': lastEntry!.toIso8601String().split('T')[0],
    };
  }
}


class AchievementModel {
  final int id;
  final String? name;
  final String? description;
  final String? image; 

  AchievementModel({required this.id, this.name, this.description, this.image});

  // Убираем Base64 декодирование - image теперь URL
  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image'], // Это URL или путь
    );
  }
}