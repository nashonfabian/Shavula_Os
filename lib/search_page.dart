import 'package:flutter/material.dart';
import 'app_helper.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;

  // Orodha ya Mapendekezo ya Haraka
  final List<String> suggestions = [
    "Viatu vya kike",
    "Viatu vya Flat vya kike",
    "Viatu vya kike",
    "Sendo za kike",
  ];

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    final results = await AppHelpers.searchProducts(query);

    if (mounted) {
      setState(() {
        searchResults = results;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BAR YA KUTAFUTIA (SEARCH BAR)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: const Color(0xFFD4A017), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: _performSearch,
                        decoration: const InputDecoration(
                          hintText: "Tafuta bidhaa...",
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // SEHEMU YA MAPENDEKEZO NA RESULTS DISPLAY
            Expanded(
              child: _searchController.text.isEmpty
                  ? _buildSuggestionsList()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  // DISPLAY YA MAPENDEKEZO WAKATI TEXTFIELD IKO WAZI
  Widget _buildSuggestionsList() {
    return Container(
      color: Colors.grey.shade300,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "MAPENDEKEZO",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final item = suggestions[index];
                return ListTile(
                  title: Text(
                    item,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  onTap: () {
                    _searchController.text = item;
                    _performSearch(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // DISPLAY YA RESULTS KUTOKA SQLITE WAKATI MTUMIAJI ANATAFUTA
  Widget _buildSearchResults() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchResults.isEmpty) {
      return const Center(
        child: Text(
          "Hakuna bidhaa iliyopatikana",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final product = searchResults[index];
        return ListTile(
          leading: product['image_url'] != null
              ? Image.network(product['image_url'], width: 50, height: 50, fit: BoxFit.cover)
              : const Icon(Icons.shopping_bag),
          title: Text(product['name'] ?? "Bidhaa"),
          subtitle: Text("TSH ${product['price'] ?? 0}"),
          onTap: () {
            AppHelpers.openProductPage(context, productName: product['name'] ?? "");
          },
        );
      },
    );
  }
}