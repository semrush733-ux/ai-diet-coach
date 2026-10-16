import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../../../core/utils/units.dart';

/// One glucose reading. Original value + unit are kept; mg/dL is canonical.
class GlucoseEntry {
  const GlucoseEntry({
    required this.id,
    required this.valueOriginal,
    required this.unitOriginal, // mg_dl | mmol_l
    required this.valueMgDl,
    required this.context,
    required this.measuredAt,
    this.note,
  });

  final int id;
  final double valueOriginal;
  final String unitOriginal;
  final double valueMgDl;
  final String context;
  final DateTime measuredAt;
  final String? note;

  double get valueMmolL => Units.mgDlToMmolL(valueMgDl);

  Map<String, dynamic> toJson() => {
        'id': id,
        'value_original': valueOriginal,
        'unit_original': unitOriginal,
        'value_mg_dl': valueMgDl,
        'context': context,
        'measured_at': measuredAt.toIso8601String(),
        'note': note,
      };

  factory GlucoseEntry.fromJson(Map<String, dynamic> json) => GlucoseEntry(
        id: (json['id'] as num).toInt(),
        valueOriginal: (json['value_original'] as num).toDouble(),
        unitOriginal: '${json['unit_original']}',
        valueMgDl: (json['value_mg_dl'] as num).toDouble(),
        context: '${json['context']}',
        measuredAt:
            DateTime.tryParse('${json['measured_at']}') ?? DateTime.now(),
        note: json['note'] as String?,
      );
}

class HbA1cEntry {
  const HbA1cEntry(
      {required this.id, required this.valuePercent, required this.testedAt});

  final int id;
  final double valuePercent;
  final DateTime testedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'value_percent': valuePercent,
        'tested_at': testedAt.toIso8601String(),
      };

  factory HbA1cEntry.fromJson(Map<String, dynamic> json) => HbA1cEntry(
        id: (json['id'] as num).toInt(),
        valuePercent: (json['value_percent'] as num).toDouble(),
        testedAt:
            DateTime.tryParse('${json['tested_at']}') ?? DateTime.now(),
      );
}

class WeightEntry {
  const WeightEntry(
      {required this.id, required this.weightKg, required this.recordedAt});

  final int id;
  final double weightKg;
  final DateTime recordedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'weight_kg': weightKg,
        'recorded_at': recordedAt.toIso8601String(),
      };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        id: (json['id'] as num).toInt(),
        weightKg: (json['weight_kg'] as num).toDouble(),
        recordedAt:
            DateTime.tryParse('${json['recorded_at']}') ?? DateTime.now(),
      );
}

final trackingRepositoryProvider = Provider<TrackingRepository>(
    (ref) => TrackingRepository(ref.watch(localStoreProvider)));

/// On-device tracking storage: glucose, HbA1c, weight, daily water.
class TrackingRepository {
  TrackingRepository(this._store);

  final LocalStore _store;

  Future<List<T>> _readList<T>(
      String key, T Function(Map<String, dynamic>) fromJson) async {
    final json = await _store.readJson(key);
    final items = json?['items'];
    if (items is! List) return [];
    return [
      for (final item in items)
        if (item is Map<String, dynamic>) fromJson(item),
    ];
  }

  Future<void> _writeList(
      String key, List<Map<String, dynamic>> items) async {
    await _store.writeJson(key, {'items': items});
  }

  // ── Glucose ──
  Future<List<GlucoseEntry>> glucose() async {
    final list = await _readList(StoreKeys.glucose, GlucoseEntry.fromJson);
    list.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    return list;
  }

  Future<void> addGlucose({
    required double value,
    required String unit,
    required String context,
    String? note,
  }) async {
    final list = await glucose();
    final id = list.isEmpty
        ? 1
        : list.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    final mgDl = unit == 'mmol_l'
        ? Units.mmolLToMgDl(value)
        : value.toDouble();
    list.insert(
      0,
      GlucoseEntry(
        id: id,
        valueOriginal: value,
        unitOriginal: unit,
        valueMgDl: double.parse(mgDl.toStringAsFixed(1)),
        context: context,
        measuredAt: DateTime.now(),
        note: note,
      ),
    );
    await _writeList(
        StoreKeys.glucose, [for (final e in list) e.toJson()]);
  }

  Future<void> deleteGlucose(int id) async {
    final list = await glucose();
    list.removeWhere((e) => e.id == id);
    await _writeList(
        StoreKeys.glucose, [for (final e in list) e.toJson()]);
  }

  // ── HbA1c ──
  Future<List<HbA1cEntry>> hba1c() async {
    final list = await _readList(StoreKeys.hba1c, HbA1cEntry.fromJson);
    list.sort((a, b) => b.testedAt.compareTo(a.testedAt));
    return list;
  }

  Future<void> addHbA1c(double valuePercent) async {
    final list = await hba1c();
    final id = list.isEmpty
        ? 1
        : list.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    list.insert(
        0,
        HbA1cEntry(
            id: id, valuePercent: valuePercent, testedAt: DateTime.now()));
    await _writeList(StoreKeys.hba1c, [for (final e in list) e.toJson()]);
  }

  // ── Weight ──
  Future<List<WeightEntry>> weights() async {
    final list = await _readList(StoreKeys.weight, WeightEntry.fromJson);
    list.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return list;
  }

  Future<void> addWeight(double weightKg) async {
    final list = await weights();
    final id = list.isEmpty
        ? 1
        : list.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    list.insert(
        0,
        WeightEntry(
            id: id, weightKg: weightKg, recordedAt: DateTime.now()));
    await _writeList(StoreKeys.weight, [for (final e in list) e.toJson()]);
  }

  // ── Water (glasses per day) ──
  Future<int> waterToday() async {
    final json = await _store.readJson(StoreKeys.water) ?? {};
    final key = _todayKey();
    return (json[key] as num?)?.toInt() ?? 0;
  }

  Future<int> setWaterToday(int glasses) async {
    final json = await _store.readJson(StoreKeys.water) ?? {};
    final value = glasses.clamp(0, 30).toInt();
    json[_todayKey()] = value;
    await _store.writeJson(StoreKeys.water, json);
    return value;
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
