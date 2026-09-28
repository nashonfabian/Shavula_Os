import 'package:flutter/material.dart';

class ChangeLocationPopup extends StatefulWidget {
  final String currentLocation;
  final Function(String newLocation) onLocationSaved;

  const ChangeLocationPopup({
    super.key,
    this.currentLocation = "",
    required this.onLocationSaved,
  });

  @override
  State<ChangeLocationPopup> createState() => _ChangeLocationPopupState();
}

class _ChangeLocationPopupState extends State<ChangeLocationPopup> {
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.currentLocation);
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _submitLocation() {
    String newLocation = _locationController.text.trim();
    if (newLocation.isNotEmpty) {
      widget.onLocationSaved(newLocation);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 5,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TITLE TEXT
            const Text(
              "kupata watoa bidhaa wa eneo lako,\nTafadhali jaza eneo lako",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // 2. INPUT FIELD
            TextField(
              controller: _locationController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Andika eneo lako...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  borderSide: const BorderSide(color: Color(0xFF9FA8DA)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. ENDELEA BUTTON
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _submitLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5CAE9), // Soft Blue/Purple from UI
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Endelea",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}