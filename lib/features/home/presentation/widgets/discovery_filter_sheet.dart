import 'package:flutter/material.dart';
import 'package:qr_dating_app/features/home/data/discovery_country_repository.dart';
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
  static const List<String> _fallbackCountryOptions = <String>[
    'Turkey',
    'United States',
    'United Kingdom',
    'Germany',
    'France',
    'Spain',
    'Italy',
    'Netherlands',
    'Canada',
    'Australia',
  ];
  final DiscoveryCountryRepository _countryRepository =
      DiscoveryCountryRepository();
  String? _gender;
  bool _useAge = false;
  late RangeValues _ageRange;
  bool _useDistance = false;
  double _distanceKm = 50;
  late Set<String> _selectedCountries;
  late final TextEditingController _countryQueryController;
  final ScrollController _sheetScrollController = ScrollController();
  List<String> _countryOptions = _fallbackCountryOptions;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _gender = i.gender;
    _useAge = i.minAge != null || i.maxAge != null;
    final lo = (i.minAge ?? 18).clamp(18, 99).toDouble();
    final hi = (i.maxAge ?? 99).clamp(18, 99).toDouble();
    _ageRange = RangeValues(lo <= hi ? lo : hi, lo <= hi ? hi : lo);
    _useDistance = i.maxDistanceKm != null;
    _distanceKm = (i.maxDistanceKm ?? 50).clamp(1, 500).toDouble();
    _selectedCountries = <String>{...(i.countries ?? const <String>[])};
    _countryQueryController = TextEditingController();
    _loadCountryOptions();
  }

  Future<void> _loadCountryOptions() async {
    try {
      final names = await _countryRepository.fetchCountryNames();
      if (!mounted || names.isEmpty) return;
      setState(() {
        _countryOptions = names;
      });
    } catch (_) {
      // keep fallback options
    }
  }

  @override
  void dispose() {
    _countryQueryController.dispose();
    _sheetScrollController.dispose();
    super.dispose();
  }

  void _updateAndKeepBottom(VoidCallback update) {
    if (!mounted) return;
    setState(update);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sheetScrollController.hasClients) return;
      _sheetScrollController.jumpTo(
        _sheetScrollController.position.maxScrollExtent,
      );
      Future<void>.delayed(const Duration(milliseconds: 60), () {
        if (!mounted || !_sheetScrollController.hasClients) return;
        _sheetScrollController.jumpTo(
          _sheetScrollController.position.maxScrollExtent,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final minLabel = _ageRange.start.round();
    final maxLabel = _ageRange.end.round();
    final countryQuery = _countryQueryController.text.trim().toLowerCase();
    final showCountrySuggestions = countryQuery.isNotEmpty;
    final countrySuggestions = _countryOptions
        .where((c) {
          if (_selectedCountries.contains(c)) return false;
          return c.toLowerCase().contains(countryQuery);
        })
        .toList(growable: false);

    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _sheetScrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.zoneLobbyFilterTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.zoneLobbyFilterGender,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
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
                              onSelected: (_) =>
                                  _updateAndKeepBottom(() => _gender = null),
                            ),
                            FilterChip(
                              label: Text(l10n.zoneLobbyFilterGenderFemale),
                              selected: _gender == 'female',
                              onSelected: (_) => _updateAndKeepBottom(
                                () => _gender = 'female',
                              ),
                            ),
                            FilterChip(
                              label: Text(l10n.zoneLobbyFilterGenderMale),
                              selected: _gender == 'male',
                              onSelected: (_) =>
                                  _updateAndKeepBottom(() => _gender = 'male'),
                            ),
                            FilterChip(
                              label: Text(l10n.zoneLobbyFilterGenderOther),
                              selected: _gender == 'other',
                              onSelected: (_) =>
                                  _updateAndKeepBottom(() => _gender = 'other'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.zoneLobbyFilterAge,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.zoneLobbyFilterAgeToggle),
                          value: _useAge,
                          onChanged: (v) =>
                              _updateAndKeepBottom(() => _useAge = v),
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
                            onChanged: (v) =>
                                _updateAndKeepBottom(() => _ageRange = v),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text(
                          l10n.discoveryFilterCountry,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _countryQueryController,
                          onChanged: (_) => _updateAndKeepBottom(() {}),
                          decoration: InputDecoration(
                            hintText: l10n.discoveryFilterCountryHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                        ),
                        if (_selectedCountries.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final c in _selectedCountries)
                                InputChip(
                                  label: Text(c),
                                  onDeleted: () {
                                    _updateAndKeepBottom(
                                      () => _selectedCountries.remove(c),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                        if (showCountrySuggestions) ...[
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                for (final c in countrySuggestions)
                                  ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(c),
                                    onTap: () {
                                      _updateAndKeepBottom(() {
                                        _selectedCountries.add(c);
                                        _countryQueryController.clear();
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text(
                          l10n.discoveryFilterDistance,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.discoveryFilterDistanceToggle),
                          value: _useDistance,
                          onChanged: (v) =>
                              _updateAndKeepBottom(() => _useDistance = v),
                        ),
                        if (_useDistance) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_distanceKm.round()} km',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _distanceKm,
                            min: 1,
                            max: 500,
                            divisions: 499,
                            label: '${_distanceKm.round()} km',
                            onChanged: (v) =>
                                _updateAndKeepBottom(() => _distanceKm = v),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                              countries: _selectedCountries.isEmpty
                                  ? null
                                  : _selectedCountries.toList(growable: false),
                              maxDistanceKm: _useDistance
                                  ? _distanceKm.round()
                                  : null,
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
      ),
    );
  }
}
