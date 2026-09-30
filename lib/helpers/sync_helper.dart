import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'db_helper.dart';
import 'timezone_helper.dart';

class SyncHelper {
  static final SyncHelper instance = SyncHelper._init();
  SyncHelper._init();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Orodha ya meza za kusawazisha (SQLite -> Supabase)
  final List<String> _tables = [
    'users',
    'Seller_listing',
    'Products',
    'Orders',
    'Payments',
    'Loans',
  ];

  /// Columns za ndani ya SQLite tu, ambazo hazitumwi Supabase:
  /// - is_synced: alama ya sync ya ndani
  /// - password_hash: KAMWE isifike cloud (Supabase Auth inashughulikia password)
  final Map<String, List<String>> _localOnlyColumns = {
    'users': ['is_synced', 'password_hash'],
  };

  // Columns za aina timestamptz kwenye Supabase
  static const _tzColumns = ['created_at', 'payment_date', 'updated_at'];

  Map<String, dynamic> _buildCloudPayload(
      String table, Map<String, dynamic> record) {
    final payload = Map<String, dynamic>.from(record);

    for (final col in _localOnlyColumns[table] ?? const ['is_synced']) {
      payload.remove(col);
    }

    // SQLite inahifadhi muda wa simu (local). Supabase timestamptz inataka
    // muda wenye zone - tuma kama UTC ili tarehe zisiyumbe (Tanzania = UTC+3).
    for (final k in _tzColumns) {
      final v = payload[k];
      if (v is String && v.isNotEmpty) {
        final d = DateTime.tryParse(v);
        if (d != null) payload[k] = d.toUtc().toIso8601String();
      }
    }

    // Seller_listing.area ni ARRAY kwenye Supabase lakini TEXT (JSON) SQLite.
    if (table == 'Seller_listing' && payload['area'] is String) {
      final raw = (payload['area'] as String).trim();
      if (raw.isEmpty) {
        payload['area'] = <String>[];
      } else {
        try {
          final decoded = jsonDecode(raw);
          payload['area'] = decoded is List
              ? decoded.map((e) => e.toString()).toList()
              : [raw];
        } catch (_) {
          payload['area'] = [raw];
        }
      }
    }

    return payload;
  }

  /// SQLite -> Supabase: rusha rekodi zenye is_synced = 0
  Future<void> syncLocalToCloud() async {
    final db = await DatabaseHelper.instance.database;

    for (String table in _tables) {
      try {
        final unsynced =
            await db.query(table, where: 'is_synced = ?', whereArgs: [0]);

        for (var record in unsynced) {
          await _supabase.from(table).upsert(_buildCloudPayload(table, record));
          await DatabaseHelper.instance.markAsSynced(table, record['id']);
        }
      } catch (e) {
        debugPrint('Sync error on table $table: $e');
      }
    }
  }

  /// Supabase -> SQLite: pakua catalog yote ya bidhaa kwa mafungu.
  Future<void> pullProducts() async {
    const pageSize = 500;
    var offset = 0;

    try {
      while (true) {
        final rows = await _supabase
            .from('Products')
            .select()
            .order('id')
            .range(offset, offset + pageSize - 1);
        await _pullTable('Products', rows);

        if (rows.length < pageSize) break;
        offset += pageSize;
      }
    } catch (e) {
      debugPrint('Pull error (Products): $e');
    }
  }

  // ---------------- Supabase -> SQLite ----------------

  Map<String, dynamic> _normalizeRemote(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};
    raw.forEach((k, v) {
      if (v is bool) {
        out[k] = v ? 1 : 0;
      } else if (v is List || v is Map) {
        out[k] = jsonEncode(v);
      } else if (_tzColumns.contains(k) && v is String) {
        final d = DateTime.tryParse(v);
        out[k] = d != null ? tanzaniaTimestamp(d) : v;
      } else {
        out[k] = v;
      }
    });
    return out;
  }

  Future<void> _pullTable(String table, List<dynamic> rows) async {
    final db = await DatabaseHelper.instance.database;
    final cols = (await db.rawQuery('PRAGMA table_info($table)'))
        .map((r) => r['name'] as String)
        .toSet();

    for (final r in rows) {
      final row = _normalizeRemote(Map<String, dynamic>.from(r as Map));
      row.removeWhere((k, _) => !cols.contains(k));

      // Usiandike juu ya mabadiliko ya ndani ambayo bado hayajatumwa
      final local = await db.query(table,
          columns: ['is_synced'],
          where: 'id = ?',
          whereArgs: [row['id']],
          limit: 1);
      if (local.isNotEmpty && local.first['is_synced'] == 0) continue;

      row['is_synced'] = 1;
      await DatabaseHelper.instance.insertOrUpdate(table, row);
    }
  }

  /// Supabase -> SQLite: pakua Loans, Payments na Orders za huyu supplier
  /// (ili mtumiaji akiingia kwenye simu mpya aone data yake yote).
  Future<void> pullSupplierData(String email) async {
    Future<void> safe(String label, Future<void> Function() job) async {
      try {
        await job();
      } catch (e) {
        debugPrint('Pull error ($label): $e');
      }
    }

    await safe('Loans', () async {
      final rows =
          await _supabase.from('Loans').select().eq('supplier_id', email);
      await _pullTable('Loans', rows);
    });
    await safe('Payments', () async {
      final rows =
          await _supabase.from('Payments').select().eq('supplier_id', email);
      await _pullTable('Payments', rows);
    });
    await safe('Orders', () async {
      final rows = await _supabase
          .from('Orders')
          .select()
          .or('supplier.eq."$email",matched_supplier.eq."$email"');
      await _pullTable('Orders', rows);
    });
  }
}
