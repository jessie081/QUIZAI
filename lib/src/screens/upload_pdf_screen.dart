import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../app_router.dart';
import '../providers.dart';
import '../widgets/app_shell_app_bar.dart';
import '../widgets/app_status_banner.dart';

class UploadPdfScreen extends ConsumerStatefulWidget {
  const UploadPdfScreen({super.key});

  @override
  ConsumerState<UploadPdfScreen> createState() => _UploadPdfScreenState();
}

class _UploadPdfScreenState extends ConsumerState<UploadPdfScreen> {
  final Uuid _uuid = const Uuid();
  PlatformFile? _selectedFile;
  bool _isPicking = false;
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _pickPdf() async {
    setState(() {
      _isPicking = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['pdf'],
        withData: true,
      );

      if (!mounted || result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final extension = file.extension?.toLowerCase();
      if (extension != 'pdf') {
        setState(() {
          _errorMessage = 'Please choose a valid PDF file.';
        });
        return;
      }

      setState(() {
        _selectedFile = file;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Unable to open the file picker right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  Future<void> _processPdf() async {
    final file = _selectedFile;
    if (file == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      if (file.bytes == null && (kIsWeb || file.path == null)) {
        setState(() {
          _errorMessage =
              'This PDF could not be read from the device. Try selecting it again.';
        });
        return;
      }

      final nativePath = !kIsWeb ? file.path : null;
      final document = await ref.read(pdfRepositoryProvider).processDocument(
        id: _uuid.v4(),
        fileName: file.name,
        filePath: nativePath ?? file.name,
        nativePath: nativePath,
        bytes: file.bytes,
      );

      if (document.extractedText.trim().isEmpty) {
        setState(() {
          _errorMessage =
              'We could not extract readable text from this PDF. Try another file.';
        });
        return;
      }

      await ref.read(currentPdfProvider.notifier).setDocument(document);

      if (!mounted) {
        return;
      }

      Navigator.pushNamed(
        context,
        AppRoutes.pdfProcessing,
        arguments: PdfProcessingRouteArgs(document: document),
      );
    } catch (error) {
      setState(() {
        _errorMessage = 'PDF processing failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) {
      return '0 B';
    }

    const units = <String>['B', 'KB', 'MB', 'GB'];
    final index = (math.log(bytes) / math.log(1024)).floor();
    final size = bytes / math.pow(1024, index);
    return '${size.toStringAsFixed(decimals)} ${units[index]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedPath = kIsWeb
        ? 'Browser upload'
        : (_selectedFile?.path ?? 'In-memory upload');

    return Scaffold(
      appBar: const AppShellAppBar(title: 'Upload PDF'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD0D5DD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upload one PDF', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Pick a reviewer, module, or handout. The app will extract text, then send you straight into the study flow.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isPicking ? null : _pickPdf,
                      icon: _isPicking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.attach_file_rounded),
                      label:
                          Text(_isPicking ? 'Opening picker...' : 'Select PDF'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedFile != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD0D5DD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ready to process', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 14),
                    _InfoRow(label: 'Name', value: _selectedFile!.name),
                    const SizedBox(height: 10),
                    _InfoRow(
                      label: 'Size',
                      value: _formatBytes(_selectedFile!.size),
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(label: 'Source', value: selectedPath),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _processPdf,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded),
                        label: Text(
                          _isProcessing
                              ? 'Preparing study workspace...'
                              : 'Continue',
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD0D5DD)),
                ),
                child: Text(
                  'No file selected yet. Choose one PDF to continue.',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              AppStatusBanner(
                icon: Icons.warning_amber_rounded,
                title: 'Upload issue',
                message: _errorMessage!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF475467),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
