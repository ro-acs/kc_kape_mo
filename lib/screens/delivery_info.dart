import 'package:flutter/material.dart';
import 'order_receipt.dart';

enum PaymentMethod { gcash, cod }

class DeliveryInfo extends StatefulWidget {
  const DeliveryInfo({super.key});

  @override
  State<DeliveryInfo> createState() => _DeliveryInfoState();
}

class _DeliveryInfoState extends State<DeliveryInfo> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  PaymentMethod? _selectedPaymentMethod;
  String? _selectedCity;

  final List<String> _cities = <String>[
    'Manila',
    'Cebu',
    'Davao',
    'Baguio',
    'Iloilo',
    'Zamboanga',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCity = _cities.first;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _contactController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _confirmOrder() {
    if (_addressController.text.trim().isEmpty ||
        _contactController.text.trim().isEmpty ||
        _selectedPaymentMethod == null ||
        _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields.",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderReceiptScreen(
          address: _addressController.text,
          contact: _contactController.text,
          city: _selectedCity!,
          payment: _selectedPaymentMethod == PaymentMethod.gcash
              ? "Gcash"
              : "Cash on Delivery",
          note: _noteController.text,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.brown),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.brown, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCity,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.brown),
          isExpanded: true,
          style: const TextStyle(color: Colors.black, fontSize: 16),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCity = newValue;
            });
          },
          items: _cities.map<DropdownMenuItem<String>>((String city) {
            return DropdownMenuItem<String>(
              value: city,
              child: Text(city),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery Information"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Delivery Details",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown[100],
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField("Full Address", _addressController, maxLines: 3),
            const SizedBox(height: 15),
            _buildDropdown(),
            const SizedBox(height: 15),
            _buildTextField("Contact Number", _contactController,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 15),
            _buildTextField("Note to Delivery (Optional)", _noteController,
                maxLines: 3),
            const SizedBox(height: 30),
            Text(
              "Payment Method",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown[100],
              ),
            ),
            const SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: <Widget>[
                  RadioListTile<PaymentMethod>(
                    title: const Text("Gcash",
                        style: TextStyle(color: Colors.black)),
                    value: PaymentMethod.gcash,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (PaymentMethod? value) {
                      setState(() {
                        _selectedPaymentMethod = value;
                      });
                    },
                    activeColor: Colors.brown,
                  ),
                  RadioListTile<PaymentMethod>(
                    title: const Text("Cash on Delivery",
                        style: TextStyle(color: Colors.black)),
                    value: PaymentMethod.cod,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (PaymentMethod? value) {
                      setState(() {
                        _selectedPaymentMethod = value;
                      });
                    },
                    activeColor: Colors.brown,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Confirm Order"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
