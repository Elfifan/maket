import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final String assetPath;
  final String title;

  const PdfViewerScreen({super.key, required this.assetPath, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;

  @override
  void initState() {
    super.initState();
    // Сначала копируем файл из ассетов в память телефона
    _prepareFile();
  }

  Future<void> _prepareFile() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      final bytes = data.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/temp_terms.pdf');
      
      await file.writeAsBytes(bytes, flush: true);
      
      setState(() {
        localPath = file.path;
      });
    } catch (e) {
      debugPrint("Ошибка подготовки файла: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: const Color(0xFFA58EFF)),
      body: localPath != null
          ? PDFView(
              filePath: localPath,
              enableSwipe: true,
              autoSpacing: true,
              pageSnap: true,
              onError: (error) => print(error.toString()),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}