import 'package:flutter/material.dart';
import 'helpers/auth_helper.dart';
import 'helpers/supplier_helper.dart';
import 'helpers/sync_helper.dart';
import 'login_page.dart';
import 'customers_page.dart';
import 'pending_orders_page.dart';
import 'register_customer_page.dart';
import 'reports_page.dart';

/// Dashibodi ya Mtoa Huduma. supplier_id = email ya mtumiaji.
class SupplierHomePage extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String? fullName;
  final bool wasOffline;

  const SupplierHomePage({
    super.key,
    required this.userId,
    required this.userEmail,
    this.fullName,
    this.wasOffline = false,
  });

  @override
  State<SupplierHomePage> createState() => _SupplierHomePageState();
}

class _SupplierHomePageState extends State<SupplierHomePage> {
  static const gold = Color(0xFFD4A017);
  late Future<Map<String, int>> _statsFuture;

  String get _email => widget.userEmail;

  @override
  void initState() {
    super.initState();
    _statsFuture = SupplierHelper.instance.stats(_email);
    _bootstrapSync();
  }

  /// Tuma mabadiliko ya ndani, kisha pakua data mpya ya supplier (kimya kimya).
  Future<void> _bootstrapSync() async {
    SyncHelper.instance.setActiveSupplier(_email);
    await SyncHelper.instance.syncForActiveSupplier();
    if (mounted) _refreshStats();
  }

  void _refreshStats() {
    setState(() => _statsFuture = SupplierHelper.instance.stats(_email));
  }

  Future<void> _go(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _refreshStats();
  }

  /// Funga: toka kwenye akaunti na rudi kwenye ukurasa wa login
  Future<void> _funga() async {
    SyncHelper.instance.clearActiveSupplier();
    await AuthHelper().logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _notBuiltYet(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label - bado haijatengenezwa.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.fullName ?? widget.userEmail;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text('Bidhaa', style: TextStyle(color: Colors.black, fontSize: 15)),
            Text('Mtoa Bidhaa',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline)),
            Text('Mteja', style: TextStyle(color: Colors.black, fontSize: 15)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _bootstrapSync,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Karibu 👋, ndugu $name. Ona zaidi...',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _funga,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: gold, foregroundColor: Colors.black),
                      child: const Text('Funga'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search bar - inafungua ukurasa wa wateja wote ukiwa tayari kutafuta
              TextField(
                readOnly: true,
                onTap: () => _go(CustomersPage(
                    supplierEmail: _email, mode: CustomerMode.all, autofocusSearch: true)),
                decoration: InputDecoration(
                  hintText: 'Tafuta mteja...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              const SizedBox(height: 20),

              FutureBuilder<Map<String, int>>(
                future: _statsFuture,
                builder: (context, snap) {
                  final s = snap.data ??
                      {'pendingRequests': 0, 'totalCustomers': 0, 'overdueJobs': 0, 'todayJobs': 0};
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      _StatCard(
                        icon: Icons.hourglass_bottom,
                        iconColor: gold,
                        label: 'Maombi mapya ya wateja',
                        value: s['pendingRequests']!,
                        onTap: () => _go(PendingOrdersPage(supplierEmail: _email)),
                      ),
                      _StatCard(
                        icon: Icons.menu_book,
                        iconColor: Colors.red,
                        label: 'Idadi ya wateja wote',
                        value: s['totalCustomers']!,
                        onTap: () => _go(
                            CustomersPage(supplierEmail: _email, mode: CustomerMode.all)),
                      ),
                      _StatCard(
                        icon: Icons.currency_exchange,
                        iconColor: Colors.red,
                        label: 'Kazi zilizocheleweshwa',
                        value: s['overdueJobs']!,
                        outlined: true,
                        onTap: () => _go(
                            CustomersPage(supplierEmail: _email, mode: CustomerMode.overdue)),
                      ),
                      _StatCard(
                        icon: Icons.access_time,
                        iconColor: Colors.red,
                        label: 'Kazi ya leo',
                        value: s['todayJobs']!,
                        outlined: true,
                        onTap: () => _go(
                            CustomersPage(supplierEmail: _email, mode: CustomerMode.today)),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _goldButton('Sajili mteja',
                        () => _go(RegisterCustomerPage(supplierEmail: _email))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _goldButton('Angalia ripoti',
                        () => _go(ReportsPage(supplierEmail: _email, name: name))),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () => _notBuiltYet('Weka bidhaa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Weka bidhaa',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              if (widget.wasOffline) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Umeingia bila mtandao (offline) - takwimu ni za ndani tu.',
                    style: TextStyle(color: Colors.deepOrange),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _goldButton(String label, VoidCallback onTap) => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int value;
  final bool outlined;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: outlined ? Border.all(color: Colors.red.withOpacity(0.4)) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Text('$value',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
