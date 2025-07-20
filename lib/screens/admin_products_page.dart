import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  void _showAddProductDialog() {
    _nameController.clear();
    _priceController.clear();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add New Product"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: _addProduct,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
            child: const Text(
              "Add",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addProduct() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());

    if (name.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please enter valid name and price."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    await FirebaseFirestore.instance.collection('coffee_items').add({
      'name': name,
      'price': price,
      'timestamp': Timestamp.now(),
    });

    Navigator.pop(context);
  }

  void _showEditProductDialog(
      String docId, String currentName, double currentPrice) {
    _nameController.text = currentName;
    _priceController.text = currentPrice.toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Product"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () => _updateProduct(docId),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
            child: const Text(
              "Save",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProduct(String docId) async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());

    if (name.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please enter valid name and price."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    await FirebaseFirestore.instance
        .collection('coffee_items')
        .doc(docId)
        .update({
      'name': name,
      'price': price,
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Product updated."),
      backgroundColor: Colors.green,
    ));
  }

  Future<void> _deleteProduct(String id) async {
    await FirebaseFirestore.instance
        .collection('coffee_items')
        .doc(id)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Product deleted"),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Products"),
        backgroundColor: Colors.brown,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown,
        onPressed: _showAddProductDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('coffee_items').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text("Something went wrong"));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final products = snapshot.data!.docs;

          if (products.isEmpty)
            return const Center(child: Text("No products found."));

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (_, index) {
              final data = products[index].data() as Map<String, dynamic>;
              final docId = products[index].id;
              final name = data['name'] ?? 'No Name';
              final price = (data['price'] ?? 0).toDouble();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(name),
                  subtitle: Text("₱${price.toStringAsFixed(2)}"),
                  onTap: () => _showEditProductDialog(docId, name, price),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteProduct(docId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
