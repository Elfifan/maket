class CourseModel {
  final int id;
  final int? idEmployee;
  final String name;
  final String? description;
  final DateTime? dateCreate;
  final double? price;
  final int? complexity;
  final bool? status;

  CourseModel({
    required this.id,
    this.idEmployee,
    required this.name,
    this.description,
    this.dateCreate,
    this.price,
    this.complexity,
    this.status,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as int,
      idEmployee: json['id_employee'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      dateCreate: json['date_create'] != null
          ? DateTime.parse(json['date_create'])
          : null,
      price: json['price'] != null
          ? (json['price'] as num).toDouble()
          : null,
      complexity: json['complexity'] as int?,
      status: json['status'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (idEmployee != null) 'id_employee': idEmployee,
      'name': name,
      if (description != null) 'description': description,
      if (dateCreate != null) 'date_create': dateCreate!.toIso8601String().split('T')[0],
      if (price != null) 'price': price,
      if (complexity != null) 'complexity': complexity,
      if (status != null) 'status': status,
    };
  }
}