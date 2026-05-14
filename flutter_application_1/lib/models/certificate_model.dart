class CertificateModel {
  final int? id;
  final int idUser;
  final int idCourses;
  final String certificateUrl;
  final String? courseName;
  final DateTime? issueDate;
  final String? verificationCode;

  CertificateModel({
    this.id,
    required this.idUser,
    required this.idCourses,
    required this.certificateUrl,
    this.courseName,
    this.issueDate,
    this.verificationCode,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    String? courseName;
    if (json['courses'] != null && json['courses'] is Map) {
      courseName = json['courses']['name'];
    }
    
    return CertificateModel(
      id: json['id'] as int?,
      idUser: json['id_user'] as int,
      idCourses: json['id_courses'] as int,
      certificateUrl: json['certificate_url'] as String,
      courseName: courseName,
      issueDate: json['issue_date'] != null ? DateTime.parse(json['issue_date']) : null,
      verificationCode: json['verification_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'id_courses': idCourses,
      'certificate_url': certificateUrl,
      'issue_date': issueDate?.toIso8601String(),
      'verification_code': verificationCode,
    };
  }
}