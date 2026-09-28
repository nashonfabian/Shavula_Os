import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';
import 'sync_helper.dart';
import 'timezone_helper.dart';

enum ReportPeriod { leo, wiki, mwezi }

class ReportData {
  final double collected;
  final double outstanding;
  final int activeCount;
  final List<Map<String, dynamic>> dueLoans;
  ReportData({
    required this.collected,
    required this.outstanding,
    required this.activeCount,
    required this.dueLoans,
  });
}

// ---------- Vifaa vidogo vya kuonyesha data ----------

String fmtMoney(num? n) {
  final v = (n ?? 0).round();
  final s = v.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return v < 0 ? '-$buf' : buf.toString();
}

String dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// "2026-09-28T..." -> "28/09/2026"
String fmtDate(dynamic iso) {
  final s = '${iso ?? ''}';
  if (s.length < 10) return '-';
  final p = s.substring(0, 10).split('-');
  if (p.length != 3) return '-';
  return '${p[2]}/${p[1]}/${p[0]}';
}

/// 0765959032 -> 255765959032 (kwa WhatsApp)
String intlPhone(String phone) {
  var d = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.startsWith('0')) d = '255${d.substring(1)}';
  return d;
}

class SupplierHelper {
  static final SupplierHelper instance = SupplierHelper._();
  SupplierHelper._();

  // Kazi "hai" = si imekamilika wala imefutwa
  static const _live =
      "COALESCE(status,'active') NOT IN ('completed','deleted')";
  static const _notDeleted = "COALESCE(status,'active') != 'deleted'";
  static const _orderMine = '(supplier = ? OR matched_supplier = ?)';

  Future<Database> get _db => DatabaseHelper.instance.database;

  void _syncSoon() => unawaited(SyncHelper.instance.syncLocalToCloud());

  // ---------------- Dashibodi ----------------

  Future<Map<String, int>> stats(String email) async {
    final db = await _db;
    final today = dateOnly(tanzaniaNow());
    Future<int> count(String sql, List<Object?> args) async =>
        Sqflite.firstIntValue(await db.rawQuery(sql, args)) ?? 0;

    return {
      'pendingRequests': await count(
          "SELECT COUNT(*) FROM Orders WHERE LOWER(status) = 'pending' AND $_orderMine",
          [email, email]),
      'totalCustomers': await count(
          "SELECT COUNT(DISTINCT COALESCE(customer_id, customer_phone, customer_name)) FROM Loans WHERE supplier_id = ? AND $_notDeleted",
          [email]),
      'overdueJobs': await count(
          "SELECT COUNT(*) FROM Loans WHERE supplier_id = ? AND $_live AND substr(due_date,1,10) < ?",
          [email, today]),
      'todayJobs': await count(
          "SELECT COUNT(*) FROM Loans WHERE supplier_id = ? AND $_live AND substr(due_date,1,10) = ?",
          [email, today]),
    };
  }

  // ---------------- Maombi (Orders) ----------------

  Future<List<Map<String, dynamic>>> pendingOrders(String email) async {
    final db = await _db;
    return db.rawQuery(
        "SELECT * FROM Orders WHERE LOWER(status) = 'pending' AND $_orderMine ORDER BY created_at DESC",
        [email, email]);
  }

