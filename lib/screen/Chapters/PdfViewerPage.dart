import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../generated/l10n.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;

  PdfViewerPage({required this.pdfUrl});

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  bool _isLoading = true;
  String? _localPath;
  late PDFViewController _pdfViewController;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _downloadAndPreparePdf();
  }

  Future<void> _downloadAndPreparePdf() async {
    try {
      print("Starting PDF download from: ${widget.pdfUrl}");
      final tempDir = await getTemporaryDirectory();
      final fileName = widget.pdfUrl.split('/').last.split('?').first;
      final localFile = File('${tempDir.path}/$fileName');

      print("Saving PDF to: ${localFile.path}");

      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        await localFile.writeAsBytes(response.bodyBytes);
        print("PDF downloaded successfully, size: ${await localFile.length()} bytes");
        if (await localFile.exists()) {
          print("File exists at: ${localFile.path}");
          setState(() {
            _localPath = localFile.path;
            _isLoading = false;
          });
        } else {
          throw Exception("Downloaded file does not exist");
        }
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      print("Error downloading PDF: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${S.of(context).errorLoadingPdf} $e')),
      );
    }
  }

  void _onPdfViewCreated(PDFViewController controller) {
    _pdfViewController = controller;
    _updateTotalPages();
  }

  Future<void> _updateTotalPages() async {
    final pages = await _pdfViewController.getPageCount();
    setState(() {
      _totalPages = pages ?? 0;
    });
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      _pdfViewController.setPage(page);
      setState(() {
        _currentPage = page;
      });
    }
  }

  void _reloadPdf() {
    setState(() {
      _isLoading = true;
      _localPath = null;
    });
    _downloadAndPreparePdf();
  }

  @override
  Widget build(BuildContext context) {
    print("Building PdfViewerPage, _localPath: $_localPath, _isLoading: $_isLoading");
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pdfViewerTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _reloadPdf,
            tooltip: S.of(context).reloadPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (_isLoading)
                  Center(child: CircularProgressIndicator())
                else if (_localPath != null)
                  PDFView(
                    filePath: _localPath!,
                    onViewCreated: _onPdfViewCreated,
                    onRender: (pages) {
                      print("PDF rendered with $pages pages");
                      setState(() {
                        _totalPages = pages ?? 0;
                      });
                    },
                    onError: (error) {
                      print("PDFView error: $error");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${S.of(context).errorLoadingPdf} $error')),
                      );
                    },
                    onPageError: (page, error) {
                      print("PDFView page $page error: $error");
                    },
                    onPageChanged: (page, total) {
                      setState(() {
                        _currentPage = page ?? 0;
                        _totalPages = total ?? 0;
                      });
                    },
                  )
                else
                  Center(child: Text(S.of(context).failedToLoadPdf,)),
              ],
            ),
          ),
          if (!_isLoading && _localPath != null)
            Container(
              padding: EdgeInsets.all(8.0),
              color: Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.first_page),
                    onPressed: () => _goToPage(0),
                    tooltip: S.of(context).firstPage,
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_left),
                    onPressed: () => _goToPage(_currentPage - 1),
                    tooltip: S.of(context).previousPage,
                  ),
                  Text(
                    '${S.of(context).pageInfo} ${_currentPage + 1} de $_totalPages',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right),
                    onPressed: () => _goToPage(_currentPage + 1),
                    tooltip: S.of(context).nextPage,
                  ),
                  IconButton(
                    icon: Icon(Icons.last_page),
                    onPressed: () => _goToPage(_totalPages - 1),
                    tooltip: S.of(context).lastPage,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}