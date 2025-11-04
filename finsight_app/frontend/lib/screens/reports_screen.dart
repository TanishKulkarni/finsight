import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<FileSystemEntity> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/reports');
    if (await dir.exists()) {
      final list = await dir.list().toList();
      list.sort((a, b) => (b.statSync().modified).compareTo(a.statSync().modified));
      setState(() {
        _files = list.where((e) => e.path.toLowerCase().endsWith('.pdf')).toList();
        _loading = false;
      });
    } else {
      setState(() {
        _files = [];
        _loading = false;
      });
    }
  }

  Future<void> _share(File file) async {
    final bytes = await file.readAsBytes();
    await Printing.sharePdf(bytes: bytes, filename: file.uri.pathSegments.last);
  }

  Future<void> _open(File file) async {
    await OpenFilex.open(file.path);
  }

  Future<void> _delete(File file) async {
    await file.delete();
    await _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loadReports, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const Center(child: Text('No reports found'))
              : ListView.builder(
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = File(_files[index].path);
                    final name = file.uri.pathSegments.last;
                    final modified = file.statSync().modified;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(name),
                        subtitle: Text('Modified: ${modified.toLocal()}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share),
                              onPressed: () => _share(file),
                              tooltip: 'Share',
                            ),
                            IconButton(
                              icon: const Icon(Icons.download_rounded),
                              onPressed: () => _open(file),
                              tooltip: 'Open',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(file),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}


