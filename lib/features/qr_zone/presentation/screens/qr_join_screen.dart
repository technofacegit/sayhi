import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/core/active_zone_session.dart';
import 'package:qr_dating_app/features/qr_zone/data/zone_repository.dart';
import 'package:qr_dating_app/features/qr_zone/domain/zone_code_input.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bottom inset so content clears [BottomAppBar] + center FAB notch when shell uses extendBody.
const double _kShellBottomClearance = 100;

class QrJoinScreen extends StatefulWidget {
  final String? expectedZoneId;

  const QrJoinScreen({super.key, this.expectedZoneId});

  @override
  State<QrJoinScreen> createState() => _QrJoinScreenState();
}

class _QrJoinScreenState extends State<QrJoinScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _navigating = false;
  bool _joining = false;

  Future<void> _vibrateLong() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.heavyImpact();
  }

  Future<void> _showCenteredError(String message) async {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => IgnorePointer(
        ignoring: true,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    await Future<void>.delayed(const Duration(milliseconds: 1700));
    entry.remove();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<bool> _joinWithCode(String rawCode) async {
    final l10n = context.l10n;
    final code = normalizeZoneCodeForJoin(rawCode);
    if (code.isEmpty) return false;
    if (mounted) {
      setState(() => _joining = true);
    }
    await _vibrateLong();

    try {
      final zone = widget.expectedZoneId != null
          ? await ZoneRepository().joinZoneByIdAndCode(
              zoneId: widget.expectedZoneId!,
              code: code,
            )
          : await ZoneRepository().joinZoneByCode(code);
      ActiveZoneSession.enterZone(zone);
      if (mounted) {
        context.go(AppRouter.zoneMainPath);
      }
      return true;
    } on AuthException catch (e, st) {
      debugPrint('joinZoneByCode AuthException: $e');
      debugPrint('$st');
      if (mounted) {
        setState(() => _joining = false);
      }
      final message = e.message.contains('INVALID_ZONE_CODE') ||
              e.message.contains('ZONE_CODE_MISMATCH')
          ? l10n.qrJoinInvalidCode
          : e.message;
      await _showCenteredError(message);
      return false;
    } catch (e, st) {
      debugPrint('joinZoneByCode error: $e');
      debugPrint('$st');
      if (mounted) {
        setState(() => _joining = false);
      }
      final message = e.toString().contains('INVALID_ZONE_CODE') ||
              e.toString().contains('ZONE_CODE_MISMATCH')
          ? l10n.qrJoinInvalidCode
          : l10n.qrJoinFailed(e.toString());
      await _showCenteredError(message);
      return false;
    } finally {
      if (mounted) {
        setState(() => _joining = false);
      }
    }
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

    final success = await _joinWithCode(code);

    if (!mounted) return;
    if (!success) {
      _navigating = false;
      await _scannerController.start();
    }
  }

  Future<void> _openManualCode() async {
    await _scannerController.stop();
    if (!mounted) return;

    final code = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final dialogL10n = ctx.l10n;
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(dialogL10n.qrJoinManualTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 64,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            inputFormatters: [
              LengthLimitingTextInputFormatter(64),
            ],
            decoration: InputDecoration(
              labelText: dialogL10n.qrJoinZoneCodeLabel,
              hintText: dialogL10n.qrJoinZoneCodeHint,
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
              child: Text(dialogL10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                Navigator.of(ctx).pop(t.isEmpty ? null : t);
              },
              child: Text(dialogL10n.commonContinue),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    var joined = false;
    if (code != null && code.isNotEmpty) {
      joined = await _joinWithCode(code);
    }

    if (mounted && !joined) await _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
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
            tooltip: l10n.commonBack,
          ),
          title: Text(
            l10n.qrJoinTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () => _scannerController.toggleTorch(),
              icon: const Icon(Icons.flashlight_on_rounded),
              tooltip: l10n.qrJoinTorch,
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
                        l10n.qrJoinCameraHint,
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
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        MobileScanner(
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
                                        if (_joining)
                                          ColoredBox(
                                            color: Colors.black.withValues(alpha: 0.35),
                                            child: Center(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: 0.65),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2.2,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      l10n.qrJoinVerifying,
                                                      style: theme.textTheme.bodyMedium
                                                          ?.copyWith(color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                              ),
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
                  onPressed: _joining ? null : _openManualCode,
                  icon: const Icon(Icons.keyboard_rounded, size: 20),
                  label: Text(l10n.qrJoinEnterManually),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
