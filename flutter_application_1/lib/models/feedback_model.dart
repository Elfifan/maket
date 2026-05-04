class FeedbackModel {
  final int id;
  final int? userId;
  final int? courseId;
  final double? estimation;
  final String? description;
  final bool? status;
  final String? userName;
  final String? userEmail;

  FeedbackModel({
    required this.id,
    this.userId,
    this.courseId,
    this.estimation,
    this.description,
    this.status,
    this.userName,
    this.userEmail,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    // Данные пользователя из связанной таблицы
    final userData = json['users'] as Map<String, dynamic>?;

    return FeedbackModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['id_user'] as int?,
      courseId: json['id_courses'] as int?,
      estimation: (json['estimation'] as num?)?.toDouble(),
      description: json['description'] as String?,
      status: json['status'] as bool?,
      userName: userData?['name'] as String?,
      userEmail: userData?['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_user': userId,
      'id_courses': courseId,
      'estimation': estimation,
      'description': description,
      'status': status,
    };
  }

  /// Получить отображаемое имя пользователя
  String get displayName {
    if (userName != null && userName!.isNotEmpty) return userName!;
    if (userEmail != null && userEmail!.isNotEmpty) {
      return userEmail!.split('@')[0];
    }
    return 'Пользователь';
  }

  /// Получить инициал для аватара
  String get initial {
    final name = displayName;
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }
}