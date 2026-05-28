import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/certificate_model.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import 'supabase_service.dart';

class CertificateService {
  static final CertificateService _instance = CertificateService._internal();
  factory CertificateService() => _instance;
  CertificateService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  Future<CertificateModel?> generateAndUploadCertificate({
    required UserModel user,
    required CourseModel course,
  }) async {
    try {
      // Если сертификат уже существует, возвращаем его и не создаём новый
      final existingCertificate = await getCertificate(user.id!, course.id);
      if (existingCertificate != null) {
        return existingCertificate;
      }

      final String verificationCode = _uuid.v4().substring(0, 8).toUpperCase();

      // Генерируем PDF
      final pdfBytes = await _generateCertificatePdf(user, course, verificationCode);

      // Создаем уникальное имя файла
      final fileName = 'certificate_${user.id}_${course.id}_${_uuid.v4()}.pdf';

      // Загружаем в Supabase Storage
      final certificateUrl = await _uploadPdfToStorage(pdfBytes, fileName);

      if (certificateUrl == null) {
        throw Exception('Failed to upload certificate to storage');
      }

      // Создаем запись в БД
      final certificate = await _createCertificateRecord(
        userId: user.id!,
        courseId: course.id,
        certificateUrl: certificateUrl,
        verificationCode: verificationCode,
      );

      // Выдаем достижение ID 9 за завершение любого курса
      await SupabaseService().awardAchievement(user.id!, 9);

      return certificate;
    } catch (e) {
      debugPrint('Error generating certificate: $e');
      return null;
    }
  }