  Future<void> updateOrder(int id,
      {required String status, String? reason}) async {
    final db = await _db;
    await db.update(
      'Orders',
      {
        'status': status,
        if (reason != null) 'reason': reason,
        'is_synced': 0,
        'updated_at': tanzaniaTimestamp(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _syncSoon();
  }

  // ---------------- Wateja / Mikopo (Loans) ----------------

  /// mode: 'all' | 'overdue' | 'today'
  Future<List<Map<String, dynamic>>> loans(String email,
      {String mode = 'all'}) async {
    final db = await _db;
    final today = dateOnly(tanzaniaNow());
    switch (mode) {
      case 'overdue':
        return db.rawQuery(
            "SELECT * FROM Loans WHERE supplier_id = ? AND $_live AND substr(due_date,1,10) < ? ORDER BY due_date ASC",
            [email, today]);
      case 'today':
        return db.rawQuery(
            "SELECT * FROM Loans WHERE supplier_id = ? AND $_live AND substr(due_date,1,10) = ? ORDER BY customer_name ASC",
            [email, today]);
      default:
        return db.rawQuery(
            "SELECT * FROM Loans WHERE supplier_id = ? AND $_notDeleted ORDER BY start_date DESC, id DESC",
            [email]);
    }
  }

  /// Wateja tofauti waliokwisha sajiliwa (kwa dropdown ya fomu ya usajili)
  Future<List<Map<String, dynamic>>> knownCustomers(String email) async {
    final db = await _db;
    return db.rawQuery(
        "SELECT COALESCE(customer_id, customer_phone) AS cid, customer_name, customer_phone, customer_location "
        "FROM Loans WHERE supplier_id = ? AND $_notDeleted GROUP BY cid ORDER BY customer_name",
        [email]);
  }

  Future<int> createLoan({
    required String supplierEmail,
    required String customerId,
    required String name,
    required String phone,
    required String area,
    required String product,
    required double total,
    required double deposit,
    required double daily,
    required DateTime start,
  }) async {
    final db = await _db;
    // Id kubwa kutoka muda ili isigongane na id za Supabase wakati wa sync
    final id = DateTime.now().microsecondsSinceEpoch;
    final now = tanzaniaTimestamp();
    final remaining = total - deposit;
    final firstDue = DateTime(start.year, start.month, start.day)
        .add(const Duration(days: 1));

    await db.insert('Loans', {
      'id': id,
      'created_at': now,
      'updated_at': now,
      'amount_paid': deposit,
      'customer_id': customerId,
      'customer_location': area,
      'customer_name': name,
      'customer_phone': phone,
      'daily_payment': daily,
      'due_date': '${dateOnly(firstDue)}T00:00:00',
      'initial_amount': deposit,
      'product_name': product,
      'remaining_balance': remaining,
      'status': remaining <= 0 ? 'completed' : 'active',
      'supplier_id': supplierEmail,
      'total_amount': total,
      'start_date': '${dateOnly(start)}T00:00:00',
      'show_daily_payment': 1,
      'show_due_date': 1,
      'is_synced': 0,
    });
    _syncSoon();
    return id;
  }

  /// Rekodi malipo, punguza deni, na sogeza due_date kulingana na siku
  /// zilizolipiwa: due = start + (siku zilizolipiwa + 1).
  Future<void> recordPayment(Map<String, dynamic> loan, double amount) async {
    final db = await _db;
    final total = (loan['total_amount'] as num?)?.toDouble() ?? 0;
    final initial = (loan['initial_amount'] as num?)?.toDouble() ?? 0;
    final daily = (loan['daily_payment'] as num?)?.toDouble() ?? 0;
    final paid = ((loan['amount_paid'] as num?)?.toDouble() ?? 0) + amount;
    final remaining = (total - paid) < 0 ? 0.0 : (total - paid);

    var due = loan['due_date'] as String?;
    if (daily > 0) {
      final s = DateTime.tryParse('${loan['start_date']}') ?? tanzaniaNow();
      final covered = ((paid - initial) / daily).floor();
      final d =
          DateTime(s.year, s.month, s.day).add(Duration(days: covered + 1));
      due = '${dateOnly(d)}T00:00:00';
    }

    final now = tanzaniaTimestamp();
    await db.transaction((txn) async {
      await txn.insert('Payments', {
        'id': DateTime.now().microsecondsSinceEpoch,
        'created_at': now,
        'updated_at': now,
        'amount_payment': amount,
        'supplier_id': loan['supplier_id'],
        'payment_date': now,
        'loan_id': loan['id'],
        'payment_customer_name': loan['customer_name'],
        'loan_payment': amount,
        'customer_id': loan['customer_id'],
        'is_synced': 0,
      });
      await txn.update(
        'Loans',
        {
          'amount_paid': paid,
          'remaining_balance': remaining,
          'status': remaining <= 0 ? 'completed' : 'active',
          'due_date': due,
          'is_synced': 0,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [loan['id']],
      );
    });
    _syncSoon();
  }

  /// Kufuta laini (soft delete) - inasawazishwa na Supabase kama status='deleted'
  Future<void> deleteLoan(int id) async {
    final db = await _db;
    await db.update(
      'Loans',
      {'status': 'deleted', 'is_synced': 0, 'updated_at': tanzaniaTimestamp()},
      where: 'id = ?',
      whereArgs: [id],
    );
    _syncSoon();
  }

  // ---------------- Ripoti ----------------

  Future<ReportData> report(String email, ReportPeriod p) async {
    final db = await _db;
    final now = tanzaniaNow();
    final today = DateTime(now.year, now.month, now.day);
    late DateTime start;
    late DateTime end;
    switch (p) {
      case ReportPeriod.leo:
        start = today;
        end = today;
        break;
      case ReportPeriod.wiki: // Jumatatu - Jumapili
        start = today.subtract(Duration(days: today.weekday - 1));
        end = start.add(const Duration(days: 6));
        break;
      case ReportPeriod.mwezi:
        start = DateTime(today.year, today.month, 1);
        end = DateTime(today.year, today.month + 1, 0);
        break;
    }

    num scalar(List<Map<String, Object?>> r) =>
        (r.first.values.first as num?) ?? 0;

    final collected = scalar(await db.rawQuery(
        "SELECT COALESCE(SUM(amount_payment),0) FROM Payments WHERE supplier_id = ? AND substr(payment_date,1,10) BETWEEN ? AND ?",
        [email, dateOnly(start), dateOnly(end)]));
    final outstanding = scalar(await db.rawQuery(
        "SELECT COALESCE(SUM(remaining_balance),0) FROM Loans WHERE supplier_id = ? AND $_live",
        [email]));
    final active = scalar(await db.rawQuery(
        "SELECT COUNT(*) FROM Loans WHERE supplier_id = ? AND $_live",
        [email]));
    final due = await db.rawQuery(
        "SELECT * FROM Loans WHERE supplier_id = ? AND $_live AND substr(due_date,1,10) <= ? ORDER BY due_date ASC",
        [email, dateOnly(end)]);

    return ReportData(
      collected: collected.toDouble(),
      outstanding: outstanding.toDouble(),
      activeCount: active.toInt(),
      dueLoans: due,
    );
  }
}
