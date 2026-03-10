class ModuleModel {
  final int id;
  final int idCourses;
  final String name;
  final int? orderModule;
  final bool? status;

  ModuleModel({
    required this.id,
    required this.idCourses,
    required this.name,
    this.orderModule,
    this.status,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      id: json['id'] as int,
      idCourses: json['id_courses'] as int,
      name: json['name'] as String,
      orderModule: json['order_module'] as int?,
      status: json['status'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_courses': idCourses,
      'name': name,
      if (orderModule != null) 'order_module': orderModule,
      if (status != null) 'status': status,
    };
  }
}