import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CertificatePdfViewerScreen extends StatefulWidget {
  final String certificateUrl;
  final String title;

  const CertificatePdfViewerScreen({
    super.key,
    required this.certificateUrl,
    required this.title
  });

  @override
  State<CertificatePdfViewerScreen> createState() => _CertificatePdfViewerScreenState();
}

class _CertificatePdfViewerScreenState extends State<CertificatePdfViewerScreen> {
  String? localPath;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _downloadAndSavePdf();
  }

  Future<void> _downloadAndSavePdf() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final response = await http.get(Uri.parse(widget.certificateUrl));

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/certificate_${DateTime.now().millisecondsSinceEpoch}.pdf');

        await file.writeAsBytes(response.bodyBytes, flush: true);

        setState(() {
          localPath = file.path;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      debugPrint("Ошибка загрузки PDF: $e");
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFFA58EFF),
        actions: [
          if (!_isLoading && !_hasError)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _downloadAndSavePdf,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFA58EFF)),
            SizedBox(height: 16),
            Text('Загрузка сертификата...'),
          ],
        ),
      );
    }

    if (_hasError || localPath == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Не удалось загрузить сертификат',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _downloadAndSavePdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA58EFF),
              ),
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      );
    }

    return SizedBox.expand(
      child: PDFView(
        filePath: localPath,
        enableSwipe: true,
        autoSpacing: false,
        pageSnap: false,
        fitPolicy: FitPolicy.BOTH,
        onError: (error) => print(error.toString()),
      ),
    );
  }
}