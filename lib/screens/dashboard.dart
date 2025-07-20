import 'package:provider/provider.dart';
import '../providers/feedback_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/coffee_item.dart';
import '../widgets/search_bar_widget.dart';
import 'cart_screen.dart';
import 'feedback_main.dart';
import 'login_page.dart';
import 'addresses_screen.dart';
import 'my_orders_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<CoffeeItem> _coffeeItems = [];
  List<CoffeeItem> _filteredItems = [];
  int _cartCount = 0;
  String _userEmail = '';
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadCoffeeItems();
    _loadUserInfo();
    _listenToCart();
  }

  void _loadCoffeeItems() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('coffee_items').get();
    final items = snapshot.docs.map((doc) {
      return CoffeeItem.fromMap(doc.id, doc.data());
    }).toList();

    setState(() {
      _coffeeItems = items;
      _filteredItems = items;
    });
  }

  void _loadUserInfo() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _userEmail = snapshot.data()?['email'] ?? user.email ?? 'Welcome!';
      });
    }
  }

  void _listenToCart() {
    final user = _auth.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .snapshots()
        .listen((snapshot) {
      int totalQuantity = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Skip promo documents (based on common promo fields)
        if (data.containsKey('code') &&
            data.containsKey('type') &&
            data.containsKey('value')) {
          continue;
        }

        final quantity = data['quantity'] ?? 1;
        totalQuantity +=
            quantity is int ? quantity : int.tryParse(quantity.toString()) ?? 1;
      }

      setState(() {
        _cartCount = totalQuantity;
      });
    });
  }

  void _filterCoffeeItems(String query) {
    final filtered = _coffeeItems
        .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() => _filteredItems = filtered);
  }

  void _addToCart(CoffeeItem item) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to add to cart")),
      );
      return;
    }

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(item.id);

    final doc = await cartRef.get();
    if (doc.exists) {
      await cartRef.update({'quantity': FieldValue.increment(1)});
    } else {
      await cartRef.set({
        'name': item.name,
        'price': item.price,
        'quantity': 1,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const CartScreen()));
          },
        ),
      ),
    );
  }

  void _navigateTo(Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kc Kape Mo"),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CartScreen()));
                },
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Text('$_cartCount',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                ),
            ],
          )
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.brown[100],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.brown),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.coffee, color: Colors.white, size: 40),
                  const SizedBox(height: 10),
                  const Text("Welcome!",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text(_userEmail,
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.brown),
              title: const Text("Dashboard"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.brown),
              title: const Text("My Orders"),
              onTap: () => _navigateTo(const MyOrdersPage()),
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.brown),
              title: const Text("Addresses"),
              onTap: () => _navigateTo(const AddressesScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.feedback, color: Colors.brown),
              title: const Text("Feedback"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => FeedbackData(),
                    child: const FeedbackMainScreen(),
                  ),
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.brown),
              title: const Text("Logout"),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Confirm Logout"),
                    content: const Text("Are you sure you want to logout?"),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel")),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown),
                        child: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _auth.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchBarWidget(
              onChanged: _filterCoffeeItems,
              hintText: 'Search for coffee...',
            ),
            const SizedBox(height: 20),
            _filteredItems.isEmpty
                ? const Center(child: Text("No coffee items available."))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return Card(
                        color: Colors.brown[100],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item.icon,
                                  size: 48, color: Colors.brown[700]),
                              const SizedBox(height: 8),
                              Text(item.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.brown)),
                              Text('₱${item.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.brown[800])),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => _addToCart(item),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.brown,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text(
                                  "Add to Cart",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
