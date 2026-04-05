class SubmoduleModel {
  final int id;
  final int idModule;
  final String name;
  final String? description;
  final String? content;
  final int? orderSubmodule;

  SubmoduleModel({
    required this.id,
    required this.idModule,
    required this.name,
    this.description,
    this.content,
    this.orderSubmodule,
  });

  factory SubmoduleModel.fromJson(Map<String, dynamic> json) {
    return SubmoduleModel(
      id: json['id'] as int,
      idModule: json['id_module'] as int,
      name: json['name'] ?? '',
      description: json['description'],
      content: json['content'],
      orderSubmodule: json['order_submodule'],
    );
  }
}