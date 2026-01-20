import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../data/providers/core_providers.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';

final documentsProvider = FutureProvider.autoDispose((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.documents);
  final data = response.data['data'];
  
  if (data is List) {
    return data;
  } else if (data is Map && data.containsKey('results')) {
    return data['results'] as List;
  }
  return [];
});

class DocumentListScreen extends ConsumerWidget {
  const DocumentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _showUploadDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(documentsProvider);
        },
        child: documentsAsync.when(
          data: (documents) {
            if (documents.isEmpty) {
              return EmptyState(
                icon: Icons.file_copy_outlined,
                title: 'No Documents',
                message: 'Upload your documents for verification',
                action: ElevatedButton.icon(
                  onPressed: () => _showUploadDialog(context, ref),
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Document'),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: documents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = documents[index];
                return _DocumentCard(document: doc);
              },
            );
          },
          loading: () => const LoadingIndicator(),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadDialog(context, ref),
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
    );
  }

  Future<void> _showUploadDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    String selectedCategory = 'IDENTIFICATION';

    final categories = [
      'IDENTIFICATION',
      'PROOF_OF_INCOME',
      'RESIDENCE_PROOF',
      'OTHER',
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Upload Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Document Title',
                  hintText: 'Enter title',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                items: categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat.replaceAll('_', ' ')),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedCategory = value!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }

                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                );

                if (result != null && context.mounted) {
                  Navigator.pop(context);
                  await _uploadDocument(
                    context,
                    ref,
                    titleController.text,
                    selectedCategory,
                    result.files.first,
                  );
                }
              },
              child: const Text('Select File'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadDocument(
    BuildContext context,
    WidgetRef ref,
    String title,
    String category,
    PlatformFile file,
  ) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final formData = FormData.fromMap({
        'title': title,
        'category': category,
        'file': await MultipartFile.fromFile(file.path!, filename: file.name),
      });

      await apiClient.uploadFile(ApiEndpoints.documents, formData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(documentsProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _DocumentCard extends StatelessWidget {
  final Map<String, dynamic> document;

  const _DocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    final status = document['status'] as String;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'VERIFIED':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'PENDING':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.description, color: Colors.blue),
        ),
        title: Text(
          document['title'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          (document['category'] as String).replaceAll('_', ' '),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 4),
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
