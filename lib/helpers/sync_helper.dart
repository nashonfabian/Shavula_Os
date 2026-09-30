import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'db_helper.dart';
import 'timezone_helper.dart';

class SyncHelper with WidgetsBindingObserver {
  static final SyncHelper instance = SyncHelper._init();
  SyncHelper._init();

  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _syncInProgress = false;
  bool _syncRequestedAgain = false;
  String? _activeSupplierEmail;

  // Orodha ya meza za kusawazisha (SQLite -> Supabase)
  final List<String> _tables = [
    'users',
    'Seller_listing',
    'Products',
    'Orders',
    'Loans',
    'Payments',
  ];

  /// Columns za ndani ya SQLite tu, ambazo hazitumwi Supabase:
  /// - is_synced: alama ya sync ya ndani
  /// - password_hash: KAMWE isifike cloud (Supabase Auth inashughulikia password)
  final Map<String, List<String>> _localOnlyColumns = {
    'users': ['is_synced', 'password_hash'],
  };

  // Columns za aina timestamptz kwenye Supabase
  static const _tzColumns = ['created_at', 'payment_date', 'updated_at'];

  void startAutoSync() {
    if (_connectivitySubscription != null) return;

    WidgetsBinding.instance.addObserver(this);
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (result) {
        if (result != ConnectivityResult.none) {
          unawaited(syncForActiveSupplier());
        }
      },
      onError: (Object error) =>
          debugPrint('Connectivity listener error: $error'),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(syncForActiveSupplier());
    }
  }

  void setActiveSupplier(String? email) {
    _activeSupplierEmail = email?.trim().toLowerCase();
  }

  void clearActiveSupplier() {
    _activeSupplierEmail = null;
  }

  Future<void> syncForActiveSupplier() async {
    await syncLocalToCloud();
    final email = _activeSupplierEmail;
    if (email == null || email.isEmpty) return;

    await pullSupplierData(email);
    await pullProducts();
  }

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
    if (_syncInProgress) {
      _syncRequestedAgain = true;
      return;
    }

    _syncInProgress = true;
    try {
      do {
        _syncRequestedAgain = false;
        await _syncLocalToCloudPass();
      } while (_syncRequestedAgain);
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> _syncLocalToCloudPass() async {
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

    await safe('users', () async {
      final rows = await _supabase
          .from('users')
          .select()
          .eq('supplier_id', email);
      await _pullSupplierProfile(rows);
    });
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
    await safe('Seller_listing', () async {
      final rows = await _supabase
          .from('Seller_listing')
          .select()
          .eq('supplier_email', email);
      await _pullTable('Seller_listing', rows);
    });
    await safe('Orders', () async {
      final rows = await _supabase
          .from('Orders')
          .select()
          .or('supplier.eq."$email",matched_supplier.eq."$email"');
      await _pullTable('Orders', rows);
    });
  }

  Future<void> _pullSupplierProfile(List<dynamic> rows) async {
    final db = await DatabaseHelper.instance.database;
    final columns = (await db.rawQuery('PRAGMA table_info(users)'))
        .map((row) => row['name'] as String)
        .toSet();

    for (final remote in rows) {
      final row = _normalizeRemote(Map<String, dynamic>.from(remote as Map));
      row.removeWhere((key, _) => !columns.contains(key));

      final local = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [row['id']],
        limit: 1,
      );
      if (local.isNotEmpty && local.first['is_synced'] == 0) continue;

      // Keep the local offline credential; it must never be replaced by cloud data.
      if (local.isNotEmpty) {
        row['password_hash'] = local.first['password_hash'];
      }
      row['is_synced'] = 1;
      await DatabaseHelper.instance.insertOrUpdate('users', row);
    }
  }
}
