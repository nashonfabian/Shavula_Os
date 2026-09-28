import 'package:flutter/material.dart';
import 'change_location_popup.dart';
import 'order_form_popup.dart';
import 'helpers/db_helper.dart';
import 'helpers/auth_helper.dart';
import 'product_open.dart';
import 'search_page.dart';
import 'login_page.dart';
import 'supplier_home_page.dart';

class AppHelpers {

  // 1. Navigation kwenda ProductOpenPage
  static void openProductPage(
    BuildContext context, {
    String productName = "Maguani ya vitambaa (Linen) ya kike",
    String currentLocation = "Kitunda, DSM",
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductOpenPage(
          productName: productName,
          currentLocation: currentLocation,
        ),
      ),
    );
  }

  // 2. Pop-up ya Kubadilisha Eneo
  static void openChangeLocationPopup(
    BuildContext context, {
    required Function(String newLocation) onLocationChanged,
    String currentLocation = "",
  }) {
    showDialog(
      context: context,
      builder: (context) => ChangeLocationPopup(
        currentLocation: currentLocation,
        onLocationSaved: (newLocation) async {
          onLocationChanged(newLocation);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Eneo limebadilishwa kuwa $newLocation"),
                backgroundColor: const Color(0xFF0D2380),
              ),
            );
          }
        },
      ),
    );
  }

  // 3. Pop-up ya Fomu ya Maombi ya Bidhaa (Order Form)
  static void openOrderForm(
    BuildContext context, {
    String productName = "Maguani ya vitambaa (Linen) ya kike",
    String location = "Kitunda, DSM",
    String cashPrice = "30000",
    String sellerName = "Fabian",
    String depositPrice = "6,429",
    String dailyPayment = "",
    String totalPrice = "45,000",
    String imageUrl = "https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=500",
  }) {
    showDialog(
      context: context,
      builder: (context) => OrderFormPopup(
        productName: productName,
        location: location,
        cashPrice: cashPrice,
        sellerName: sellerName,
        depositPrice: depositPrice,
        dailyPayment: dailyPayment,
        totalPrice: totalPrice,
        imageUrl: imageUrl,
      ),
    );
  }

  // 4. Inaita DatabaseHelper na kuchuja kwa kategoria na eneo
  static Future<List<Map<String, dynamic>>> fetchProductsByCategory({
    required String location,
    required String category,
  }) async {
    final db = await DatabaseHelper.instance.database;

    if (category == "Bidhaa zote kwa pamoja" || category.isEmpty) {
      return await db.query('Products');
    } else {
      return await db.query(
        'Products',
        where: 'category = ?',
        whereArgs: [category],
      );
    }
  }

  // 5. Inatafuta kwa SKU kwenye Table ya Products
  static Future<Map<String, dynamic>?> fetchProductBySku(String sku) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'Products',
      where: 'sku = ?',
      whereArgs: [sku],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // 6. Action ya kufungua SearchPage
  static void openSearchPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  // 7. Action ya kutafuta bidhaa kutoka SQLite kupitia DatabaseHelper
  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    return await DatabaseHelper.instance.searchProducts(query);
  }

  // 8. Action ya kufungua LoginPage (Mtoa Bidhaa / Mteja) - au SupplierHomePage
  // moja kwa moja kama kuna session iliyohifadhiwa (mtumiaji tayari
  // ameshaingia awali kwenye kifaa hiki).
  static Future<void> openLoginPage(BuildContext context) async {
    final savedSession = await AuthHelper().restoreSession();

    if (!context.mounted) return;

    if (savedSession != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SupplierHomePage(
            userId: savedSession.userId,
            userEmail: savedSession.email,
            fullName: savedSession.fullName,
            wasOffline: savedSession.wasOffline,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}
