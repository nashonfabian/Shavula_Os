import 'package:flutter/material.dart';
import 'helpers/supplier_helper.dart';
import 'helpers/timezone_helper.dart';

/// Ripoti ya biashara: makusanyo ya leo, wiki hii au mwezi huu.
class ReportsPage extends StatefulWidget {
  final String supplierEmail;
  final String name;
  const ReportsPage(
      {super.key, required this.supplierEmail, required this.name});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  static const navy = Color(0xFF0D2380);
  static const gold = Color(0xFFD4A017);

  ReportPeriod? _period;
  ReportData? _data;
  bool _loading = false;

  static const _labels = {
    ReportPeriod.leo: 'Leo',
    ReportPeriod.wiki: 'Wiki hii',
    ReportPeriod.mwezi: 'Mwezi huu',
  };

  Future<void> _select(ReportPeriod? p) async {
    if (p == null) return;
    setState(() {
      _period = p;
      _loading = true;
    });
    final d = await SupplierHelper.instance.report(widget.supplierEmail, p);
    if (!mounted) return;
    setState(() {
      _data = d;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: Column(
          children: [
            const Text('Ripoti ya biashara',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Text(
                  'Habari👋, karibu ndugu ${widget.name} katika report yako ya biashara.',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            const Text('Chagua report ya siku, wiki hii, mwezi huu',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: DropdownButton<ReportPeriod>(
                value: _period,
                hint: const Text('Chagua muda'),
                underline: const SizedBox(),
                items: ReportPeriod.values
                    .map((p) =>
                        DropdownMenuItem(value: p, child: Text(_labels[p]!)))
                    .toList(),
                onChanged: _select,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(color: Colors.white),
            if (!_loading && _data != null) ..._content(_data!),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(ReportData d) {
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            _card(Icons.attach_money, gold, 'Kiasi kilichokusanywa',
                fmtMoney(d.collected)),
            const SizedBox(height: 10),
            _card(Icons.account_balance_wallet, gold,
                'Pesa ambayo haijakusanywa', fmtMoney(d.outstanding)),
            const SizedBox(height: 10),
            _card(Icons.work_outline, Colors.black, 'Kazi zinazoendelea',
                '${d.activeCount}'),
            const SizedBox(height: 10),
            _card(Icons.currency_exchange, Colors.red,
                'Kazi zinazotakiwa kulipwa', '${d.dueLoans.length}'),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Text('Kazi zote zinazotakiwa kulipwa',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 10),
      if (d.dueLoans.isEmpty)
        const Text('Hakuna kazi inayotakiwa kulipwa.',
            style: TextStyle(color: Colors.white70)),
      ...d.dueLoans.map(_dueRow),
    ];
  }

  Widget _card(IconData icon, Color color, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6)
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _dueRow(Map<String, dynamic> l) {
    final today = dateOnly(tanzaniaNow());
    final late = '${l['due_date']}'.length >= 10 &&
        '${l['due_date']}'.substring(0, 10).compareTo(today) < 0;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${l['customer_name'] ?? '-'}  •  ${l['customer_phone'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('${l['product_name'] ?? '-'}'),
          Text(
              'Marejesho ya siku: TSH ${fmtMoney(l['daily_payment'] as num?)}'),
          Text(
              'Kiasi kilichobaki: TSH ${fmtMoney(l['remaining_balance'] as num?)}'),
          Text(
            late
                ? 'Amechelewa tangu ${fmtDate(l['due_date'])}'
                : 'Analipa: ${fmtDate(l['due_date'])}',
            style: TextStyle(
                color: late ? Colors.red : Colors.black54,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
