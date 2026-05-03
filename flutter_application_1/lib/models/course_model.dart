class CourseModel {
  final int id;
  final int? idEmployee;
  final String name;
  final String? description;
  final String? icon;
  final DateTime? dateCreate;
  final double? price;
  final int? complexity;
  final String? status; // Изменено с bool? на String?

  CourseModel({
    required this.id,
    this.idEmployee,
    required this.name,
    this.description,
    this.icon,
    this.dateCreate,
    this.price,
    this.complexity,
    this.status,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    String? status;
    final statusValue = json['status'];
    if (statusValue is String) {
      status = statusValue;
    } else if (statusValue is bool) {
      status = statusValue ? 'Активный' : 'На проверке';
    } else if (statusValue != null) {
      status = statusValue.toString();
    }

    return CourseModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      idEmployee: json['id_employee'] as int?,
      name: json['name']?.toString() ?? '',
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      dateCreate: json['date_create'] != null
          ? DateTime.tryParse(json['date_create'].toString())
          : null,
      price: json['price'] != null
          ? (json['price'] as num).toDouble()
          : null,
      complexity: json['complexity'] as int?,
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (idEmployee != null) 'id_employee': idEmployee,
      'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (dateCreate != null) 'date_create': dateCreate!.toIso8601String().split('T')[0],
      if (price != null) 'price': price,
      if (complexity != null) 'complexity': complexity,
      if (status != null) 'status': status,
    };
  }

  /// Проверка, активен ли курс
  bool get isActive => status == 'Активный';
}