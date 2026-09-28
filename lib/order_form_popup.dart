import 'package:flutter/material.dart';

class OrderFormPopup extends StatefulWidget {
  final String productName;
  final String location;
  final String cashPrice;
  final String sellerName;
  final String depositPrice;
  final String dailyPayment;
  final String totalPrice;
  final String imageUrl;

  const OrderFormPopup({
    super.key,
    this.productName = "Maguani ya vitambaa (Linen) ya kike",
    this.location = "Kitunda, DSM",
    this.cashPrice = "30000",
    this.sellerName = "Fabian",
    this.depositPrice = "6,429",
    this.dailyPayment = "",
    this.totalPrice = "45,000",
    this.imageUrl = "https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=500",
  });

  @override
  State<OrderFormPopup> createState() => _OrderFormPopupState();
}

class _OrderFormPopupState extends State<OrderFormPopup> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();

  bool _isFormValid = false;

  void _validateForm() {
    setState(() {
      _isFormValid = _fullNameController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty &&
          _streetController.text.trim().isNotEmpty;
    });
  }

  void _submitForm() {
    if (!_isFormValid) return;

    // Workflow: Save order to SQLite or Send Application
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Maombi yako yametumwa kikamilifu!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFF0D2380), // Deep Blue Background
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER & CLOSE BUTTON
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Fomu ya maombi ya bidhaa",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. PRODUCT & SELLER SUMMARY
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.imageUrl,
                      width: 60,
                      height: 65,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.productName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.location,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          "Bei ya bidhaa: ${widget.cashPrice}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const Text("😊 ", style: TextStyle(fontSize: 10)),
                            Text(
                              "Karibu by ${widget.sellerName}",
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. VIGEO VYA MTOA BIDHAA (YELLOW CARD)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_month, size: 16, color: Colors.black87),
                        SizedBox(width: 6),
                        Text(
                          "VIGEO VYA MTOA BIDHAA",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Kianzio
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.monetization_on_outlined, size: 16, color: Colors.amber),
                            SizedBox(width: 4),
                            Text("Kianzio", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Text(
                          "TSH ${widget.depositPrice}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Malipo ya kila siku
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.amber),
                            SizedBox(width: 4),
                            Text("Malipo ya kila siku:", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Text(
                          "TSH ${widget.dailyPayment}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Jumla ya gharama
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.remove_circle_outline, size: 14, color: Colors.amber),
                            SizedBox(width: 4),
                            Text("Jumla ya gharama:", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Text(
                          "TSH ${widget.totalPrice}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Notice
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Vigezo hivi vimewekwa na mtoa bidhaa husika hakikisha. Hakikisha umesoma na kuelewa kabla ya kutuma maombi",
                            style: TextStyle(fontSize: 9, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. TAARIFA ZAKO CARD
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: Colors.black87),
                        SizedBox(width: 6),
                        Text(
                          "TAARIFA ZAKO",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Majina Kamili
                    _buildInputField(
                      label: "Majina kamili",
                      hint: "Andika majina kamili...",
                      controller: _fullNameController,
                    ),
                    const SizedBox(height: 10),

                    // Namba ya simu
                    _buildInputField(
                      label: "Namba ya simu",
                      hint: "Mfano: 07XXXXXXXX",
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),

                    // Mtaa / Eneo
                    _buildInputField(
                      label: "Mtaa / Eneo unaloishi",
                      hint: "Andika mtaa au eneo unaloishi...",
                      controller: _streetController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. TUMA MAOMBI BUTTON
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: _isFormValid ? _submitForm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B803A), // Green button on active
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Tuma maombi",
                    style: TextStyle(
                      color: _isFormValid ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (_) => _validateForm(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0D2380)),
            ),
          ),
        ),
      ],
    );
  }
}