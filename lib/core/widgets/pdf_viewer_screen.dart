import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../network/dio_client.dart';
import '../theme/app_colors.dart';
import 'error_state.dart';

enum _LoadStatus { loading, generating, error, ready }

/// Visualiseur PDF générique à partir d'une URL publique (contrat de
/// bail, quittance de paiement...). Gère explicitement les états
/// chargement / génération en cours (404, job asynchrone pas encore
/// terminé) / erreur / contenu — jamais l'exception brute de PdfPreview.
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key, required this.title, required this.pdfUrl});

  final String title;
  final String pdfUrl;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  _LoadStatus _status = _LoadStatus.loading;
  Uint8List? _bytes;
  int _generatingRetries = 0;
  Timer? _retryTimer;

  static const _maxGeneratingRetries = 5;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _status = _LoadStatus.loading);

    try {
      final response = await DioClient.instance.dio.get<List<int>>(
        widget.pdfUrl,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );
      if (!mounted) return;
      setState(() {
        _bytes = Uint8List.fromList(response.data!);
        _status = _LoadStatus.ready;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      if (e.response?.statusCode == 404 &&
          _generatingRetries < _maxGeneratingRetries) {
        _generatingRetries++;
        setState(() => _status = _LoadStatus.generating);
        _retryTimer = Timer(const Duration(seconds: 4), _load);
        return;
      }

      setState(() => _status = _LoadStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      backgroundColor: AppColors.background,
      body: switch (_status) {
        _LoadStatus.loading => const Center(child: CircularProgressIndicator()),
        _LoadStatus.generating => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Génération du document en cours…',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        _LoadStatus.error => ErrorState(
          message:
              'Impossible de charger le document. Vérifie ta connexion et réessaie.',
          onRetry: () {
            _generatingRetries = 0;
            _load();
          },
        ),
        _LoadStatus.ready => PdfPreview(
          build: (format) async => _bytes!,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
        ),
      },
    );
  }
}
