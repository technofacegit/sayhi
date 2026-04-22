import 'package:flutter/material.dart';
import 'package:qr_dating_app/features/home/presentation/widgets/discovery_filter_form.dart';
import 'package:qr_dating_app/features/qr_zone/data/zone_repository.dart';

/// Gender + age + country + distance filters for home discovery (same as zone lobby).
class DiscoveryFilterSheet extends StatelessWidget {
  const DiscoveryFilterSheet({super.key, required this.initial});

  final ZoneLobbyFilters initial;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: DiscoveryFilterForm(
                initial: initial,
                sheetMode: true,
                onClear: () async {
                  Navigator.of(context).pop(ZoneLobbyFilters.none);
                },
                onApply: (f) async {
                  Navigator.of(context).pop(f);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
