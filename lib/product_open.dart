import 'package:flutter/material.dart';

class ProductOpenPage extends StatefulWidget {
  final String productName;
  final String currentLocation;

  const ProductOpenPage({
    super.key,
    this.productName = "Nguo ya Kike",
    this.currentLocation = "Kitunda, DSM",
  });

  static String routeName = 'ProductOpen';
  static String routePath = '/productOpen';

  @override
  State<ProductOpenPage> createState() => _ProductOpenPageState();
}

class _ProductOpenPageState extends State<ProductOpenPage> {
  static const Color kPrimaryGold = Color(0xFFD4A017);

  // Orodha ya Picha (Thumbnails)
  final List<String> _productImages = [
    'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=500', // Pink (Default)
    'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=500', // White/Pink
    'https://images.unsplash.com/photo-1502716119720-b23a93e5fe1b?w=500', // Black
    'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=500', // Yellow
  ];

  late String _selectedMainImage;

  @override
  void initState() {
    super.initState();
    _selectedMainImage = _productImages[0];
  }

  // WORKFLOW 1: Thumbnail clicked -> Change Main Image
  void _onThumbnailClicked(String imageUrl) {
    setState(() {
      _selectedMainImage = imageUrl;
    });
  }

  // WORKFLOW 2: Agiza sasa clicked
  void _onAgizaSasaClicked(String sellerName, String priceDetails) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Oda imeanzishwa kwa $sellerName ($priceDetails)"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 1. MAIN LARGE DISPLAY IMAGE
              Container(
                height: 420,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(_selectedMainImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. CATEGORY THUMBNAILS (Picha Ndogo za Chini)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _productImages.length,
                  itemBuilder: (context, index) {
                    String imgUrl = _productImages[index];
                    bool isSelected = _selectedMainImage == imgUrl;

                    return GestureDetector(
                      onTap: () => _onThumbnailClicked(imgUrl),
                      child: Container(
                        width: 70,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? kPrimaryGold : Colors.grey.shade300,
                            width: isSelected ? 2.5 : 1,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(imgUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              const Divider(thickness: 1),

              // 3. SUPPLIERS / WAUZAJI SECTION
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Muuzaji 1: Fabian
                    Expanded(
                      child: _buildSupplierCard(
                        sellerName: "Fabian",
                        cashPrice: "30,000",
                        installmentPrice: "45,000",
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Muuzaji 2: Zeynalix
                    Expanded(
                      child: _buildSupplierCard(
                        sellerName: "Zeynalix",
                        cashPrice: "30,000",
                        installmentPrice: "51,000",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget ya Supplier Card (Fabian / Zeynalix)
  Widget _buildSupplierCard({
    required String sellerName,
    required String cashPrice,
    required String installmentPrice,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller Header
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Colors.black87),
              const SizedBox(width: 4),
              Text(
                sellerName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Cash Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.monetization_on_outlined, size: 12, color: Colors.green),
                    SizedBox(width: 3),
                    Text("Cash", style: TextStyle(fontSize: 10, color: Colors.green)),
                  ],
                ),
                Text(
                  "TSH $cashPrice",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Lipa Kidogo Kidogo Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 10, color: Colors.red),
                    SizedBox(width: 3),
                    Text("Lipa kidogo kidogo", style: TextStyle(fontSize: 9, color: Colors.red)),
                  ],
                ),
                Text(
                  "TSH $installmentPrice",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Button: Agiza sasa
          SizedBox(
            width: double.infinity,
            height: 34,
            child: ElevatedButton(
              onPressed: () => _onAgizaSasaClicked(sellerName, "Cash: $cashPrice"),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGold,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Agiza sasa',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}