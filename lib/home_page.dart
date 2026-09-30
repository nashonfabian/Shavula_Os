import 'package:flutter/material.dart';
import 'app_helper.dart'; // Ndio yenye DatabaseHelper, Products, na openSearchPage
import 'helpers/sync_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedRoleIndex = 0;
  int selectedCategoryIndex = 0;

  String selectedLocation = "Kitunda, DSM";
  String selectedCategory = "Bidhaa zote kwa pamoja";
  List<Map<String, dynamic>> displayedProducts = [];
  bool isLoading = false;

  final List<String> roles = ['Bidhaa', 'Mtoa Bidhaa', 'Mteja'];
  final List<String> categories = [
    "Bidhaa zote kwa pamoja",
    "Nguo za kike",
    "Viatu vya kike",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshProductsFromCloud();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) setState(() => isLoading = true);
    try {
      final data = await AppHelpers.fetchProductsByCategory(
        location: selectedLocation,
        category: selectedCategory,
      );
      if (mounted) {
        setState(() => displayedProducts = data);
      }
    } catch (e) {
      debugPrint("Error loading: $e");
    } finally {
      if (showLoading && mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _refreshProductsFromCloud() async {
    await SyncHelper.instance.pullProducts();
    if (mounted) await _loadData(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Search Bar & Location
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          AppHelpers.openSearchPage(context);
                        },
                        child: AbsorbPointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.amber.shade600, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: TextField(
                                    enabled: false,
                                    decoration: InputDecoration(
                                      hintText: 'Tafuta bidhaa......',
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade600,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.search,
                                      color: Colors.white, size: 20),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18),
                        Text(selectedLocation,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Navigation Tabs (Imewekewa Action ya Kufungua LoginPage kwa Mtoa Bidhaa na Mteja)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(roles.length, (index) {
                  final isSelected = selectedRoleIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedRoleIndex = index);

                      // Ikiwa amebonyeza "Mtoa Bidhaa" (index 1) au "Mteja" (index 2)
                      if (index == 1 || index == 2) {
                        AppHelpers.openLoginPage(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: isSelected
                            ? const Border(
                                bottom:
                                    BorderSide(color: Colors.black, width: 2))
                            : null,
                      ),
                      child: Text(
                        roles[index],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),

              // 3. Location Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFFBF4E8),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Eneo lako: Dar es salam, $selectedLocation',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                          const Text(
                              'Agiza bidhaa na Lipa kidogo kidogo kutoka kwa wauzaji wa eneo lako',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        AppHelpers.openChangeLocationPopup(
                          context,
                          currentLocation: selectedLocation,
                          onLocationChanged: (newLoc) {
                            setState(() => selectedLocation = newLoc);
                            _loadData();
                          },
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline,
                          size: 14, color: Colors.amber),
                      label: const Text('Badilisha eneo',
                          style: TextStyle(fontSize: 11, color: Colors.amber)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          side: BorderSide(color: Colors.amber.shade300),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // 4. Rahisisha Utafutaji
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('Rahisisha utafutaji',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, index) {
                    final isSelected = selectedCategoryIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategoryIndex = index;
                          selectedCategory = categories[index];
                        });
                        _loadData();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF7EEDD)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300)),
                        child: Text(categories[index],
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 15),

              // 5. Product Cards List
              if (isLoading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator())),
              if (!isLoading && displayedProducts.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Hakuna bidhaa zilizopatikana kwa sasa.'),
                  ),
                ),
              if (!isLoading && displayedProducts.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedProducts.length,
                  itemBuilder: (context, index) {
                    final product = displayedProducts[index];
                    return ProductCardWidget(productData: product);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductCardWidget extends StatelessWidget {
  final Map<String, dynamic> productData;
  const ProductCardWidget({super.key, required this.productData});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                spreadRadius: 1)
          ]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => AppHelpers.openProductPage(context,
                productName: '${productData['name'] ?? 'Bidhaa'}',
                currentLocation: "Kitunda, DSM"),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 130,
                height: 160,
                child: '${productData['image_url'] ?? ''}'.isEmpty
                    ? Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image,
                            size: 50, color: Colors.grey),
                      )
                    : Image.network(
                        '${productData['image_url']}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image,
                              size: 50, color: Colors.grey),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${productData['name'] ?? 'Bidhaa'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text('TSH ${productData['price'] ?? '-'}'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => AppHelpers.openOrderForm(
                      context,
                      productName: '${productData['name'] ?? 'Bidhaa'}',
                      location: "Kitunda, DSM",
                      sellerName:
                          '${productData['supplier_email'] ?? 'Mtoa bidhaa'}',
                      cashPrice: '${productData['price'] ?? ''}',
                      imageUrl: '${productData['image_url'] ?? ''}',
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5B54E),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        elevation: 0),
                    child: const Text('Agiza bidhaa',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SellerPriceTile extends StatelessWidget {
  final String sellerName;
  final String cashPrice;
  final String loanPrice;
  const SellerPriceTile(
      {super.key,
      required this.sellerName,
      required this.cashPrice,
      required this.loanPrice});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.person_outline, size: 14),
          const SizedBox(width: 4),
          Text(sellerName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))
        ]),
        const SizedBox(height: 4),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(4)),
            child: Text('💰 Cash TSH $cashPrice',
                style: const TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold))),
        const SizedBox(height: 3),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(4)),
            child: Text('💳 Lipa kidogo kidogo TSH $loanPrice',
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold))),
      ],
    );
  }
}
