import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:qr_dating_app/features/qr_zone/data/zone_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists [ZoneLobbyFilters] for home discovery.
///
/// When signed in, preferences are stored in Supabase (`user_discovery_filters`)
/// so they survive app reinstall after login. Local [SharedPreferences] is used
/// as cache and for signed-out sessions.
class DiscoveryFiltersStorage {
  DiscoveryFiltersStorage({SupabaseClient? client, SharedPreferences? prefs})
    : _client = client ?? Supabase.instance.client,
      _prefsOverride = prefs;

  static const _table = 'user_discovery_filters';
  static const _localKey = 'discovery_filters_v1';
  static final ValueNotifier<int> filtersRevision = ValueNotifier<int>(0);

  final SupabaseClient _client;
  final SharedPreferences? _prefsOverride;

  Future<SharedPreferences> _prefs() async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  /// Returns [ZoneLobbyFilters.none] if nothing stored or parse fails.
  Future<ZoneLobbyFilters> load() async {
    final uid = _client.auth.currentUser?.id;
    if (uid != null) {
      try {
        final row = await _client
            .from(_table)
            .select(
              'gender, min_age, max_age, countries, country, max_distance_km',
            )
            .eq('user_id', uid)
            .maybeSingle();
        if (_client.auth.currentUser?.id != uid) {
          return _loadLocal();
        }
        if (row == null) {
          await _clearLocal();
          return ZoneLobbyFilters.none;
        }
        final f = _filtersFromRow(Map<String, dynamic>.from(row));
        await _writeLocal(f);
        return f;
      } catch (_) {
        return _loadLocal();
      }
    }
    return _loadLocal();
  }

  /// Clears remote row (when signed in) and local prefs when [filters] is empty.
  Future<void> save(ZoneLobbyFilters filters) async {
    final uid = _client.auth.currentUser?.id;
    if (!filters.hasAny) {
      await _clearLocal();
      if (uid != null) {
        try {
          await _client.from(_table).delete().eq('user_id', uid);
        } catch (_) {}
      }
      filtersRevision.value++;
      return;
    }

    await _writeLocal(filters);

    if (uid == null) return;

    try {
      await _client.from(_table).upsert(<String, dynamic>{
        'user_id': uid,
        'gender': filters.gender,
        'min_age': filters.minAge,
        'max_age': filters.maxAge,
        'countries': filters.countries,
        'max_distance_km': filters.maxDistanceKm,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (_) {}
    filtersRevision.value++;
  }

  Future<ZoneLobbyFilters> _loadLocal() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_localKey);
    if (raw == null || raw.isEmpty) {
      return ZoneLobbyFilters.none;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return ZoneLobbyFilters.none;
      final m = Map<String, dynamic>.from(decoded);
      return ZoneLobbyFilters(
        gender: m['gender'] as String?,
        minAge: _readInt(m['minAge']),
        maxAge: _readInt(m['maxAge']),
        countries:
            _readStringList(m['countries']) ??
            _readSingleCountryFallback(m['country']),
        maxDistanceKm: _readInt(m['maxDistanceKm']),
      );
    } catch (_) {
      return ZoneLobbyFilters.none;
    }
  }

  Future<void> _writeLocal(ZoneLobbyFilters filters) async {
    final prefs = await _prefs();
    if (!filters.hasAny) {
      await prefs.remove(_localKey);
      return;
    }
    final payload = <String, dynamic>{
      if (filters.gender != null) 'gender': filters.gender,
      if (filters.minAge != null) 'minAge': filters.minAge,
      if (filters.maxAge != null) 'maxAge': filters.maxAge,
      if (filters.countries != null && filters.countries!.isNotEmpty)
        'countries': filters.countries,
      if (filters.maxDistanceKm != null) 'maxDistanceKm': filters.maxDistanceKm,
    };
    await prefs.setString(_localKey, jsonEncode(payload));
  }

  Future<void> _clearLocal() async {
    final prefs = await _prefs();
    await prefs.remove(_localKey);
  }

  static ZoneLobbyFilters _filtersFromRow(Map<String, dynamic> row) {
    final gender = row['gender'] as String?;
    final minAge = _readInt(row['min_age']);
    final maxAge = _readInt(row['max_age']);
    final countries =
        _readStringList(row['countries']) ??
        _readSingleCountryFallback(row['country']);
    final maxDistanceKm = _readInt(row['max_distance_km']);
    return ZoneLobbyFilters(
      gender: gender,
      minAge: minAge,
      maxAge: maxAge,
      countries: countries,
      maxDistanceKm: maxDistanceKm,
    );
  }

  static int? _readInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  static List<String>? _readStringList(Object? value) {
    if (value is! List) return null;
    final out = <String>[];
    for (final e in value) {
      final s = e?.toString().trim() ?? '';
      if (s.isNotEmpty) out.add(s);
    }
    return out.isEmpty ? null : out;
  }

  static List<String>? _readSingleCountryFallback(Object? value) {
    final s = value?.toString().trim() ?? '';
    if (s.isEmpty) return null;
    return <String>[s];
  }
}
