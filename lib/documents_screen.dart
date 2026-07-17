import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'document_qa_screen.dart';
import 'main.dart' show logout;
import 'theme.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _uploading = false;
  String? _statusMessage;
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    try {
      final data = await Supabase.instance.client
          .from('documents')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _documents = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint('Error fetching documents: $e');
    }
  }

  Future<void> _pickAndUploadFile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.first;
    if (pickedFile.bytes == null) {
      setState(() => _statusMessage = 'Could not read file');
      return;
    }

    setState(() {
      _uploading = true;
      _statusMessage = 'Uploading ${pickedFile.name}...';
    });

    try {
      final uri = Uri.parse(
          'https://web-production-3f04d.up.railway.app/upload-document');
      final request = http.MultipartRequest('POST', uri);
      request.fields['user_id'] = userId;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          pickedFile.bytes!,
          filename: pickedFile.name,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Upload failed: ${response.statusCode} ${response.body}');
      }

      final data = jsonDecode(response.body);
      setState(() {
        _statusMessage =
            'Uploaded! ${data['chunks_created']} chunks processed.';
      });

      await _fetchDocuments();
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _deleteDocument(Map<String, dynamic> doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Delete document?'),
        content: Text(
          '"${doc['title'] ?? 'Untitled'}" and all its processed content will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: kRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('documents')
          .delete()
          .eq('id', doc['id']);
      await _fetchDocuments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  void _openDocument(Map<String, dynamic> doc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentQaScreen(
          documentId: doc['id'],
          documentTitle: doc['title'] ?? 'Untitled',
        ),
      ),
    );
  }

  Widget _posterCard(Map<String, dynamic> doc) {
    final isReady = doc['status'] == 'ready';
    return GestureDetector(
      onTap: isReady ? () => _openDocument(doc) : null,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: kSurfaceLight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  size: 40,
                  color: isReady ? kRed : kTextSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc['title'] ?? 'Untitled',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doc['status'] ?? '',
                    style: TextStyle(
                      fontSize: 10,
                      color: isReady ? kRed : kTextSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        actions: [
          IconButton(
            onPressed: _fetchDocuments,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: _uploading ? null : _pickAndUploadFile,
            icon: const Icon(Icons.upload_file),
            label: Text(_uploading ? 'Uploading...' : 'Upload PDF'),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _statusMessage!,
              style: const TextStyle(color: kTextSecondary),
            ),
          ],
          if (_documents.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Your Library',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _documents.map(_posterCard).toList(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'All Documents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ..._documents.map((doc) {
              final isReady = doc['status'] == 'ready';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.description,
                    color: isReady ? kRed : kTextSecondary,
                  ),
                  title: Text(doc['title'] ?? 'Untitled'),
                  subtitle: Text(
                    'Status: ${doc['status']}',
                    style: const TextStyle(color: kTextSecondary),
                  ),
                  enabled: isReady,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: kTextSecondary),
                    tooltip: 'Delete document',
                    onPressed: () => _deleteDocument(doc),
                  ),
                  onTap: isReady ? () => _openDocument(doc) : null,
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: 48),
            const Center(
              child: Text(
                'No documents yet. Upload a PDF to get started.',
                style: TextStyle(color: kTextSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
