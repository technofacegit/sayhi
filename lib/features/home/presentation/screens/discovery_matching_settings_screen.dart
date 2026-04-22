import 'package:flutter/material.dart';
import 'package:qr_dating_app/features/home/data/discovery_filters_storage.dart';
import 'package:qr_dating_app/features/home/presentation/widgets/discovery_filter_form.dart';
import 'package:qr_dating_app/features/qr_zone/data/zone_repository.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';

/// Full-screen discovery / matching filters (same storage as Home + Say Hi lobby).
class DiscoveryMatchingSettingsScreen extends StatefulWidget {
  const DiscoveryMatchingSettingsScreen({super.key});

  @override
  State<DiscoveryMatchingSettingsScreen> createState() =>
      _DiscoveryMatchingSettingsScreenState();
}

class _DiscoveryMatchingSettingsScreenState
    extends State<DiscoveryMatchingSettingsScreen> {
  final DiscoveryFiltersStorage _storage = DiscoveryFiltersStorage();
  ZoneLobbyFilters _initial = ZoneLobbyFilters.none;
  bool _loading = true;
  int _formKey = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final f = await _storage.load();
    if (!mounted) return;
    setState(() {
      _initial = f;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.discoveryMatchingSettingsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: DiscoveryFilterForm(
                key: ValueKey(_formKey),
                initial: _initial,
                sheetMode: false,
                title: l10n.discoveryMatchingSettingsHeadline,
                clearButtonLabel: l10n.zoneLobbyFilterClear,
                applyButtonLabel: l10n.discoveryMatchingSettingsSave,
                onClear: () async {
                  await _storage.save(ZoneLobbyFilters.none);
                  if (!context.mounted) return;
                  setState(() {
                    _initial = ZoneLobbyFilters.none;
                    _formKey++;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.discoveryMatchingSettingsCleared),
                    ),
                  );
                },
                onApply: (f) async {
                  await _storage.save(f);
                  if (!context.mounted) return;
                  setState(() => _initial = f);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.discoveryMatchingSettingsSaved),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
