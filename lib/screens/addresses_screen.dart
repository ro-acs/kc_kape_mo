import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final _auth = FirebaseAuth.instance;
  final _addressController = TextEditingController();
  String? _selectedProvince;
  String? _selectedCity;

  final Map<String, List<String>> _provinceCityMap = {
    "Abra": ["Bangued", "Boliney", "Daguioman", "Danglas", "La Paz"],
    "Agusan del Norte": ["Butuan City", "Carmen", "Jabonga", "Nasipit"],
    "Agusan del Sur": ["Bayugan City", "Bunawan", "San Francisco"],
    "Aklan": ["Kalibo", "Malay", "Banga", "New Washington"],
    "Albay": ["Legazpi City", "Ligao City", "Tabaco City", "Daraga"],
    "Antique": ["San Jose de Buenavista", "Sibalom", "Tibiao"],
    "Aurora": ["Baler", "Casiguran", "Dingalan"],
    "Basilan": ["Isabela City", "Lamitan City"],
    "Bataan": ["Balanga City", "Mariveles", "Orani", "Dinalupihan"],
    "Batanes": ["Basco", "Itbayat", "Ivana"],
    "Batangas": ["Batangas City", "Lipa City", "Tanauan City", "Bauan"],
    "Benguet": ["La Trinidad", "Itogon", "Tuba", "Bokod"],
    "Biliran": ["Naval", "Almeria", "Caibiran"],
    "Bohol": ["Tagbilaran City", "Panglao", "Tubigon", "Ubay"],
    "Bukidnon": ["Malaybalay City", "Valencia City", "Don Carlos"],
    "Bulacan": [
      "Malolos City",
      "Meycauayan City",
      "Santa Maria",
      "San Jose del Monte",
    ],
    "Cagayan": ["Tuguegarao City", "Aparri", "Alcala"],
    "Camarines Norte": ["Daet", "Jose Panganiban", "Labo"],
    "Camarines Sur": ["Naga City", "Iriga City", "Pili", "Libmanan"],
    "Camiguin": ["Mambajao", "Mahinog", "Catarman"],
    "Capiz": ["Roxas City", "Panay", "Pontevedra"],
    "Catanduanes": ["Virac", "Bato", "San Andres"],
    "Cavite": ["Tagaytay City", "Dasmariñas", "Bacoor", "Imus"],
    "Cebu": ["Cebu City", "Mandaue City", "Lapu-Lapu City", "Talisay"],
    "Davao del Norte": ["Tagum City", "Panabo City", "Santo Tomas"],
    "Davao del Sur": ["Digos City", "Santa Cruz", "Bansalan"],
    "Davao Oriental": ["Mati City", "Baganga", "Lupon"],
    "Dinagat Islands": ["San Jose", "Dinagat", "Libjo"],
    "Eastern Samar": ["Borongan City", "Dolores", "Oras"],
    "Guimaras": ["Jordan", "Buenavista", "Nueva Valencia"],
    "Ifugao": ["Lagawe", "Kiangan", "Banaue"],
    "Ilocos Norte": ["Laoag City", "Batac City", "Paoay"],
    "Ilocos Sur": ["Vigan City", "Candon City", "Santa Maria"],
    "Iloilo": ["Iloilo City", "Passi City", "Oton", "Pototan"],
    "Isabela": ["Ilagan City", "Cauayan City", "Santiago City", "Roxas"],
    "Kalinga": ["Tabuk City", "Lubuagan", "Rizal"],
    "La Union": ["San Fernando City", "Agoo", "Bauang"],
    "Laguna": ["Calamba City", "San Pedro", "Santa Rosa", "Biñan"],
    "Lanao del Norte": ["Iligan City", "Tubod", "Kapatagan"],
    "Lanao del Sur": ["Marawi City", "Balabagan", "Bayang"],
    "Leyte": ["Tacloban City", "Ormoc City", "Palo"],
    "Maguindanao": ["Cotabato City", "Datu Odin Sinsuat", "Buluan"],
    "Marinduque": ["Boac", "Gasan", "Mogpog"],
    "Masbate": ["Masbate City", "Aroroy", "Milagros"],
    "Metro Manila": [
      "Manila",
      "Quezon City",
      "Makati",
      "Taguig",
      "Pasig",
      "Pasay",
      "Caloocan",
      "Marikina",
    ],
    "Misamis Occidental": ["Oroquieta City", "Ozamiz City", "Tangub City"],
    "Misamis Oriental": ["Cagayan de Oro", "Gingoog City", "El Salvador"],
    "Mountain Province": ["Bontoc", "Sagada", "Tadian"],
    "Negros Occidental": ["Bacolod City", "Talisay", "Silay", "Bago"],
    "Negros Oriental": ["Dumaguete City", "Bais", "Tanjay"],
    "North Cotabato": ["Kidapawan City", "M'lang", "Makilala"],
    "Northern Samar": ["Catarman", "Allen", "Laoang"],
    "Nueva Ecija": [
      "Cabanatuan City",
      "Gapan",
      "San Jose City",
      "Palayan City",
    ],
    "Nueva Vizcaya": ["Bayombong", "Solano", "Bagabag"],
    "Occidental Mindoro": ["San Jose", "Mamburao", "Abra de Ilog"],
    "Oriental Mindoro": ["Calapan City", "Pinamalayan", "Roxas"],
    "Palawan": ["Puerto Princesa", "Coron", "El Nido"],
    "Pampanga": ["San Fernando", "Angeles City", "Mabalacat", "Apalit"],
    "Pangasinan": ["Dagupan City", "San Carlos City", "Urdaneta", "Lingayen"],
    "Quezon": ["Lucena City", "Tayabas", "Candelaria", "Sariaya"],
    "Quirino": ["Cabarroguis", "Diffun", "Saguday"],
    "Rizal": ["Antipolo City", "Cainta", "Taytay", "Binangonan"],
    "Romblon": ["Romblon", "Odiongan", "San Agustin"],
    "Samar": ["Catbalogan", "Calbayog", "Basey"],
    "Sarangani": ["Alabel", "Glan", "Malungon"],
    "Siquijor": ["Siquijor", "Larena", "Lazi"],
    "Sorsogon": ["Sorsogon City", "Gubat", "Bulusan"],
    "South Cotabato": ["Koronadal", "Polomolok", "Surallah"],
    "Southern Leyte": ["Maasin City", "Sogod", "Hinunangan"],
    "Sultan Kudarat": ["Isulan", "Tacurong", "President Quirino"],
    "Sulu": ["Jolo", "Patikul", "Indanan"],
    "Surigao del Norte": ["Surigao City", "Dapa", "General Luna"],
    "Surigao del Sur": ["Tandag City", "Bislig City", "Barobo"],
    "Tarlac": ["Tarlac City", "Capas", "Concepcion"],
    "Tawi-Tawi": ["Bongao", "Panglima Sugala", "Sitangkai"],
    "Zambales": ["Olongapo City", "Iba", "Subic"],
    "Zamboanga del Norte": ["Dipolog City", "Dapitan City", "Sindangan"],
    "Zamboanga del Sur": ["Pagadian City", "Zamboanga City", "Molave"],
    "Zamboanga Sibugay": ["Ipil", "Kabasalan", "Imelda"],
  };

  Future<void> _showAddressDialog(
      {String? id, Map<String, dynamic>? initial}) async {
    _addressController.text = initial?['address'] ?? '';
    _selectedProvince = initial?['province'];
    _selectedCity = initial?['city'];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        return AlertDialog(
          title: Text(id == null ? 'Add Address' : 'Edit Address'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: "Full Address"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  decoration: const InputDecoration(labelText: "Province"),
                  items: _provinceCityMap.keys.map((prov) {
                    return DropdownMenuItem(value: prov, child: Text(prov));
                  }).toList(),
                  onChanged: (value) {
                    setModalState(() {
                      _selectedProvince = value;
                      _selectedCity = null; // reset city
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: const InputDecoration(labelText: "City"),
                  items: _selectedProvince == null
                      ? []
                      : _provinceCityMap[_selectedProvince]!
                          .map((city) =>
                              DropdownMenuItem(value: city, child: Text(city)))
                          .toList(),
                  onChanged: (value) {
                    setModalState(() {
                      _selectedCity = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (_addressController.text.isEmpty ||
                    _selectedProvince == null ||
                    _selectedCity == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all fields")),
                  );
                  return;
                }

                if (id == null) {
                  await _addAddress();
                } else {
                  await _editAddress(id);
                }
                Navigator.pop(context);
              },
              child: Text(id == null ? "Add" : "Save"),
            )
          ],
        );
      }),
    );
  }

  Future<void> _addAddress() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .add({
      'address': _addressController.text.trim(),
      'province': _selectedProvince,
      'city': _selectedCity,
      'isDefault': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _editAddress(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .doc(id)
        .update({
      'address': _addressController.text.trim(),
      'province': _selectedProvince,
      'city': _selectedCity,
    });
  }

  Future<void> _deleteAddress(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .doc(id)
        .delete();
  }

  Future<void> _setDefaultAddress(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses');
    final snapshot = await ref.get();
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == id});
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to manage addresses.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Addresses"),
        actions: [
          IconButton(
              onPressed: () => _showAddressDialog(),
              icon: const Icon(Icons.add)),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('addresses')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No addresses saved."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final full = data['address'] ?? '';
              final prov = data['province'] ?? '';
              final city = data['city'] ?? '';
              final isDefault = data['isDefault'] == true;

              return ListTile(
                title: Text(full),
                subtitle: Text('$city, $prov'),
                leading: Icon(
                  isDefault ? Icons.check_circle : Icons.circle_outlined,
                  color: isDefault ? Colors.green : Colors.grey,
                ),
                onTap: () => _setDefaultAddress(doc.id),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.brown),
                      onPressed: () =>
                          _showAddressDialog(id: doc.id, initial: data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteAddress(doc.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