  Future<T?> _withRetry<T>(Future<T?> Function() action, String label) async {
    int attempts = 0;
    const int maxAttempts = 3;
    const Duration timeout = Duration(seconds: 1);

    while (attempts < maxAttempts) {
      try {
        attempts++;
        return await action().timeout(timeout);
      } catch (e) {
        debugPrint('[$label] Попытка $attempts не удалась: $e');
        if (attempts >= maxAttempts) return null;
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> _findCertificateRow(int userId, int courseId) async {
    return _withRetry(() async {
      final response = await _supabase
          .from('certificates')
          .select('*, courses(name)')
          .eq('id_user', userId)
          .eq('id_courses', courseId)
          .order('id', ascending: true)
          .limit(1) as List<dynamic>?;

      if (response == null || response.isEmpty) {
        return null;
      }

      return Map<String, dynamic>.from(response.first as Map<String, dynamic>);
    }, 'Find Certificate');
  }

  Future<CertificateModel?> getCertificate(int userId, int courseId) async {
    final row = await _findCertificateRow(userId, courseId);
    if (row == null) {
      return null;
    }

    return CertificateModel.fromJson(row);
  }

  Future<Uint8List> _generateCertificatePdf(UserModel user, CourseModel course, String verificationCode) async {
    final pdf = pw.Document();

    final regularFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final boldFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));

    final primaryPurple = PdfColor.fromHex('#8A74F9');
    final goldColor = PdfColor.fromHex('#D4AF37');
    final textDark = PdfColor.fromHex('#1E1E2C');
    final textLight = PdfColor.fromHex('#A0A0B0');
    final boxBorder = PdfColor.fromHex('#63B3A5');
    final pinkLine = PdfColor.fromHex('#E8A0B8');

    final String issueDate = "${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: goldColor, width: 1.5),
            ),
            child: pw.Container(
              margin: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: primaryPurple, width: 4),
                color: PdfColors.white,
              ),
              padding: const pw.EdgeInsets.fromLTRB(40, 40, 40, 30),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // HEADER
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // LEFT HEADER
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 36,
                            height: 36,
                            decoration: pw.BoxDecoration(
                              color: primaryPurple,
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                            child: pw.Center(
                              child: pw.Text('K', style: pw.TextStyle(color: PdfColors.white, font: boldFont, fontSize: 20)),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('KODIX ACADEMY', style: pw.TextStyle(font: boldFont, fontSize: 16, color: textDark, letterSpacing: 1.5)),
                              pw.SizedBox(height: 2),
                              pw.Text('МЕЖДУНАРОДНЫЙ СЕРТИФИКАТ', style: pw.TextStyle(font: regularFont, fontSize: 8, color: textLight, letterSpacing: 2)),
                            ],
                          ),
                        ],
                      ),
                      // RIGHT HEADER
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            left: pw.BorderSide(color: goldColor, width: 1.5),
                            right: pw.BorderSide(color: goldColor, width: 1.5),
                          ),
                        ),
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: goldColor, width: 1),
                            borderRadius: pw.BorderRadius.circular(20),
                          ),
                          child: pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Container(width: 4, height: 4, decoration: pw.BoxDecoration(color: goldColor, shape: pw.BoxShape.circle)),
                              pw.SizedBox(width: 6),
                              pw.Text('VERIFIED GRADUATE', style: pw.TextStyle(color: goldColor, font: boldFont, fontSize: 10, letterSpacing: 1.5)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // BODY
                  pw.Column(
                    children: [
                      pw.Text(
                        'СЕРТИФИКАТ',
                        style: pw.TextStyle(font: boldFont, fontSize: 42, color: textDark, letterSpacing: 8),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'ОБ УСПЕШНОМ ПРОХОЖДЕНИИ КУРСА',
                        style: pw.TextStyle(font: regularFont, fontSize: 12, color: primaryPurple, letterSpacing: 3),
                      ),
                      pw.SizedBox(height: 30),
                      pw.Text(
                        'Настоящий документ удостоверяет, что',
                        style: pw.TextStyle(font: regularFont, fontSize: 12, color: textDark),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        (user.name != null && user.name!.trim().isNotEmpty)
                            ? user.name!.trim()
                            : (user.email != null && user.email!.isNotEmpty)
                                ? user.email!.split('@')[0]
                                : 'Ученик',
                        style: pw.TextStyle(font: boldFont, fontSize: 24, color: textDark),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(width: 200, height: 1, color: pinkLine),
                      pw.SizedBox(height: 16),
                      pw.Text(
                        'успешно завершил(а) обучение по программе курса:',
                        style: pw.TextStyle(font: regularFont, fontSize: 12, color: textDark),
                      ),
                      pw.SizedBox(height: 16),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: boxBorder, width: 1.5),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          course.name,
                          style: pw.TextStyle(font: boldFont, fontSize: 16, color: textDark),
                        ),
                      ),
                    ],
                  ),

                  // FOOTER
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(issueDate, style: pw.TextStyle(font: boldFont, fontSize: 12, color: textDark)),
                          pw.SizedBox(height: 4),
                          pw.Text('ДАТА ВЫДАЧИ', style: pw.TextStyle(font: regularFont, fontSize: 8, color: textLight, letterSpacing: 1)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('ЛР', style: pw.TextStyle(font: boldFont, fontSize: 14, color: textDark)),
                          pw.SizedBox(height: 4),
                          pw.Container(width: 150, height: 1, color: PdfColors.grey300),
                          pw.SizedBox(height: 4),
                          pw.Text('РУКОВОДИТЕЛЬ АКАДЕМИИ', style: pw.TextStyle(font: regularFont, fontSize: 8, color: textLight, letterSpacing: 1)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(verificationCode, style: pw.TextStyle(font: boldFont, fontSize: 12, color: textDark)),
                          pw.SizedBox(height: 4),
                          pw.Text('КОД ВЕРИФИКАЦИИ', style: pw.TextStyle(font: regularFont, fontSize: 8, color: textLight, letterSpacing: 1)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<String?> _uploadPdfToStorage(Uint8List pdfBytes, String fileName) async {
    return _withRetry(() async {
      final bucket = _supabase.storage.from('certificates');

      // Загружаем файл
      await bucket.uploadBinary(
        fileName,
        pdfBytes,
        fileOptions: const FileOptions(
          contentType: 'application/pdf',
          upsert: false,
        ),
      );

      // Получаем публичный URL
      final publicUrl = bucket.getPublicUrl(fileName);
      return publicUrl;
    }, 'Upload PDF');
  }

  Future<CertificateModel?> _createCertificateRecord({
    required int userId,
    required int courseId,
    required String certificateUrl,
    required String verificationCode,
  }) async {
    return _withRetry(() async {

      final response = await _supabase
          .from('certificates')
          .insert({
            'id_user': userId,
            'id_courses': courseId,
            'certificate_url': certificateUrl,
            'verification_code': verificationCode,
          })
          .select('*, courses(name)')
          .single();

      return CertificateModel.fromJson(response);
    }, 'Create Certificate Record');
  }

  Future<bool> hasCertificate(int userId, int courseId) async {
    try {
      final row = await _findCertificateRow(userId, courseId);
      return row != null;
    } catch (e) {
      debugPrint('Error checking certificate: $e');
      return false;
    }
  }
}