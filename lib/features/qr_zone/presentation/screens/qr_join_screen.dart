import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/mock_venues.dart';

/// Bottom inset so content clears [BottomAppBar] + center FAB notch when shell uses extendBody.
const double _kShellBottomClearance = 100;

class QrJoinScreen extends StatefulWidget {
  const QrJoinScreen({super.key});

  @override
  State<QrJoinScreen> createState() => _QrJoinScreenState();
}

class _QrJoinScreenState extends State<QrJoinScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _navigating = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_navigating) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue ?? barcodes.first.displayValue;
    if (code == null || code.isEmpty) return;

    _navigating = true;
    await _scannerController.stop();
    if (!mounted) return;

    await context.push<void>(
      AppRouter.activeZonePath,
      extra: MockVenues.randomScan(),
    );

    if (!mounted) return;
    _navigating = false;
    await _scannerController.start();
  }

  Future<void> _openManualCode() async {
    await _scannerController.stop();
    if (!mounted) return;

    final code = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Enter code manually'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 10,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            inputFormatters: [
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              labelText: 'Zone Code',
              hintText: 'e.g. ROOFTOP',
              counterText: '',
            ),
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) {
              final t = controller.text.trim();
              Navigator.of(ctx).pop(t.isEmpty ? null : t);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                Navigator.of(ctx).pop(t.isEmpty ? null : t);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (code != null && code.isNotEmpty) {
      await context.push<void>(
        AppRouter.activeZonePath,
        extra: MockVenues.randomScan(),
      );
    }

    if (mounted) await _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surface = colorScheme.surface;
    final mq = MediaQuery.of(context);
    final bottomPad = mq.padding.bottom + _kShellBottomClearance;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: surface,
        appBar: AppBar(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
          ),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            tooltip: 'Back',
          ),
          title: Text(
            'Join a Zone',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () => _scannerController.toggleTorch(),
              icon: const Icon(Icons.flashlight_on_rounded),
              tooltip: 'Torch',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ColoredBox(
                color: surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Point your camera at the venue QR code',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Center(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final maxSide = math.min(
                                constraints.maxWidth * 0.92,
                                constraints.maxHeight * 0.95,
                              );
                              final side = maxSide.clamp(200.0, 420.0);
                              return SizedBox(
                                width: side,
                                height: side,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: colorScheme.outline
                                          .withValues(alpha: 0.45),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.shadow
                                            .withValues(alpha: 0.08),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: MobileScanner(
                                      controller: _scannerController,
                                      onDetect: _onBarcodeDetected,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error) {
                                        return ColoredBox(
                                          color: colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.5),
                                          child: Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.camera_alt_outlined,
                                                    size: 40,
                                                    color: colorScheme.error,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    error.errorDetails
                                                            ?.message ??
                                                        error.toString(),
                                                    textAlign: TextAlign.center,
                                                    style: theme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: colorScheme
                                                          .onSurface
                                                          .withValues(
                                                              alpha: 0.75),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad),
              color: surface,
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _openManualCode,
                  icon: const Icon(Icons.keyboard_rounded, size: 20),
                  label: const Text('Enter code manually'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
