import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/certificate_model.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';

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

      // Генерируем PDF
      final pdfBytes = await _generateCertificatePdf(user, course);

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
      );

      return certificate;
    } catch (e) {
      print('Error generating certificate: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _findCertificateRow(int userId, int courseId) async {
    try {
      final response = await _supabase
          .from('certificates')
          .select()
          .eq('id_user', userId)
          .eq('id_courses', courseId)
          .order('id', ascending: true)
          .limit(1) as List<dynamic>?;

      if (response == null || response.isEmpty) {
        return null;
      }

      return Map<String, dynamic>.from(response.first as Map<String, dynamic>);
    } catch (e) {
      print('Error finding certificate row: $e');
      return null;
    }
  }

  Future<CertificateModel?> getCertificate(int userId, int courseId) async {
    final row = await _findCertificateRow(userId, courseId);
    if (row == null) {
      return null;
    }

    return CertificateModel.fromJson(row);
  }

  Future<Uint8List> _generateCertificatePdf(UserModel user, CourseModel course) async {
    final pdf = pw.Document();

    // Load Roboto fonts
    final regularFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final boldFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue, width: 3),
              gradient: pw.LinearGradient(
                colors: [PdfColors.white, PdfColors.grey100],
                begin: pw.Alignment.topCenter,
                end: pw.Alignment.bottomCenter,
              ),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Text(
                    'СЕРТИФИКАТ',
                    style: pw.TextStyle(
                      fontSize: 42,
                      color: PdfColors.white,
                      font: boldFont,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Text(
                  'О ЗАВЕРШЕНИИ КУРСА',
                  style: pw.TextStyle(
                    fontSize: 28,
                    color: PdfColors.blue900,
                    font: boldFont,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 50),
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue200, width: 1),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text(
                    'Настоящим удостоверяется, что',
                    style: pw.TextStyle(
                      fontSize: 20,
                      font: regularFont,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    user.name ?? 'Пользователь',
                    style: pw.TextStyle(
                      fontSize: 32,
                      color: PdfColors.blue,
                      font: boldFont,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Text(
                  'успешно завершил(а) курс',
                  style: pw.TextStyle(
                    fontSize: 20,
                    font: regularFont,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 30),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    border: pw.Border.all(color: PdfColors.green, width: 2),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text(
                    course.name,
                    style: pw.TextStyle(
                      fontSize: 26,
                      color: PdfColors.green,
                      font: boldFont,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 50),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          'Дата выдачи:',
                          style: pw.TextStyle(
                            fontSize: 16,
                            font: regularFont,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          DateTime.now().toString().split(' ')[0],
                          style: pw.TextStyle(
                            fontSize: 18,
                            font: boldFont,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          'Код верификации:',
                          style: pw.TextStyle(
                            fontSize: 16,
                            font: regularFont,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          _uuid.v4().substring(0, 8).toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 18,
                            font: boldFont,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<String?> _uploadPdfToStorage(Uint8List pdfBytes, String fileName) async {
    try {
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
    } catch (e) {
      print('Error uploading PDF: $e');
      if (e.toString().contains('Bucket not found')) {
        print('Please create a bucket named "certificates" in Supabase Storage with public access.');
      }
      return null;
    }
  }

  Future<CertificateModel?> _createCertificateRecord({
    required int userId,
    required int courseId,
    required String certificateUrl,
  }) async {
    try {
      final verificationCode = _uuid.v4().substring(0, 8).toUpperCase();

      final response = await _supabase
          .from('certificates')
          .insert({
            'id_user': userId,
            'id_courses': courseId,
            'certificate_url': certificateUrl,
            'verification_code': verificationCode,
          })
          .select()
          .single();

      return CertificateModel.fromJson(response);
    } catch (e) {
      print('Error creating certificate record: $e');
      return null;
    }
  }

  Future<bool> hasCertificate(int userId, int courseId) async {
    try {
      final row = await _findCertificateRow(userId, courseId);
      return row != null;
    } catch (e) {
      print('Error checking certificate: $e');
      return false;
    }
  }
}