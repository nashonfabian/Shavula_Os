import 'package:flutter/material.dart';
import 'helpers/supplier_helper.dart';
import 'helpers/timezone_helper.dart';

/// Fomu ya kumsajili mteja (kuunda mkopo mpya).
/// Ikitokea kwenye "Kubali" ombi, [prefill] na [orderId] hujazwa, na ombi
/// linawekwa 'accepted' baada ya usajili kufanikiwa.
class RegisterCustomerPage extends StatefulWidget {
  final String supplierEmail;
  final Map<String, dynamic>? prefill;
  final int? orderId;

  const RegisterCustomerPage({
    super.key,
    required this.supplierEmail,
    this.prefill,
    this.orderId,
  });

  @override
  State<RegisterCustomerPage> createState() => _RegisterCustomerPageState();
}

class _RegisterCustomerPageState extends State<RegisterCustomerPage> {
  static const navy = Color(0xFF0D2380);
  static const gold = Color(0xFFD4A017);

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _area = TextEditingController();
  final _product = TextEditingController();
  final _total = TextEditingController();
  final _deposit = TextEditingController();
  final _daily = TextEditingController();

  DateTime _start = tanzaniaNow();
  List<Map<String, dynamic>> _known = [];
  String? _selectedCustomerId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    if (p != null) {
      _name.text = '${p['name'] ?? ''}';
      _phone.text = '${p['phone'] ?? ''}';
      _area.text = '${p['area'] ?? ''}';
      _product.text = '${p['product'] ?? ''}';
      if (p['total'] != null) _total.text = '${p['total']}';
    }
    SupplierHelper.instance.knownCustomers(widget.supplierEmail).then((rows) {
      if (mounted) setState(() => _known = rows);
    });
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _area,
      _product,
      _total,
      _deposit,
      _daily
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '')) ?? 0;

  void _pickExisting(String? cid) {
    setState(() => _selectedCustomerId = cid);
    if (cid == null) return;
    final c = _known.firstWhere((k) => '${k['cid']}' == cid, orElse: () => {});
    if (c.isEmpty) return;
    _name.text = '${c['customer_name'] ?? ''}';
    _phone.text = '${c['customer_phone'] ?? ''}';
    _area.text = '${c['customer_location'] ?? ''}';
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _start = d);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final phone = _phone.text.trim();
    final customerId =
        _selectedCustomerId ?? await SupplierHelper.instance.newCustomerId();
    await SupplierHelper.instance.createLoan(
      supplierEmail: widget.supplierEmail,
      customerId: customerId,
      name: _name.text.trim(),
      phone: phone,
      area: _area.text.trim(),
      product: _product.text.trim(),
      total: _num(_total),
      deposit: _num(_deposit),
      daily: _num(_daily),
      start: _start,
    );
    if (widget.orderId != null) {
      await SupplierHelper.instance
          .updateOrder(widget.orderId!, status: 'accepted');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mteja amesajiliwa kikamilifu.')));
    Navigator.pop(context, true);
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(t,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      );

  Widget _field(TextEditingController c, String hint,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: c,
      keyboardType: type,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text('Fomu ya kumsajili mteja',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            _label('Chagua mteja kama ulishamsajili'),
            DropdownButtonFormField<String>(
              value: _selectedCustomerId,
              isExpanded: true,
              hint: const Text('Chagua mteja'),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              items: _known
                  .map((k) => DropdownMenuItem<String>(
                        value: '${k['cid']}',
                        child: Text(
                            '${k['customer_name']} - ${k['customer_phone']}',
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: _pickExisting,
            ),
            _label('Jina la mteja'),
            _field(_name, 'Andika kama ni mpya'),
            _label('Namba ya simu'),
            _field(_phone, 'Mfano: 07XXXXXXXX', type: TextInputType.phone),
            _label('Jina la mtaa'),
            _field(_area, 'Mtaa anaoishi'),
            _label('Jina la bidhaa'),
            _field(_product, 'Bidhaa aliyochukua'),
            _label('Bei ya mkopo'),
            _field(_total, 'Jumla ya gharama', type: TextInputType.number),
            _label('Kianzio:'),
            _field(_deposit, 'Kiasi alichotoa mwanzo (0 kama hakuna)',
                type: TextInputType.number),
            _label('Marejesho ya kila siku'),
            _field(_daily, 'Kiasi cha kila siku', type: TextInputType.number),
            _label('Tarehe ya kuanza'),
            InkWell(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(fmtDate(dateOnly(_start)),
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white24,
                  disabledForegroundColor: Colors.white54,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Sajili mteja',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
