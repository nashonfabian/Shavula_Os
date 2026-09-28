import 'package:flutter/material.dart';
import 'helpers/supplier_helper.dart';
import 'register_customer_page.dart';

const _gold = Color(0xFFD4A017);

Widget _productImage(String? url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (url == null || url.isEmpty) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }
  return Image.network(
    url,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    ),
  );
}

// =====================================================================
// Orodha ya maombi mapya (status = pending)
// =====================================================================
class PendingOrdersPage extends StatefulWidget {
  final String supplierEmail;
  const PendingOrdersPage({super.key, required this.supplierEmail});

  @override
  State<PendingOrdersPage> createState() => _PendingOrdersPageState();
}

class _PendingOrdersPageState extends State<PendingOrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await SupplierHelper.instance.pendingOrders(widget.supplierEmail);
    if (!mounted) return;
    setState(() {
      _orders = data;
      _loading = false;
    });
  }

  Future<void> _open(Map<String, dynamic> order) async {
    final handled = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailPage(order: order, supplierEmail: widget.supplierEmail),
      ),
    );
    if (handled == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ombi limeshughulikiwa.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Maombi mapya',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Hakuna maombi mapya kwa sasa.',
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (_, i) {
                    final o = _orders[i];
                    return InkWell(
                      onTap: () => _open(o),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black26),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _productImage('${o['product_url'] ?? ''}',
                                  width: 70, height: 70),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Oda mpya',
                                      style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                  Text('${o['customer_name'] ?? '-'}',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${o['product_name'] ?? '-'}'),
                                  Text('TSH ${fmtMoney(o['price'] as num?)}  •  ${fmtDate(o['created_at'])}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// =====================================================================
// Undani wa ombi: Kubali / Kataa
// =====================================================================
class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> order;
  final String supplierEmail;
  const OrderDetailPage({super.key, required this.order, required this.supplierEmail});

  /// Kubali -> fungua fomu ya usajili ikiwa na taarifa za mteja tayari.
  /// Ombi linawekwa 'accepted' baada ya mteja kusajiliwa kikamilifu.
  Future<void> _accept(BuildContext context) async {
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterCustomerPage(
          supplierEmail: supplierEmail,
          orderId: order['id'] as int,
          prefill: {
            'name': order['customer_name'],
            'phone': order['customer_phone'],
            'area': order['customer_area'],
            'product': order['product_name'],
            'total': order['price'],
          },
        ),
      ),
    );
    if (done == true && context.mounted) Navigator.pop(context, true);
  }

  Future<void> _reject(BuildContext context) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kataa ombi'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Sababu ya kukataa'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ghairi')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Kataa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (reason == null) return;
    await SupplierHelper.instance.updateOrder(order['id'] as int,
        status: 'rejected', reason: reason.isEmpty ? null : reason);
    if (context.mounted) Navigator.pop(context, true);
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text('$label:$value', style: const TextStyle(fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Oda mpya',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black54),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Oda mpya',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  _line('Jina la mteja', '${order['customer_name'] ?? '-'}'),
                  _line('Namba ya simu', '${order['customer_phone'] ?? '-'}'),
                  _line('Jina la mtaa', '${order['customer_area'] ?? '-'}'),
                  _line('Jina la bidhaa', '${order['product_name'] ?? '-'}'),
                  _line('Bei ya bidhaa', fmtMoney(order['price'] as num?)),
                  _line('Aina ya maombi', 'SHAVULA order'),
                  _line('Tarehe ya maombi', fmtDate(order['created_at'])),
                  if ('${order['note'] ?? ''}'.isNotEmpty) _line('Maelezo', '${order['note']}'),
                  const SizedBox(height: 10),
                  _productImage('${order['product_url'] ?? ''}',
                      width: double.infinity, height: 320, fit: BoxFit.cover),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _accept(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Kubali', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _reject(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Kataa', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
