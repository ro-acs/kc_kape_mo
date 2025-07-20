import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_orders_page.dart';
import 'admin_products_page.dart';
import 'admin_users_page.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  String _adminEmail = 'Loading...';
  final _auth = FirebaseAuth.instance;

  final List<String> _pageTitles = [
    "Dashboard Overview",
    "Manage Orders",
    "Manage Products",
    "User Accounts",
    "Logout",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _adminEmail = snapshot.data()?['email'] ?? user.email ?? 'Welcome!';
      });
    }
  }

  final List<Widget> _pages = [
    Center(child: Text("Welcome to the Admin Dashboard")),
    Center(child: Text("Orders Management Page")),
    Center(child: Text("Products Management Page")),
    Center(child: Text("Users List Page")),
    Center(child: Text("Logging out...")),
  ];

  void _onSelectPage(int index) {
    Navigator.pop(context); // Close drawer first

    switch (index) {
      case 0:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
        break;
      case 1:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminOrdersPage()));
        break;
      case 2:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminProductsPage()));
        break;
      case 3:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AdminUsersPage()));
        break;
    }
  }

  Future<int> _getTotalOrders() async {
    final snapshot =
        await FirebaseFirestore.instance.collectionGroup('orders').get();
    return snapshot.docs.length;
  }

  Future<int> _getTotalUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    return snapshot.docs.length;
  }

  Future<int> _getTotalProducts() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('coffee_items').get();
    return snapshot.docs.length;
  }

  Future<double> _getTotalSales() async {
    final snapshot =
        await FirebaseFirestore.instance.collectionGroup('orders').get();
    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc['total'] ?? 0).toDouble();
    }
    _getWeeklySalesChange();
    return total;
  }

  Widget _buildStatCardWithStream(
    String title,
    IconData icon,
    Stream<QuerySnapshot> stream,
    Color color, {
    bool isCurrency = false,
    double Function(QuerySnapshot)? compute,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        String displayValue = '...';
        if (snapshot.hasData) {
          if (compute != null) {
            double value = compute(snapshot.data!);
            displayValue =
                isCurrency ? "₱${value.toStringAsFixed(2)}" : value.toString();
          } else {
            displayValue = snapshot.data!.docs.length.toString();
          }
        }

        return Container(
          width: MediaQuery.of(context).size.width / 2 - 30,
          constraints: const BoxConstraints(minHeight: 130),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 24, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<double> _getWeeklySalesChange() async {
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));

    final allOrders =
        await FirebaseFirestore.instance.collectionGroup('orders').get();

    double totalLastWeek = 0;
    double totalThisWeek = 0;

    for (var doc in allOrders.docs) {
      final timestamp = (doc['timestamp'] as Timestamp).toDate();
      final total = (doc['total'] ?? 0).toDouble();

      if (timestamp.isAfter(now.subtract(const Duration(days: 7)))) {
        totalThisWeek += total;
      } else if (timestamp
          .isAfter(lastWeek.subtract(const Duration(days: 7)))) {
        totalLastWeek += total;
      }
    }

    if (totalLastWeek == 0) return 100.0; // Prevent division by zero
    return ((totalThisWeek - totalLastWeek) / totalLastWeek) * 100;
  }

  Future<double> _getWeeklyChange() async {
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));

    final thisWeek = await FirebaseFirestore.instance
        .collectionGroup('orders')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(lastWeek))
        .get();

    final lastWeekData = await FirebaseFirestore.instance
        .collectionGroup('orders')
        .where('timestamp',
            isGreaterThan: Timestamp.fromDate(twoWeeksAgo),
            isLessThanOrEqualTo: Timestamp.fromDate(lastWeek))
        .get();

    double thisWeekSales = 0;
    double lastWeekSales = 0;

    for (var doc in thisWeek.docs) {
      thisWeekSales += (doc['total'] ?? 0).toDouble();
    }

    for (var doc in lastWeekData.docs) {
      lastWeekSales += (doc['total'] ?? 0).toDouble();
    }

    if (lastWeekSales == 0) return 100;
    return ((thisWeekSales - lastWeekSales) / lastWeekSales) * 100;
  }

  Future<List<FlSpot>> _getSalesData() async {
    try {
      final now = DateTime.now().toUtc();
      final last7Days = now.subtract(const Duration(days: 7));
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('orders')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(last7Days))
          .get();

      Map<int, double> dailyTotals = {};
      for (var doc in snapshot.docs) {
        if (doc.data().containsKey('timestamp') &&
            doc['timestamp'] is Timestamp) {
          DateTime date = (doc['timestamp'] as Timestamp).toDate();
          int day = date.weekday;
          dailyTotals[day] =
              (dailyTotals[day] ?? 0) + (doc['total'] ?? 0).toDouble();
        }
      }

      return List.generate(
          7, (i) => FlSpot(i.toDouble(), dailyTotals[i + 1] ?? 0));
    } catch (e) {
      print("Error fetching sales data: $e");
      return [];
    }
  }

  Widget _buildSalesChart() {
    final now = DateTime.now().toUtc();
    final last7Days = now.subtract(const Duration(days: 7));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('orders')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(last7Days))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        print(snapshot);

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No sales data available.'));
        }

        try {
          Map<int, double> dailyTotals = {};

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['timestamp'] is Timestamp) {
              DateTime date = (data['timestamp'] as Timestamp).toDate();
              int day = date.weekday;
              dailyTotals[day] =
                  (dailyTotals[day] ?? 0) + (data['total'] ?? 0).toDouble();
            }
          }

          final spots = List.generate(
            7,
            (i) => FlSpot(i.toDouble(), dailyTotals[i + 1] ?? 0),
          );

          return LineChart(LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 4,
                color: Colors.green,
                dotData: FlDotData(show: false),
              ),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    return Text(days[value.toInt() % 7]);
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            ),
          ));
        } catch (e) {
          return Center(child: Text('Error loading chart: $e'));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        backgroundColor: Colors.brown[700],
        elevation: 0,
      ),
      drawer: Drawer(
        backgroundColor: Colors.brown[900],
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.brown, Colors.brown.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings,
                        size: 30, color: Colors.brown),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin Panel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _adminEmail,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.dashboard, 'Dashboard', 0),
            _buildDrawerItem(Icons.receipt_long, 'Orders', 1),
            _buildDrawerItem(Icons.coffee, 'Products', 2),
            _buildDrawerItem(Icons.people, 'Users', 3),
            const Divider(color: Colors.white38),
            _buildDrawerItem(Icons.logout, 'Logout', 4),
          ],
        ),
      ),
      // In the build method under Scaffold:
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "📊 Dashboard Overview",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildStatCardWithStream(
                    "Total Orders",
                    Icons.receipt_long,
                    FirebaseFirestore.instance
                        .collectionGroup('orders')
                        .snapshots(),
                    Colors.blueAccent,
                  ),
                  _buildStatCardWithStream(
                    "Total Users",
                    Icons.people,
                    FirebaseFirestore.instance.collection('users').snapshots(),
                    Colors.teal,
                  ),
                  _buildStatCardWithStream(
                    "Total Products",
                    Icons.coffee,
                    FirebaseFirestore.instance
                        .collection('coffee_items')
                        .snapshots(),
                    Colors.deepOrange,
                  ),
                  _buildStatCardWithStream(
                    "Total Sales",
                    Icons.money,
                    FirebaseFirestore.instance
                        .collectionGroup('orders')
                        .snapshots(),
                    Colors.deepPurple,
                    isCurrency: true,
                    compute: (snapshot) {
                      return snapshot.docs.fold<double>(0,
                          (sum, doc) => sum + (doc['total'] ?? 0).toDouble());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FutureBuilder(
                future: _getWeeklyChange(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  double percent = snapshot.data! as double;
                  bool positive = percent >= 0;
                  return Text(
                    "📈 Change from last week: ${positive ? '+' : ''}${percent.toStringAsFixed(2)}%",
                    style: TextStyle(
                        color: positive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text("Sales in Last 7 Days",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 200, child: _buildSalesChart()),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  Widget _buildDrawerItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.orange : Colors.white),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.orangeAccent : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () => label == 'Logout' ? _confirmLogout() : _onSelectPage(index),
    );
  }
}
