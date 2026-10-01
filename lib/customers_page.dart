import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'helpers/supplier_helper.dart';

enum CustomerMode { all, overdue, today }

class CustomersPage extends StatefulWidget {
  final String supplierEmail;
  final CustomerMode mode;
  final bool autofocusSearch;

  const CustomersPage({
    super.key,
    required this.supplierEmail,
    this.mode = CustomerMode.all,
    this.autofocusSearch = false,
  });

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  static const gold = Color(0xFFD4A017);
  static const navy = Color(0xFF0D2380);

  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _loans = [];
  bool _loading = true;

  String get _title {
    switch (widget.mode) {
      case CustomerMode.overdue:
        return 'Kazi zilizocheleweshwa';
      case CustomerMode.today:
        return 'Kazi ya leo';
      case CustomerMode.all:
        return 'Wateja wote';
    }
  }

  String get _emptyText {
    switch (widget.mode) {
      case CustomerMode.overdue:
        return 'Hakuna mteja aliyechelewa kulipa.';
      case CustomerMode.today:
        return 'Hakuna mteja anayetakiwa kulipa leo.';
      case CustomerMode.all:
        return 'Bado hujasajili mteja.';
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await SupplierHelper.instance
        .loans(widget.supplierEmail, mode: widget.mode.name);
    if (!mounted) return;
    setState(() {
      _loans = data;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _loans;
    const keys = [
      'customer_name',
      'customer_phone',
      'customer_location',
      'product_name'
    ];
    return _loans
        .where(
            (l) => keys.any((k) => '${l[k] ?? ''}'.toLowerCase().contains(q)))
        .toList();
  }

  List<List<Map<String, dynamic>>> get _customerGroups {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final loan in _filtered) {
      final id =
          '${loan['customer_id'] ?? loan['customer_phone'] ?? loan['customer_name'] ?? loan['id']}';
      groups.putIfAbsent(id, () => []).add(loan);
    }
    return groups.values.toList();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ---------------- Mawasiliano ----------------

  Future<void> _open(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _snack('Imeshindwa kufungua.');
    } catch (_) {
      _snack('Imeshindwa kufungua.');
    }
  }

  String _reminder(Map<String, dynamic> l) {
    final customerId = '${l['customer_id'] ?? ''}'.trim();
    final message =
        'Habari ${l['customer_name']}, kiasi kilichobaki kwenye mkopo wa ${l['product_name']} '
        'ni TSH ${fmtMoney(l['remaining_balance'])}. Asante.';
    if (customerId.isEmpty) return message;
    return '$message\n\nAngalia taarifa za deni hapa: ${customerPortalUrl(customerId)}';
  }

  void _call(Map<String, dynamic> l) =>
      _open(Uri(scheme: 'tel', path: '${l['customer_phone']}'));

  void _sms(Map<String, dynamic> l) => _open(Uri.parse(
      'sms:${l['customer_phone']}?body=${Uri.encodeComponent(_reminder(l))}'));

  void _whatsapp(Map<String, dynamic> l) => _open(Uri.parse(
      'https://wa.me/${intlPhone('${l['customer_phone']}')}?text=${Uri.encodeComponent(_reminder(l))}'));

  // ---------------- Lipa ----------------

  Future<void> _lipa(Map<String, dynamic> loan) async {
    final remaining = (loan['remaining_balance'] as num?)?.toDouble() ?? 0;
    final ctrl = TextEditingController();
    String? error;

    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lipa mkopo wa: ${loan['customer_name']}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('Weka kiasi',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    errorText: error,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      final v =
                          double.tryParse(ctrl.text.trim().replaceAll(',', ''));
                      if (v == null || v <= 0) {
                        setD(() => error = 'Weka kiasi sahihi.');
                      } else if (v > remaining) {
                        setD(() => error =
                            'Kimezidi deni lililobaki (TSH ${fmtMoney(remaining)}).');
                      } else {
                        Navigator.pop(ctx, v);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: gold, foregroundColor: Colors.black),
                    child: const Text('Thibitisha',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (amount == null) return;
    await SupplierHelper.instance.recordPayment(loan, amount);
    await _load();
    _snack('Malipo ya TSH ${fmtMoney(amount)} yamerekodiwa.');
  }

  // ---------------- Futa ----------------

  Future<void> _delete(Map<String, dynamic> loan) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Futa mteja?'),
        content: Text('${loan['customer_name']} - ${loan['product_name']} '
            'ataondolewa kwenye orodha.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ghairi')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Futa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    await SupplierHelper.instance.deleteLoan(loan['id'] as int);
    await _load();
    _snack('Mteja amefutwa.');
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final list = _customerGroups;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(_title,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: widget.autofocusSearch,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tafuta mteja...',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: gold, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: gold, width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _searchCtrl.text.isEmpty
                                ? _emptyText
                                : 'Hakuna mteja aliyepatikana.',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: list.length,
                        itemBuilder: (_, i) => _card(list[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _card(List<Map<String, dynamic>> loans) {
    final customer = loans.first;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${customer['customer_name'] ?? '-'}',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          _row('Namba ya simu', '${customer['customer_phone'] ?? '-'}'),
          _row('Jina la mtaa', '${customer['customer_location'] ?? '-'}'),
          ...loans.asMap().entries.map((entry) {
            final index = entry.key;
            final loan = entry.value;
            final completed = '${loan['status']}' == 'completed';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index > 0) const Divider(height: 24, thickness: 1),
                _row('Jina la bidhaa', '${loan['product_name'] ?? '-'}'),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!completed)
                      ElevatedButton(
                        onPressed: () => _lipa(loan),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor: Colors.white),
                        child: const Text('Lipa',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    _action(Icons.message, 'Message', navy, () => _sms(loan)),
                    _action(Icons.phone_in_talk, 'WhatsApp',
                        const Color(0xFF25D366), () => _whatsapp(loan)),
                    _action(Icons.add_call, 'Call', navy, () => _call(loan)),
                  ],
                ),
                _row('Bei ya bidhaa', fmtMoney(loan['total_amount'] as num?)),
                _row('Kianzio', fmtMoney(loan['initial_amount'] as num?)),
                _row('Kiasi kilichobaki',
                    fmtMoney(loan['remaining_balance'] as num?)),
                _row('Marejesho ya kila siku',
                    fmtMoney(loan['daily_payment'] as num?)),
                _row('Siku ya kuchukua bidhaa', fmtDate(loan['start_date'])),
                if (!completed)
                  _row('Analipa tarehe', fmtDate(loan['due_date'])),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hali ya huduma: ${completed ? 'Imekamilika' : 'Inaendelea'}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: completed ? Colors.green : Colors.black),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _delete(loan),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 10, thickness: 0.8),
        Text('$label: $value',
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
