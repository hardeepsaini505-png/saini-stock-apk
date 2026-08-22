import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const SainiStockApp());
}

class SainiStockApp extends StatelessWidget {
  const SainiStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Saini Stock App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const StockHome(),
    );
  }
}

class Product {
  String name;
  String category;
  int stock;
  int lowLimit;

  Product({
    required this.name,
    required this.category,
    required this.stock,
    this.lowLimit = 2,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'stock': stock,
        'lowLimit': lowLimit,
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      stock: json['stock'] ?? 0,
      lowLimit: json['lowLimit'] ?? 2,
    );
  }
}

class StockHome extends StatefulWidget {
  const StockHome({super.key});

  @override
  State<StockHome> createState() => _StockHomeState();
}

class _StockHomeState extends State<StockHome> {
  List<Product> products = [];
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('products');

    if (data != null) {
      final list = jsonDecode(data) as List;
      setState(() {
        products =
            list.map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
      });
    }
  }

  Future<void> saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'products',
      jsonEncode(products.map((e) => e.toJson()).toList()),
    );
  }

  int get totalStock => products.fold(0, (sum, p) => sum + p.stock);

  int get lowStock =>
      products.where((p) => p.stock > 0 && p.stock <= p.lowLimit).length;

  int get nilStock => products.where((p) => p.stock == 0).length;

  Future<void> addProduct() async {
    final name = TextEditingController();
    final category = TextEditingController();
    final qty = TextEditingController(text: '0');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Product'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Opening Stock',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;

              products.add(
                Product(
                  name: name.text.trim(),
                  category: category.text.trim(),
                  stock: int.tryParse(qty.text) ?? 0,
                ),
              );

              saveProducts();
              setState(() {});
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  Future<void> changeStock(Product product, bool stockIn) async {
    final qty = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(stockIn ? 'Stock In' : 'Stock Out'),
        content: TextField(
          controller: qty,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantity',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = int.tryParse(qty.text) ?? 0;

              if (amount <= 0) return;

              if (stockIn) {
                product.stock += amount;
              } else {
                if (amount > product.stock) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Stock Out quantity is greater than stock.'),
                    ),
                  );
                  return;
                }
                product.stock -= amount;
              }

              saveProducts();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteProduct(Product product) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (yes == true) {
      products.remove(product);
      await saveProducts();
      setState(() {});
    }
  }

  Future<void> generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'SAINI INFO SOLUTIONS',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text('Stock Report'),
          pw.SizedBox(height: 15),
          pw.Table.fromTextArray(
            headers: ['Product', 'Category', 'Stock', 'Status'],
            data: products.map((p) {
              String status;

              if (p.stock == 0) {
                status = 'NIL STOCK';
              } else if (p.stock <= p.lowLimit) {
                status = 'LOW STOCK';
              } else {
                status = 'OK';
              }

              return [
                p.name,
                p.category,
                p.stock.toString(),
                status,
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Total Products: ${products.length}'),
          pw.Text('Total Quantity: $totalStock'),
          pw.Text('Low Stock Items: $lowStock'),
          pw.Text('Nil Stock Items: $nilStock'),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = searchController.text.toLowerCase();

    final filtered = products.where((p) {
      return p.name.toLowerCase().contains(search) ||
          p.category.toLowerCase().contains(search);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saini Stock App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'PDF Report',
            onPressed: generatePdf,
            icon: const Icon(Icons.picture_as_pdf),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: addProduct,
        icon: const Icon(Icons.add),
        label: const Text('Product'),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search product...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: statCard(
                    'Products',
                    products.length.toString(),
                    Icons.inventory_2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: statCard(
                    'Total Stock',
                    totalStock.toString(),
                    Icons.warehouse,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: statCard(
                    'Low Stock',
                    lowStock.toString(),
                    Icons.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: statCard(
                    'Nil Stock',
                    nilStock.toString(),
                    Icons.remove_shopping_cart,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No products found',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];

                      Color statusColor;

                      if (product.stock == 0) {
                        statusColor = Colors.red;
                      } else if (product.stock <= product.lowLimit) {
                        statusColor = Colors.orange;
                      } else {
                        statusColor = Colors.green;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor,
                            child: Text(
                              product.stock.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${product.category.isEmpty ? 'No Category' : product.category}\n'
                            'Current Stock: ${product.stock}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'in') {
                                changeStock(product, true);
                              } else if (value == 'out') {
                                changeStock(product, false);
                              } else if (value == 'delete') {
                                deleteProduct(product);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'in',
                                child: Text('Stock In'),
                              ),
                              PopupMenuItem(
                                value: 'out',
                                child: Text('Stock Out'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget statCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
