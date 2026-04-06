import 'package:flutter/material.dart';
import 'package:qr_dating_app/features/qr_zone/data/zone_repository.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';

/// Gender + age filters for home discovery (same payload as zone lobby filters).
class DiscoveryFilterSheet extends StatefulWidget {
  const DiscoveryFilterSheet({super.key, required this.initial});

  final ZoneLobbyFilters initial;

  @override
  State<DiscoveryFilterSheet> createState() => _DiscoveryFilterSheetState();
}

class _DiscoveryFilterSheetState extends State<DiscoveryFilterSheet> {
  String? _gender;
  bool _useAge = false;
  late RangeValues _ageRange;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _gender = i.gender;
    _useAge = i.minAge != null || i.maxAge != null;
    final lo = (i.minAge ?? 18).clamp(18, 99).toDouble();
    final hi = (i.maxAge ?? 99).clamp(18, 99).toDouble();
    _ageRange = RangeValues(lo <= hi ? lo : hi, lo <= hi ? hi : lo);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final minLabel = _ageRange.start.round();
    final maxLabel = _ageRange.end.round();

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.zoneLobbyFilterTitle,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.zoneLobbyFilterGender,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text(l10n.zoneLobbyFilterGenderAll),
                    selected: _gender == null,
                    onSelected: (_) => setState(() => _gender = null),
                  ),
                  FilterChip(
                    label: Text(l10n.zoneLobbyFilterGenderFemale),
                    selected: _gender == 'female',
                    onSelected: (_) => setState(() => _gender = 'female'),
                  ),
                  FilterChip(
                    label: Text(l10n.zoneLobbyFilterGenderMale),
                    selected: _gender == 'male',
                    onSelected: (_) => setState(() => _gender = 'male'),
                  ),
                  FilterChip(
                    label: Text(l10n.zoneLobbyFilterGenderOther),
                    selected: _gender == 'other',
                    onSelected: (_) => setState(() => _gender = 'other'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                l10n.zoneLobbyFilterAge,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.zoneLobbyFilterAgeToggle),
                value: _useAge,
                onChanged: (v) => setState(() => _useAge = v),
              ),
              if (_useAge) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$minLabel',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$maxLabel',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: _ageRange,
                  min: 18,
                  max: 99,
                  divisions: 81,
                  labels: RangeLabels('$minLabel', '$maxLabel'),
                  onChanged: (v) => setState(() => _ageRange = v),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(ZoneLobbyFilters.none);
                      },
                      child: Text(l10n.zoneLobbyFilterClear),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(
                          ZoneLobbyFilters(
                            gender: _gender,
                            minAge: _useAge ? _ageRange.start.round() : null,
                            maxAge: _useAge ? _ageRange.end.round() : null,
                          ),
                        );
                      },
                      child: Text(l10n.zoneLobbyFilterApply),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
