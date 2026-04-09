class TestModel {
  final int id;
  final String? name;
  final String? question;
  final String? rightAnswer;
  final String? wrongAnswer1;
  final String? wrongAnswer2;
  final String? wrongAnswer3;
  final bool? status;
  final int? difficulty;
  final String? category;
  final int? submoduleId;

  TestModel({
    required this.id,
    this.name,
    this.question,
    this.rightAnswer,
    this.wrongAnswer1,
    this.wrongAnswer2,
    this.wrongAnswer3,
    this.status,
    this.difficulty,
    this.category,
    this.submoduleId,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return TestModel(
      id: parseInt(json['id']),
      name: json['name'] as String?,
      question: json['question'] as String?,
      rightAnswer: json['right_answer'] as String?,
      wrongAnswer1: json['wrong_answer1'] as String?,
      wrongAnswer2: json['wrong_answer2'] as String?,
      wrongAnswer3: json['wrong_answer3'] as String?,
      status: json['status'] as bool?,
      difficulty: json['difficulty'] as int?,
      category: json['category'] as String?,
      submoduleId: json['id_submodule'] != null ? parseInt(json['id_submodule']) : null,
    );
  }

  List<String> get answerOptions {
    final options = <String>[];
    if (rightAnswer != null && rightAnswer!.isNotEmpty) options.add(rightAnswer!);
    if (wrongAnswer1 != null && wrongAnswer1!.isNotEmpty) options.add(wrongAnswer1!);
    if (wrongAnswer2 != null && wrongAnswer2!.isNotEmpty) options.add(wrongAnswer2!);
    if (wrongAnswer3 != null && wrongAnswer3!.isNotEmpty) options.add(wrongAnswer3!);
    return options;
  }
}
