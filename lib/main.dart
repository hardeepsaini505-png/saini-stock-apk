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
      title: 'Saini Billing & Stock',
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
  double price;

  Product({
    required this.name,
    required this.category,
    required this.stock,
    this.lowLimit = 2,
    this.price = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'stock': stock,
        'lowLimit': lowLimit,
        'price': price,
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      stock: json['stock'] ?? 0,
      lowLimit: json['lowLimit'] ?? 2,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class BillItem {
  final String productName;
  final int quantity;
  final double rate;

  BillItem({
    required this.productName,
    required this.quantity,
    required this.rate,
  });

  double get amount => quantity * rate;

  Map<String, dynamic> toJson() => {
        'productName': productName,
        'quantity': quantity,
        'rate': rate,
      };

  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
        productName: json['productName'] ?? '',
        quantity: json['quantity'] ?? 0,
        rate: (json['rate'] as num?)?.toDouble() ?? 0,
      );
}

class SavedBill {
  final String billNo;
  final String date;
  final String customerName;
  final String customerMobile;
  final double subtotal;
  final double discount;
  final double gst;
  final double total;
  final List<BillItem> items;

  SavedBill({
    required this.billNo,
    required this.date,
    required this.customerName,
    required this.customerMobile,
    required this.subtotal,
    required this.discount,
    required this.gst,
    required this.total,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'billNo': billNo,
        'date': date,
        'customerName': customerName,
        'customerMobile': customerMobile,
        'subtotal': subtotal,
        'discount': discount,
        'gst': gst,
        'total': total,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory SavedBill.fromJson(Map<String, dynamic> json) => SavedBill(
        billNo: json['billNo'] ?? '',
        date: json['date'] ?? '',
        customerName: json['customerName'] ?? '',
        customerMobile: json['customerMobile'] ?? '',
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
        gst: (json['gst'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
        items: (json['items'] as List? ?? [])
            .map((e) => BillItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class StockHome extends StatefulWidget {
  const StockHome({super.key});

  @override
  State<StockHome> createState() => _StockHomeState();
}

class _StockHomeState extends State<StockHome> {
  List<Product> products = [];
  List<SavedBill> bills = [];
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final productData = prefs.getString('products');
    final billData = prefs.getString('bills');

    if (productData != null) {
      final list = jsonDecode(productData) as List;
      products = list
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (billData != null) {
      final list = jsonDecode(billData) as List;
      bills = list
          .map((e) => SavedBill.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (mounted) setState(() {});
  }

  Future<void> saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'products',
      jsonEncode(products.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> saveBills() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'bills',
      jsonEncode(bills.map((e) => e.toJson()).toList()),
    );
  }

  int get totalStock => products.fold(0, (sum, p) => sum + p.stock);

  int get lowStock =>
      products.where((p) => p.stock > 0 && p.stock <= p.lowLimit).length;

  int get nilStock => products.where((p) => p.stock == 0).length;

  double get totalSales => bills.fold(0, (sum, b) => sum + b.total);

  Future<void> addProduct() async {
    final name = TextEditingController();
    final category = TextEditingController();
    final qty = TextEditingController(text: '0');
    final price = TextEditingController(text: '0');

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
              const SizedBox(height: 12),
              TextField(
                controller: price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Selling Price',
                  prefixText: '₹ ',
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
                  price: double.tryParse(price.text) ?? 0,
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

    if (result == true && mounted) setState(() {});
  }

  Future<void> editProduct(Product product) async {
    final price = TextEditingController(text: product.price.toStringAsFixed(2));
    final low = TextEditingController(text: product.lowLimit.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Selling Price',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: low,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Low Stock Limit',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              product.price = double.tryParse(price.text) ?? product.price;
              product.lowLimit = int.tryParse(low.text) ?? product.lowLimit;
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      await saveProducts();
      if (mounted) setState(() {});
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
      if (mounted) setState(() {});
    }
  }

  Future<void> createBill() async {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pehle product add karo.')),
      );
      return;
    }

    final result = await Navigator.push<SavedBill>(
      context,
      MaterialPageRoute(
        builder: (_) => BillingPage(products: products),
      ),
    );

    if (result != null) {
      bills.insert(0, result);
      await saveProducts();
      await saveBills();
      if (mounted) setState(() {});
      await printBill(result);
    }
  }

  Future<void> printBill(SavedBill bill) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'SAINI INFO SOLUTIONS',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text('Billing Invoice'),
          pw.SizedBox(height: 12),
          pw.Text('Bill No: ${bill.billNo}'),
          pw.Text('Date: ${bill.date}'),
          if (bill.customerName.isNotEmpty)
            pw.Text('Customer: ${bill.customerName}'),
          if (bill.customerMobile.isNotEmpty)
            pw.Text('Mobile: ${bill.customerMobile}'),
          pw.SizedBox(height: 15),
          pw.Table.fromTextArray(
            headers: ['Product', 'Qty', 'Rate', 'Amount'],
            data: bill.items
                .map((item) => [
                      item.productName,
                      item.quantity.toString(),
                      '₹${item.rate.toStringAsFixed(2)}',
                      '₹${item.amount.toStringAsFixed(2)}',
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 15),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Subtotal: ₹${bill.subtotal.toStringAsFixed(2)}'),
                pw.Text('Discount: ₹${bill.discount.toStringAsFixed(2)}'),
                pw.Text('GST: ₹${bill.gst.toStringAsFixed(2)}'),
                pw.SizedBox(height: 5),
                pw.Text(
                  'TOTAL: ₹${bill.total.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 25),
          pw.Text('Thank you for your business!'),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
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
            headers: ['Product', 'Category', 'Stock', 'Rate', 'Status'],
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
                '₹${p.price.toStringAsFixed(2)}',
                status,
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Total Products: ${products.length}'),
          pw.Text('Total Quantity: $totalStock'),
          pw.Text('Low Stock Items: $lowStock'),
          pw.Text('Nil Stock Items: $nilStock'),
          pw.Text('Total Sales: ₹${totalSales.toStringAsFixed(2)}'),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  Future<void> showBills() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BillsPage(
          bills: bills,
          onPrint: printBill,
        ),
      ),
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
          'Saini Billing & Stock',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Bills',
            onPressed: showBills,
            icon: const Icon(Icons.receipt_long),
          ),
          IconButton(
            tooltip: 'PDF Stock Report',
            onPressed: generatePdf,
            icon: const Icon(Icons.picture_as_pdf),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createBill,
        icon: const Icon(Icons.point_of_sale),
        label: const Text('New Bill'),
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
                            'Stock: ${product.stock}   Rate: ₹${product.price.toStringAsFixed(2)}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'in') {
                                changeStock(product, true);
                              } else if (value == 'out') {
                                changeStock(product, false);
                              } else if (value == 'edit') {
                                editProduct(product);
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
                                value: 'edit',
                                child: Text('Edit Price / Low Limit'),
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

class BillingPage extends StatefulWidget {
  final List<Product> products;

  const BillingPage({super.key, required this.products});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final customerName = TextEditingController();
  final customerMobile = TextEditingController();
  final discountController = TextEditingController(text: '0');
  final gstController = TextEditingController(text: '0');
  final List<BillItem> items = [];

  double get subtotal => items.fold(0, (sum, item) => sum + item.amount);

  double get discount {
    final value = double.tryParse(discountController.text) ?? 0;
    return value.clamp(0, subtotal).toDouble();
  }

  double get gst {
    final percent = double.tryParse(gstController.text) ?? 0;
    return ((subtotal - discount) * percent / 100).clamp(0, double.infinity);
  }

  double get total => subtotal - discount + gst;

  Future<void> addItem() async {
    final available = widget.products.where((p) => p.stock > 0).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koi product stock me nahi hai.')),
      );
      return;
    }

    Product selected = available.first;
    final qtyController = TextEditingController(text: '1');

    final result = await showDialog<BillItem>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Product>(
                value: selected,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Product',
                  border: OutlineInputBorder(),
                ),
                items: available
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          '${p.name} (Stock ${p.stock})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selected = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity (max ${selected.stock})',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final qty = int.tryParse(qtyController.text) ?? 0;
                if (qty <= 0 || qty > selected.stock) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid quantity.')),
                  );
                  return;
                }

                Navigator.pop(
                  context,
                  BillItem(
                    productName: selected.name,
                    quantity: qty,
                    rate: selected.price,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final existingIndex =
          items.indexWhere((e) => e.productName == result.productName);

      if (existingIndex >= 0) {
        final product =
            widget.products.firstWhere((p) => p.name == result.productName);
        final newQty = items[existingIndex].quantity + result.quantity;
        if (newQty > product.stock) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Total quantity stock se zyada hai.')),
          );
          return;
        }
        items[existingIndex] = BillItem(
          productName: result.productName,
          quantity: newQty,
          rate: result.rate,
        );
      } else {
        items.add(result);
      }
      setState(() {});
    }
  }

  Future<void> saveBill() async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill me kam se kam ek item add karo.')),
      );
      return;
    }

    for (final item in items) {
      final product =
          widget.products.firstWhere((p) => p.name == item.productName);
      if (item.quantity > product.stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} ka stock kam hai.')),
        );
        return;
      }
    }

    for (final item in items) {
      final product =
          widget.products.firstWhere((p) => p.name == item.productName);
      product.stock -= item.quantity;
    }

    final now = DateTime.now();
    final billNo =
        'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';

    final bill = SavedBill(
      billNo: billNo,
      date:
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      customerName: customerName.text.trim(),
      customerMobile: customerMobile.text.trim(),
      subtotal: subtotal,
      discount: discount,
      gst: gst,
      total: total,
      items: List<BillItem>.from(items),
    );

    Navigator.pop(context, bill);
  }

  @override
  void dispose() {
    customerName.dispose();
    customerMobile.dispose();
    discountController.dispose();
    gstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Billing'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            controller: customerName,
            decoration: const InputDecoration(
              labelText: 'Customer Name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: customerMobile,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile Number',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: addItem,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add Product'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('No items added')),
              ),
            )
          else
            ...items.asMap().entries.map(
                  (entry) => Card(
                    child: ListTile(
                      title: Text(entry.value.productName),
                      subtitle: Text(
                        '${entry.value.quantity} × ₹${entry.value.rate.toStringAsFixed(2)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${entry.value.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => items.removeAt(entry.key));
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: discountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Discount ₹',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: gstController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'GST %',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  summaryRow('Subtotal', subtotal),
                  summaryRow('Discount', discount),
                  summaryRow('GST', gst),
                  const Divider(),
                  summaryRow('TOTAL', total, bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: saveBill,
            icon: const Icon(Icons.receipt_long),
            label: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('SAVE BILL & PRINT'),
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryRow(String title, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 18 : 15,
            ),
          ),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 18 : 15,
            ),
          ),
        ],
      ),
    );
  }
}

class BillsPage extends StatelessWidget {
  final List<SavedBill> bills;
  final Future<void> Function(SavedBill) onPrint;

  const BillsPage({
    super.key,
    required this.bills,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Bills')),
      body: bills.isEmpty
          ? const Center(child: Text('No bills yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: bills.length,
              itemBuilder: (context, index) {
                final bill = bills[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.receipt),
                    ),
                    title: Text(
                      bill.billNo,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${bill.date}\n'
                      '${bill.customerName.isEmpty ? 'Walk-in Customer' : bill.customerName}',
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '₹${bill.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => onPrint(bill),
                          icon: const Icon(Icons.print),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
