import 'dart:convert';

class PracticalTaskModel {
  final int id;
  final int? submoduleId;
  final String name;
  final String? description;
  final String? content;
  final String? language;
  final String? starterCode;
  final List<TestCase>? testCases;
  final int? orderTask;
  final int? difficulty;
  final bool? status;

  PracticalTaskModel({
    required this.id,
    this.submoduleId,
    required this.name,
    this.description,
    this.content,
    this.language,
    this.starterCode,
    this.testCases,
    this.orderTask,
    this.difficulty,
    this.status,
  });

  factory PracticalTaskModel.fromJson(Map<String, dynamic> json) {
    List<TestCase>? testCases;
    if (json['test_cases'] != null) {
      final casesJson = json['test_cases'];
      if (casesJson is String) {
        final List<dynamic> cases = 
            const JsonDecoder().convert(casesJson);
        testCases = cases.map((c) => TestCase.fromJson(c)).toList();
      } else if (casesJson is List) {
        testCases = casesJson.map((c) => TestCase.fromJson(c)).toList();
      }
    }

    return PracticalTaskModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      submoduleId: json['id_submodule'] as int?,
      name: json['name']?.toString() ?? '',
      description: json['description'] as String?,
      content: json['content'] as String?,
      language: json['language'] as String?,
      starterCode: json['starter_code'] as String?,
      testCases: testCases,
      orderTask: json['order_task'] as int?,
      difficulty: json['difficulty'] as int?,
      status: json['status'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (submoduleId != null) 'id_submodule': submoduleId,
      'name': name,
      if (description != null) 'description': description,
      if (content != null) 'content': content,
      if (language != null) 'language': language,
      if (starterCode != null) 'starter_code': starterCode,
      if (testCases != null) 'test_cases': jsonEncode(testCases!.map((t) => t.toJson()).toList()),
      if (orderTask != null) 'order_task': orderTask,
      if (difficulty != null) 'difficulty': difficulty,
      if (status != null) 'status': status,
    };
  }
}

class TestCase {
  final String input;
  final String expectedOutput;
  final String description;

  TestCase({
    required this.input,
    required this.expectedOutput,
    required this.description,
  });

  factory TestCase.fromJson(Map<String, dynamic> json) {
    return TestCase(
      input: json['input']?.toString() ?? '',
      expectedOutput: json['expected_output']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'input': input,
      'expected_output': expectedOutput,
      'description': description,
    };
  }
}
