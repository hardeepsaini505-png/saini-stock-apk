import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

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

class GstSettings {
  String businessName;
  String gstin;
  String address;
  String state;
  String stateCode;
  double defaultRate;
  bool interState;

  GstSettings({
    this.businessName = 'SAINI INFO SOLUTIONS',
    this.gstin = '',
    this.address = '',
    this.state = 'Himachal Pradesh',
    this.stateCode = '02',
    this.defaultRate = 18,
    this.interState = false,
  });

  Map<String, dynamic> toJson() => {
    'businessName': businessName,
    'gstin': gstin,
    'address': address,
    'state': state,
    'stateCode': stateCode,
    'defaultRate': defaultRate,
    'interState': interState,
  };

  factory GstSettings.fromJson(Map<String, dynamic> json) => GstSettings(
    businessName: json['businessName'] ?? 'SAINI INFO SOLUTIONS',
    gstin: json['gstin'] ?? '',
    address: json['address'] ?? '',
    state: json['state'] ?? 'Himachal Pradesh',
    stateCode: json['stateCode'] ?? '02',
    defaultRate: (json['defaultRate'] as num?)?.toDouble() ?? 18,
    interState: json['interState'] ?? false,
  );
}

class Product {
  String name;
  String category;
  int stock;
  int lowLimit;
  double price;
  String hsn;
  double gstRate;
  String unit;
  String alternateUnit;
  int conversion;

  Product({
    required this.name,
    required this.category,
    required this.stock,
    this.lowLimit = 2,
    this.price = 0,
    this.hsn = '',
    this.gstRate = 18,
    this.unit = 'PCS',
    this.alternateUnit = '',
    this.conversion = 1,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'stock': stock,
        'lowLimit': lowLimit,
        'price': price,
        'hsn': hsn,
        'gstRate': gstRate,
        'unit': unit,
        'alternateUnit': alternateUnit,
        'conversion': conversion,
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      stock: json['stock'] ?? 0,
      lowLimit: json['lowLimit'] ?? 2,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      hsn: json['hsn'] ?? '',
      gstRate: (json['gstRate'] as num?)?.toDouble() ?? 18,
      unit: json['unit'] ?? 'PCS',
      alternateUnit: json['alternateUnit'] ?? '',
      conversion: (json['conversion'] as num?)?.toInt() ?? 1,
    );
  }
}

class BillItem {
  final String productName;
  final double quantity;
  final double rate;
  final String hsn;
  final double gstRate;
  final String unit;
  final double stockQuantity;

  BillItem({
    required this.productName,
    required this.quantity,
    required this.rate,
    this.hsn = '',
    this.gstRate = 0,
    this.unit = 'PCS',
    this.stockQuantity = 0,
  });

  double get amount => quantity * rate;
  double get gstAmount => amount * gstRate / 100;

  Map<String, dynamic> toJson() => {
        'productName': productName,
        'quantity': quantity,
        'rate': rate,
        'hsn': hsn,
        'gstRate': gstRate,
        'unit': unit,
        'stockQuantity': stockQuantity,
      };

  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
        productName: json['productName'] ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        rate: (json['rate'] as num?)?.toDouble() ?? 0,
        hsn: json['hsn'] ?? '',
        gstRate: (json['gstRate'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] ?? 'PCS',
        stockQuantity: (json['stockQuantity'] as num?)?.toDouble() ?? ((json['quantity'] as num?)?.toDouble() ?? 0),
      );
}

class SavedBill {
  final String billNo;
  final String date;
  final String customerName;
  final String customerMobile;
  final String customerGstin;
  final double subtotal;
  final double discount;
  final double taxable;
  final double cgst;
  final double sgst;
  final double igst;
  final double gst;
  final double total;
  final List<BillItem> items;

  SavedBill({
    required this.billNo,
    required this.date,
    required this.customerName,
    required this.customerMobile,
    this.customerGstin = '',
    required this.subtotal,
    required this.discount,
    this.taxable = 0,
    this.cgst = 0,
    this.sgst = 0,
    this.igst = 0,
    required this.gst,
    required this.total,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'billNo': billNo,
        'date': date,
        'customerName': customerName,
        'customerMobile': customerMobile,
        'customerGstin': customerGstin,
        'subtotal': subtotal,
        'discount': discount,
        'taxable': taxable,
        'cgst': cgst,
        'sgst': sgst,
        'igst': igst,
        'gst': gst,
        'total': total,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory SavedBill.fromJson(Map<String, dynamic> json) => SavedBill(
        billNo: json['billNo'] ?? '',
        date: json['date'] ?? '',
        customerName: json['customerName'] ?? '',
        customerMobile: json['customerMobile'] ?? '',
        customerGstin: json['customerGstin'] ?? '',
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
        taxable: (json['taxable'] as num?)?.toDouble() ?? ((json['subtotal'] as num?)?.toDouble() ?? 0) - ((json['discount'] as num?)?.toDouble() ?? 0),
        cgst: (json['cgst'] as num?)?.toDouble() ?? 0,
        sgst: (json['sgst'] as num?)?.toDouble() ?? 0,
        igst: (json['igst'] as num?)?.toDouble() ?? 0,
        gst: (json['gst'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
        items: (json['items'] as List? ?? [])
            .map((e) => BillItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}


class Purchase {
  final String purchaseNo;
  final String date;
  final String supplierName;
  final String supplierMobile;
  final String supplierGstin;
  final double taxable;
  final double cgst;
  final double sgst;
  final double igst;
  final double total;
  final double amountPaid;
  final String paymentMode;
  final List<PurchaseItem> items;

  Purchase({
    required this.purchaseNo,
    required this.date,
    required this.supplierName,
    required this.supplierMobile,
    this.supplierGstin = '',
    this.taxable = 0,
    this.cgst = 0,
    this.sgst = 0,
    this.igst = 0,
    required this.total,
    this.amountPaid = 0,
    this.paymentMode = 'Credit',
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'purchaseNo': purchaseNo,
        'date': date,
        'supplierName': supplierName,
        'supplierMobile': supplierMobile,
        'supplierGstin': supplierGstin,
        'taxable': taxable,
        'cgst': cgst,
        'sgst': sgst,
        'igst': igst,
        'total': total,
        'amountPaid': amountPaid,
        'paymentMode': paymentMode,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
        purchaseNo: json['purchaseNo'] ?? '',
        date: json['date'] ?? '',
        supplierName: json['supplierName'] ?? '',
        supplierMobile: json['supplierMobile'] ?? '',
        supplierGstin: json['supplierGstin'] ?? '',
        taxable: (json['taxable'] as num?)?.toDouble() ?? ((json['total'] as num?)?.toDouble() ?? 0),
        cgst: (json['cgst'] as num?)?.toDouble() ?? 0,
        sgst: (json['sgst'] as num?)?.toDouble() ?? 0,
        igst: (json['igst'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
        amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0,
        paymentMode: json['paymentMode'] ?? 'Credit',
        items: (json['items'] as List? ?? [])
            .map((e) => PurchaseItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class PurchaseItem {
  final String productName;
  final double quantity;
  final double rate;
  final String hsn;
  final double gstRate;
  final String unit;
  final double stockQuantity;

  PurchaseItem({
    required this.productName,
    required this.quantity,
    required this.rate,
    this.hsn = '',
    this.gstRate = 0,
    this.unit = 'PCS',
    this.stockQuantity = 0,
  });

  double get amount => quantity * rate;
  double get gstAmount => amount * gstRate / 100;

  Map<String, dynamic> toJson() => {
        'productName': productName,
        'quantity': quantity,
        'rate': rate,
        'hsn': hsn,
        'gstRate': gstRate,
        'unit': unit,
        'stockQuantity': stockQuantity,
      };

  factory PurchaseItem.fromJson(Map<String, dynamic> json) => PurchaseItem(
        productName: json['productName'] ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        rate: (json['rate'] as num?)?.toDouble() ?? 0,
        hsn: json['hsn'] ?? '',
        gstRate: (json['gstRate'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] ?? 'PCS',
        stockQuantity: (json['stockQuantity'] as num?)?.toDouble() ?? ((json['quantity'] as num?)?.toDouble() ?? 0),
      );
}

class Client {
  String name;
  String mobile;
  String address;
  String gstin;
  double balance;

  Client({
    required this.name,
    required this.mobile,
    this.address = '',
    this.gstin = '',
    this.balance = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'mobile': mobile,
        'address': address,
        'gstin': gstin,
        'balance': balance,
      };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        name: json['name'] ?? '',
        mobile: json['mobile'] ?? '',
        address: json['address'] ?? '',
        gstin: json['gstin'] ?? '',
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
      );
}


class LedgerEntry {
  final String date;
  final String clientName;
  final String type; // Sale / Payment
  final double amount;
  final String note;

  LedgerEntry({required this.date, required this.clientName, required this.type, required this.amount, this.note = ''});

  Map<String, dynamic> toJson() => {'date': date, 'clientName': clientName, 'type': type, 'amount': amount, 'note': note};

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
    date: json['date'] ?? '', clientName: json['clientName'] ?? '', type: json['type'] ?? 'Sale',
    amount: (json['amount'] as num?)?.toDouble() ?? 0, note: json['note'] ?? '',
  );
}

const professionalUnits = <String>['PCS','BOX','LTR','ML','KG','GRAM','MTR','CM','FEET','ROLL','PACK','SET','PAIR','DOZEN','BAG','BOTTLE','CAN','TIN','SHEET','NOS'];

class StockHome extends StatefulWidget {
  const StockHome({super.key});

  @override
  State<StockHome> createState() => _StockHomeState();
}

class _StockHomeState extends State<StockHome> {
  List<Product> products = [];
  List<SavedBill> bills = [];
  List<Purchase> purchases = [];
  List<Client> clients = [];
  List<LedgerEntry> ledger = [];
  GstSettings gstSettings = GstSettings();
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
    final purchaseData = prefs.getString('purchases');
    final clientData = prefs.getString('clients');
    final ledgerData = prefs.getString('ledger');
    final gstData = prefs.getString('gstSettings');

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

    if (purchaseData != null) {
      final list = jsonDecode(purchaseData) as List;
      purchases = list
          .map((e) => Purchase.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (ledgerData != null) {
      final list = jsonDecode(ledgerData) as List;
      ledger = list.map((e) => LedgerEntry.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    if (gstData != null) {
      gstSettings = GstSettings.fromJson(Map<String, dynamic>.from(jsonDecode(gstData)));
    }

    if (clientData != null) {
      final list = jsonDecode(clientData) as List;
      clients = list
          .map((e) => Client.fromJson(Map<String, dynamic>.from(e)))
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

  Future<void> savePurchases() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'purchases',
      jsonEncode(purchases.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> saveClients() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'clients',
      jsonEncode(clients.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> saveLedger() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ledger', jsonEncode(ledger.map((e) => e.toJson()).toList()));
  }

  Future<void> saveGstSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gstSettings', jsonEncode(gstSettings.toJson()));
  }

  int get totalStock => products.fold(0, (sum, p) => sum + p.stock);

  int get lowStock =>
      products.where((p) => p.stock > 0 && p.stock <= p.lowLimit).length;

  int get nilStock => products.where((p) => p.stock == 0).length;

  double get totalSales => bills.fold(0, (sum, b) => sum + b.total);

  double get totalPurchases => purchases.fold(0, (sum, p) => sum + p.total);

  double get totalReceivable => clients.fold(0, (sum, c) => sum + (c.balance > 0 ? c.balance : 0));

  double get totalPayable => purchases.fold(0, (sum, p) => sum + (p.total - p.amountPaid).clamp(0, double.infinity));

  double get totalPurchasePaid => purchases.fold(0, (sum, p) => sum + p.amountPaid);

  Future<void> addProduct() async {
    final name = TextEditingController();
    final category = TextEditingController();
    final qty = TextEditingController(text: '0');
    final price = TextEditingController(text: '0');
    final hsn = TextEditingController();
    final gstRate = TextEditingController(text: gstSettings.defaultRate.toStringAsFixed(0));
    String unit = 'PCS';
    String alternateUnit = 'BOX';
    final conversion = TextEditingController(text: '1');

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
              DropdownButtonFormField<String>(
                value: unit,
                decoration: const InputDecoration(labelText: 'Main Unit', border: OutlineInputBorder()),
                items: professionalUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => unit = v ?? 'PCS',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: alternateUnit,
                decoration: const InputDecoration(labelText: 'Alternate Unit (optional)', border: OutlineInputBorder()),
                items: ['NONE', ...professionalUnits].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => alternateUnit = v ?? 'NONE',
              ),
              const SizedBox(height: 12),
              TextField(controller: conversion, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '1 Main Unit = how many Alternate Units?', border: OutlineInputBorder(), hintText: 'Example: 1 BOX = 100 PCS')),
              const SizedBox(height: 12),
              TextField(
                controller: qty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Opening Stock (in Main Unit)',
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
              const SizedBox(height: 12),
              TextField(controller: hsn, decoration: const InputDecoration(labelText: 'HSN Code', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: gstRate, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'GST Rate %', suffixText: '%', border: OutlineInputBorder())),
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
                  stock: (int.tryParse(qty.text) ?? 0) * ((alternateUnit != 'NONE' && (int.tryParse(conversion.text) ?? 1) > 0) ? (int.tryParse(conversion.text) ?? 1) : 1),
                  price: double.tryParse(price.text) ?? 0,
                  hsn: hsn.text.trim(),
                  gstRate: double.tryParse(gstRate.text) ?? gstSettings.defaultRate,
                  unit: unit,
                  alternateUnit: alternateUnit == 'NONE' ? '' : alternateUnit,
                  conversion: (int.tryParse(conversion.text) ?? 1).clamp(1, 100000),
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
    final hsn = TextEditingController(text: product.hsn);
    final gstRate = TextEditingController(text: product.gstRate.toStringAsFixed(0));
    String unit = product.unit;
    String alternateUnit = product.alternateUnit.isEmpty ? 'NONE' : product.alternateUnit;
    final conversion = TextEditingController(text: product.conversion.toString());

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
            const SizedBox(height: 12),
            TextField(controller: hsn, decoration: const InputDecoration(labelText: 'HSN Code', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: gstRate, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'GST Rate %', suffixText: '%', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(value: unit, decoration: const InputDecoration(labelText: 'Main Unit', border: OutlineInputBorder()), items: professionalUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(), onChanged: (v) => unit = v ?? unit),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(value: alternateUnit, decoration: const InputDecoration(labelText: 'Alternate Unit', border: OutlineInputBorder()), items: ['NONE', ...professionalUnits].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(), onChanged: (v) => alternateUnit = v ?? alternateUnit),
            const SizedBox(height: 12),
            TextField(controller: conversion, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Conversion', border: OutlineInputBorder(), hintText: '1 BOX = 100 PCS')),
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
              product.hsn = hsn.text.trim();
              product.gstRate = double.tryParse(gstRate.text) ?? product.gstRate;
              product.unit = unit;
              product.alternateUnit = alternateUnit == 'NONE' ? '' : alternateUnit;
              product.conversion = (int.tryParse(conversion.text) ?? product.conversion).clamp(1, 100000);
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

  String stockDisplay(Product p) {
    if (p.alternateUnit.isEmpty || p.conversion <= 1) return '${p.stock} ${p.unit}';
    final mainQty = p.stock ~/ p.conversion;
    final altQty = p.stock % p.conversion;
    if (altQty == 0) return '$mainQty ${p.unit}';
    return '$mainQty ${p.unit} + $altQty ${p.alternateUnit}';
  }

  Future<void> changeStock(Product product, bool stockIn) async {
    final qty = TextEditingController();
    String selectedUnit = product.alternateUnit.isNotEmpty ? product.alternateUnit : product.unit;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(stockIn ? 'Stock In' : 'Stock Out'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Stock: ${stockDisplay(product)}'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedUnit,
                decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                items: [product.unit, if (product.alternateUnit.isNotEmpty) product.alternateUnit]
                    .toSet()
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedUnit = v ?? product.unit),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qty,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(qty.text) ?? 0;
                final baseAmount = selectedUnit == product.unit ? amount * product.conversion : amount;
                if (amount <= 0) return;
                if (stockIn) {
                  product.stock += baseAmount.round();
                } else {
                  if (baseAmount > product.stock) {
                    ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Stock Out quantity is greater than stock.')));
                    return;
                  }
                  product.stock -= baseAmount.round();
                }
                saveProducts();
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
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


  Future<void> addClient() async {
    final name = TextEditingController();
    final mobile = TextEditingController();
    final address = TextEditingController();
    final gstin = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Client'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Client Name', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: mobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: address, maxLines: 2, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: gstin, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'GSTIN (optional)', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              clients.add(Client(name: name.text.trim(), mobile: mobile.text.trim(), address: address.text.trim(), gstin: gstin.text.trim().toUpperCase()));
              await saveClients();
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Save Client'),
          ),
        ],
      ),
    );
    if (result == true && mounted) setState(() {});
  }


  String _cleanPhone(String phone) {
    var p = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (p.startsWith('+')) p = p.substring(1);
    if (p.length == 10) p = '91$p';
    return p;
  }

  Future<void> sendWhatsAppReminder(Client client) async {
    if (client.mobile.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Client mobile number nahi hai.')));
      return;
    }
    if (client.balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Is client ka pending balance nahi hai.')));
      return;
    }
    final message = 'Namaste ${client.name},%0A%0AAapke account me ₹${client.balance.toStringAsFixed(2)} payment pending hai.%0AKripya payment karne ke baad screenshot share kar dein.%0A%0AThanks,%0A${gstSettings.businessName}';
    final uri = Uri.parse('https://wa.me/${_cleanPhone(client.mobile)}?text=$message');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp open nahi ho paya.')));
    }
  }

  Future<void> receivePayment(Client client) async {
    if (client.balance <= 0) return;
    final amount = TextEditingController(text: client.balance.toStringAsFixed(2));
    final note = TextEditingController(text: 'Payment received');
    final result = await showDialog<double>(context: context, builder: (context) => AlertDialog(
      title: Text('Receive Payment — ${client.name}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Current due: ₹${client.balance.toStringAsFixed(2)}'), const SizedBox(height: 12),
        TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Received Amount', prefixText: '₹ ', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: note, decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder())),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () {
        final v = double.tryParse(amount.text) ?? 0;
        if (v > 0 && v <= client.balance) Navigator.pop(context, v);
      }, child: const Text('Save Payment'))],
    ));
    if (result == null) return;
    final now = DateTime.now();
    final date = '${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}';
    client.balance -= result;
    ledger.insert(0, LedgerEntry(date: date, clientName: client.name, type: 'Payment', amount: result, note: note.text.trim()));
    await saveClients();
    await saveLedger();
    if (mounted) setState(() {});
  }

  Future<void> showDaybook() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => DaybookPage(bills: bills, purchases: purchases, ledger: ledger)));
  }

  Future<void> showLedger() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => LedgerPage(clients: clients, ledger: ledger, onReceivePayment: receivePayment, onReminder: sendWhatsAppReminder)));
  }

  Future<void> showReminders() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentReminderPage(clients: clients, onReminder: sendWhatsAppReminder, onReceivePayment: receivePayment)));
  }

  Future<void> showClients() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientsPage(
          clients: clients,
          onAdd: addClient,
          onSave: saveClients,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> createPurchase() async {
    if (products.isEmpty) {
      await addProduct();
      if (products.isEmpty) return;
    }
    final supplier = TextEditingController();
    final mobile = TextEditingController();
    final supplierGstin = TextEditingController();
    final paidAmount = TextEditingController(text: '0');
    String paymentMode = 'Credit';
    final selected = <String>{};
    final selectedUnit = <String, String>{};
    final qty = <String, TextEditingController>{};
    final rate = <String, TextEditingController>{};

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double taxable = 0;
          double gst = 0;
          for (final name in selected) {
            final q = double.tryParse(qty[name]?.text ?? '') ?? 0;
            final r = double.tryParse(rate[name]?.text ?? '') ?? 0;
            final product = products.firstWhere((p) => p.name == name);
            final amount = q * r;
            taxable += amount;
            gst += amount * product.gstRate / 100;
          }
          final total = taxable + gst;
          return AlertDialog(
            title: const Text('New Purchase'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(controller: supplier, decoration: const InputDecoration(labelText: 'Supplier Name', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: mobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Supplier Mobile', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: supplierGstin, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Supplier GSTIN (optional)', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: paymentMode,
                      decoration: const InputDecoration(labelText: 'Payment Mode', border: OutlineInputBorder()),
                      items: const [DropdownMenuItem(value: 'Credit', child: Text('Credit / Pending')), DropdownMenuItem(value: 'Cash', child: Text('Cash')), DropdownMenuItem(value: 'UPI', child: Text('UPI')), DropdownMenuItem(value: 'Bank', child: Text('Bank'))],
                      onChanged: (v) => setDialogState(() => paymentMode = v ?? 'Credit'),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: paidAmount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount Paid', prefixText: '₹ ', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    ...products.map((p) => Card(
                      child: CheckboxListTile(
                        value: selected.contains(p.name),
                        title: Text(p.name),
                        subtitle: Text('Current stock: ${p.stock}'),
                        onChanged: (v) {
                          setDialogState(() {
                            if (v == true) {
                              selected.add(p.name);
                              selectedUnit[p.name] = p.alternateUnit.isNotEmpty ? p.alternateUnit : p.unit;
                              qty[p.name] = TextEditingController(text: '1');
                              rate[p.name] = TextEditingController(text: p.price.toStringAsFixed(2));
                            } else {
                              selected.remove(p.name);
                              selectedUnit.remove(p.name);
                              qty.remove(p.name)?.dispose();
                              rate.remove(p.name)?.dispose();
                            }
                          });
                        },
                      ),
                    )),
                    if (selected.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...selected.map((name) => Row(
                        children: [
                          Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          SizedBox(width: 90, child: DropdownButtonFormField<String>(value: selectedUnit[name], isExpanded: true, decoration: const InputDecoration(labelText: 'Unit'), items: [products.firstWhere((p) => p.name == name).unit, if (products.firstWhere((p) => p.name == name).alternateUnit.isNotEmpty) products.firstWhere((p) => p.name == name).alternateUnit].toSet().map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(), onChanged: (v) => setDialogState(() => selectedUnit[name] = v ?? selectedUnit[name]!))),
                          const SizedBox(width: 6),
                          SizedBox(width: 70, child: TextField(controller: qty[name], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Qty'))),
                          const SizedBox(width: 8),
                          SizedBox(width: 90, child: TextField(controller: rate[name], keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Rate'))),
                        ],
                      )),
                      const SizedBox(height: 12),
                      Align(alignment: Alignment.centerRight, child: Text('Total: ₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  if (selected.isEmpty) return;
                  final items = <PurchaseItem>[];
                  for (final name in selected) {
                    final q = double.tryParse(qty[name]?.text ?? '') ?? 0;
                    final r = double.tryParse(rate[name]?.text ?? '') ?? 0;
                    if (q <= 0) return;
                    final product = products.firstWhere((p) => p.name == name);
                    final purchaseUnit = selectedUnit[name] ?? product.unit;
                    final stockQty = purchaseUnit == product.unit ? q * product.conversion : q;
                    items.add(PurchaseItem(productName: name, quantity: q, rate: r, hsn: product.hsn, gstRate: product.gstRate, unit: purchaseUnit, stockQuantity: stockQty));
                    product.stock += stockQty.round();
                    product.price = r > 0 ? product.price : product.price;
                  }
                  final purchase = Purchase(
                    purchaseNo: 'PUR-${DateTime.now().millisecondsSinceEpoch}',
                    date: DateTime.now().toString().substring(0, 16),
                    supplierName: supplier.text.trim(),
                    supplierMobile: mobile.text.trim(),
                    supplierGstin: supplierGstin.text.trim().toUpperCase(),
                    taxable: items.fold(0, (sum, i) => sum + i.amount),
                    cgst: gstSettings.interState ? 0 : items.fold(0, (sum, i) => sum + i.gstAmount / 2),
                    sgst: gstSettings.interState ? 0 : items.fold(0, (sum, i) => sum + i.gstAmount / 2),
                    igst: gstSettings.interState ? items.fold(0, (sum, i) => sum + i.gstAmount) : 0,
                    total: items.fold(0, (sum, i) => sum + i.amount + i.gstAmount),
                    amountPaid: (double.tryParse(paidAmount.text) ?? 0).clamp(0, items.fold<double>(0, (sum, i) => sum + i.amount + i.gstAmount)),
                    paymentMode: paymentMode,
                    items: items,
                  );
                  purchases.insert(0, purchase);
                  if (purchase.supplierName.isNotEmpty) {
                    ledger.insert(0, LedgerEntry(date: purchase.date, clientName: purchase.supplierName, type: 'Purchase', amount: purchase.total, note: purchase.purchaseNo));
                    if (purchase.amountPaid > 0) ledger.insert(0, LedgerEntry(date: purchase.date, clientName: purchase.supplierName, type: 'Supplier Payment', amount: purchase.amountPaid, note: paymentMode));
                  }
                  await saveProducts();
                  await savePurchases();
                  await saveLedger();
                  if (context.mounted) Navigator.pop(context, true);
                },
                child: const Text('Save Purchase'),
              ),
            ],
          );
        },
      ),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<void> showGstSettings() async {
    final name = TextEditingController(text: gstSettings.businessName);
    final gstin = TextEditingController(text: gstSettings.gstin);
    final address = TextEditingController(text: gstSettings.address);
    final state = TextEditingController(text: gstSettings.state);
    final stateCode = TextEditingController(text: gstSettings.stateCode);
    final rate = TextEditingController(text: gstSettings.defaultRate.toStringAsFixed(0));
    bool interState = gstSettings.interState;
    final saved = await showDialog<bool>(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: const Text('GST Settings'),
      content: SingleChildScrollView(child: Column(children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Business / Legal Name', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: gstin, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'GSTIN', hintText: 'e.g. 02ABCDE1234F1Z5', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: address, maxLines: 2, decoration: const InputDecoration(labelText: 'Business Address', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: TextField(controller: state, decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()))), const SizedBox(width: 8), SizedBox(width: 85, child: TextField(controller: stateCode, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Code', border: OutlineInputBorder())))]),
        const SizedBox(height: 10),
        TextField(controller: rate, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Default GST Rate %', suffixText: '%', border: OutlineInputBorder())),
        SwitchListTile(title: const Text('Inter-State Sale / Purchase (IGST)'), value: interState, onChanged: (v) => setDialogState(() => interState = v)),
        const Align(alignment: Alignment.centerLeft, child: Text('Same-state transactions use CGST + SGST.', style: TextStyle(color: Colors.grey, fontSize: 12))),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () async {
        gstSettings = GstSettings(businessName: name.text.trim().isEmpty ? 'SAINI INFO SOLUTIONS' : name.text.trim(), gstin: gstin.text.trim().toUpperCase(), address: address.text.trim(), state: state.text.trim(), stateCode: stateCode.text.trim(), defaultRate: double.tryParse(rate.text) ?? 18, interState: interState);
        await saveGstSettings();
        if (context.mounted) Navigator.pop(context, true);
      }, child: const Text('Save GST Settings'))],
    )));
    if (saved == true && mounted) setState(() {});
  }

  double supplierBalance(String supplierName) {
    final purchaseTotal = purchases.where((p) => p.supplierName.toLowerCase() == supplierName.toLowerCase()).fold<double>(0, (s, p) => s + p.total);
    final paid = ledger.where((e) => e.clientName.toLowerCase() == supplierName.toLowerCase() && e.type == 'Supplier Payment').fold<double>(0, (s, e) => s + e.amount);
    return (purchaseTotal - paid).clamp(0, double.infinity);
  }

  Future<void> paySupplier(String supplierName) async {
    final due = supplierBalance(supplierName);
    if (due <= 0) return;
    final amount = TextEditingController(text: due.toStringAsFixed(2));
    final note = TextEditingController();
    final result = await showDialog<double>(context: context, builder: (context) => AlertDialog(
      title: Text('Pay Supplier — $supplierName'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Pending: ₹${due.toStringAsFixed(2)}'), const SizedBox(height: 12),
        TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Payment Amount', prefixText: '₹ ', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: note, decoration: const InputDecoration(labelText: 'Note / Reference', border: OutlineInputBorder())),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { final v=double.tryParse(amount.text)??0; if(v>0 && v<=due) Navigator.pop(context,v); }, child: const Text('Save Payment'))],
    ));
    if (result == null) return;
    ledger.insert(0, LedgerEntry(date: DateTime.now().toString().substring(0,16), clientName: supplierName, type: 'Supplier Payment', amount: result, note: note.text.trim()));
    await saveLedger();
    if (mounted) setState(() {});
  }

  Future<void> showBalanceSheet() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => BalanceSheetPage(
      sales: totalSales, purchases: totalPurchases, stockValue: products.fold<double>(0, (s,p)=>s + p.stock * p.price),
      receivable: totalReceivable, payable: totalPayable, gstInput: purchases.fold<double>(0,(s,p)=>s+p.cgst+p.sgst+p.igst),
      gstOutput: bills.fold<double>(0,(s,b)=>s+b.cgst+b.sgst+b.igst), cashIn: bills.fold<double>(0,(s,b)=>s+b.total) - totalReceivable,
      cashOut: totalPurchasePaid,
    )));
  }

  Future<void> showPurchases() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PurchasesPage(purchases: purchases)),
    );
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
        builder: (_) => BillingPage(products: products, gstSettings: gstSettings),
      ),
    );

    if (result != null) {
      bills.insert(0, result);
      final client = clients.cast<Client?>().firstWhere((c) => c?.name.toLowerCase() == result.customerName.toLowerCase(), orElse: () => null);
      if (client != null && result.customerName.trim().isNotEmpty) {
        client.balance += result.total;
        ledger.insert(0, LedgerEntry(date: result.date, clientName: client.name, type: 'Sale', amount: result.total, note: result.billNo));
      }
      await saveProducts();
      await saveBills();
      await saveClients();
      await saveLedger();
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
            gstSettings.businessName,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text('Tax Invoice'),
          if (gstSettings.gstin.isNotEmpty) pw.Text('GSTIN: ${gstSettings.gstin}'),
          if (gstSettings.address.isNotEmpty) pw.Text(gstSettings.address),
          pw.Text('Tax Mode: ${gstSettings.interState ? 'IGST (Inter-State)' : 'CGST + SGST (Intra-State)'}'),
          pw.SizedBox(height: 12),
          pw.Text('Bill No: ${bill.billNo}'),
          pw.Text('Date: ${bill.date}'),
          if (bill.customerName.isNotEmpty)
            pw.Text('Customer: ${bill.customerName}'),
          if (bill.customerMobile.isNotEmpty)
            pw.Text('Mobile: ${bill.customerMobile}'),
          if (bill.customerGstin.isNotEmpty)
            pw.Text('Customer GSTIN: ${bill.customerGstin}'),
          pw.SizedBox(height: 15),
          pw.Table.fromTextArray(
            headers: ['Product / HSN', 'Qty', 'Rate', 'Taxable', 'GST'],
            data: bill.items
                .map((item) => [
                      '${item.productName}\nHSN: ${item.hsn.isEmpty ? '-' : item.hsn}',
                      '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2)} ${item.unit}',
                      '₹${item.rate.toStringAsFixed(2)}',
                      '₹${item.amount.toStringAsFixed(2)}',
                      '${item.gstRate.toStringAsFixed(0)}%\n₹${item.gstAmount.toStringAsFixed(2)}',
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
                pw.Text('Taxable Value: ₹${bill.taxable.toStringAsFixed(2)}'),
                if (bill.cgst > 0) pw.Text('CGST: ₹${bill.cgst.toStringAsFixed(2)}'),
                if (bill.sgst > 0) pw.Text('SGST: ₹${bill.sgst.toStringAsFixed(2)}'),
                if (bill.igst > 0) pw.Text('IGST: ₹${bill.igst.toStringAsFixed(2)}'),
                pw.Text('Total GST: ₹${bill.gst.toStringAsFixed(2)}'),
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
            headers: ['Product', 'HSN', 'GST', 'Unit', 'Category', 'Stock (base)', 'Rate', 'Status'],
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
                p.hsn.isEmpty ? '-' : p.hsn,
                '${p.gstRate.toStringAsFixed(0)}%',
                p.unit + (p.alternateUnit.isEmpty ? '' : ' / ${p.alternateUnit}'),
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
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saini Billing & Accounting', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Professional Billing Software', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(tooltip: 'All Reports', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsPage(products: products, bills: bills, purchases: purchases, clients: clients, totalStock: totalStock, lowStock: lowStock, nilStock: nilStock))), icon: const Icon(Icons.analytics_outlined)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Business Overview', style: TextStyle(color: Colors.white70)), SizedBox(height: 5), Text('Manage your business easily', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))])),
                  CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.storefront, size: 32, color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                dashboardButton('New Sale', 'Create invoice', Icons.point_of_sale, () => createBill()),
                dashboardButton('Purchase', 'Add stock', Icons.shopping_cart_checkout, () => createPurchase()),
                dashboardButton('Add Item', 'Products / Stock', Icons.inventory_2, () => addProduct()),
                dashboardButton('Clients', '${clients.length} saved', Icons.people_alt, () => showClients()),
                dashboardButton('Day Book', 'Daily transactions', Icons.menu_book, () => showDaybook()),
                dashboardButton('Ledger', 'Client balances', Icons.account_balance_wallet, () => showLedger()),
                dashboardButton('Receivable', 'Payment to receive', Icons.call_received, () => showReminders()),
                dashboardButton('Payable', 'Supplier payment due', Icons.call_made, () => Navigator.push(context, MaterialPageRoute(builder: (_) => PayablePage(purchases: purchases, ledger: ledger, onPay: paySupplier)))),
                dashboardButton('Balance Sheet', 'Assets & liabilities', Icons.account_balance, () => showBalanceSheet()),
                dashboardButton('Payment Reminder', 'WhatsApp reminders', Icons.notifications_active, () => showReminders()),
                dashboardButton('Sale Reports', '${bills.length} invoices', Icons.receipt_long, () => showBills()),
                dashboardButton('Purchase Reports', '${purchases.length} purchases', Icons.fact_check, () => showPurchases()),
                dashboardButton('Stock Report', '$totalStock total qty', Icons.warehouse, () => generatePdf()),
                dashboardButton('All Reports', 'Business summary', Icons.bar_chart, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsPage(products: products, bills: bills, purchases: purchases, clients: clients, totalStock: totalStock, lowStock: lowStock, nilStock: nilStock)))),
                dashboardButton('GST Settings', gstSettings.gstin.isEmpty ? 'Add GSTIN' : gstSettings.gstin, Icons.receipt_long, () => showGstSettings()),
                dashboardButton('GST Report', 'Output & Input GST', Icons.account_balance, () => Navigator.push(context, MaterialPageRoute(builder: (_) => GstReportPage(bills: bills, purchases: purchases)))),
              ],
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: statCard('Sales', '₹${totalSales.toStringAsFixed(0)}', Icons.trending_up)),
              const SizedBox(width: 8),
              Expanded(child: statCard('Purchase', '₹${totalPurchases.toStringAsFixed(0)}', Icons.shopping_bag)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: statCard('Low Stock', lowStock.toString(), Icons.warning_amber)),
              const SizedBox(width: 8),
              Expanded(child: statCard('Nil Stock', nilStock.toString(), Icons.remove_shopping_cart)),
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search item / product...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty ? IconButton(onPressed: () { searchController.clear(); setState(() {}); }, icon: const Icon(Icons.clear)) : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            if (filtered.isEmpty)
              const Padding(padding: EdgeInsets.all(35), child: Center(child: Text('No products found. Use Add Item to start.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey))))
            else
              ...filtered.map((product) {
                final statusColor = product.stock == 0 ? Colors.red : (product.stock <= product.lowLimit ? Colors.orange : Colors.green);
                return Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: statusColor, child: Text(product.stock.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${stockDisplay(product)} • ${product.category.isEmpty ? 'No Category' : product.category} • ${product.unit}${product.alternateUnit.isEmpty ? '' : ' / ${product.alternateUnit}'} • HSN ${product.hsn.isEmpty ? '-' : product.hsn} • GST ${product.gstRate.toStringAsFixed(0)}% • ₹${product.price.toStringAsFixed(2)}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) { if (value == 'in') changeStock(product, true); else if (value == 'out') changeStock(product, false); else if (value == 'edit') editProduct(product); else if (value == 'delete') deleteProduct(product); },
                      itemBuilder: (_) => const [PopupMenuItem(value: 'in', child: Text('Stock In')), PopupMenuItem(value: 'out', child: Text('Stock Out')), PopupMenuItem(value: 'edit', child: Text('Edit Price / Low Limit')), PopupMenuItem(value: 'delete', child: Text('Delete'))],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget dashboardButton(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            CircleAvatar(radius: 22, child: Icon(icon, size: 23)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
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


class ClientsPage extends StatefulWidget {
  final List<Client> clients;
  final Future<void> Function() onAdd;
  final Future<void> Function() onSave;
  const ClientsPage({super.key, required this.clients, required this.onAdd, required this.onSave});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients'), actions: [IconButton(onPressed: widget.onAdd, icon: const Icon(Icons.person_add))]),
      floatingActionButton: FloatingActionButton.extended(onPressed: widget.onAdd, icon: const Icon(Icons.person_add), label: const Text('Add Client')),
      body: widget.clients.isEmpty
          ? const Center(child: Text('No clients added yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.clients.length,
              itemBuilder: (_, i) {
                final c = widget.clients[i];
                return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${c.mobile}\n${c.address.isEmpty ? 'No address' : c.address}${c.gstin.isEmpty ? '' : '\nGSTIN: ${c.gstin}'}'), isThreeLine: true, trailing: Text('₹${c.balance.toStringAsFixed(0)}')));
              },
            ),
    );
  }
}


class DaybookPage extends StatelessWidget {
  final List<SavedBill> bills;
  final List<Purchase> purchases;
  final List<LedgerEntry> ledger;
  const DaybookPage({super.key, required this.bills, required this.purchases, required this.ledger});

  @override
  Widget build(BuildContext context) {
    final entries = <Map<String, dynamic>>[];
    for (final b in bills) entries.add({'date': b.date, 'title': 'Sale ${b.billNo}', 'party': b.customerName.isEmpty ? 'Cash Customer' : b.customerName, 'amount': b.total, 'icon': Icons.point_of_sale, 'type': 'Sale'});
    for (final p in purchases) entries.add({'date': p.date, 'title': 'Purchase ${p.purchaseNo}', 'party': p.supplierName.isEmpty ? 'Cash Purchase' : p.supplierName, 'amount': p.total, 'icon': Icons.shopping_cart, 'type': 'Purchase'});
    for (final l in ledger.where((e) => e.type == 'Payment')) entries.add({'date': l.date, 'title': 'Payment Received', 'party': l.clientName, 'amount': l.amount, 'icon': Icons.payments, 'type': 'Payment'});
    entries.sort((a,b) => b['date'].toString().compareTo(a['date'].toString()));
    return Scaffold(appBar: AppBar(title: const Text('Day Book')), body: entries.isEmpty ? const Center(child: Text('No transactions yet.')) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: entries.length, itemBuilder: (_,i) { final e=entries[i]; return Card(child: ListTile(leading: CircleAvatar(child: Icon(e['icon'] as IconData)), title: Text(e['title']), subtitle: Text('${e['date']} • ${e['party']}'), trailing: Text('₹${(e['amount'] as double).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)))); }));
  }
}

class LedgerPage extends StatelessWidget {
  final List<Client> clients;
  final List<LedgerEntry> ledger;
  final Future<void> Function(Client) onReceivePayment;
  final Future<void> Function(Client) onReminder;
  const LedgerPage({super.key, required this.clients, required this.ledger, required this.onReceivePayment, required this.onReminder});

  @override
  Widget build(BuildContext context) {
    final dueClients = clients.where((c) => c.balance > 0).toList();
    return Scaffold(appBar: AppBar(title: const Text('Client Ledger')), body: dueClients.isEmpty ? const Center(child: Text('Kisi client ka outstanding balance nahi hai.')) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: dueClients.length, itemBuilder: (_,i) { final c=dueClients[i]; final tx=ledger.where((e)=>e.clientName.toLowerCase()==c.name.toLowerCase()).toList(); return Card(child: ExpansionTile(title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${c.mobile}\nOutstanding: ₹${c.balance.toStringAsFixed(2)}'), trailing: PopupMenuButton<String>(onSelected: (v){ if(v=='pay') onReceivePayment(c); if(v=='wa') onReminder(c); }, itemBuilder: (_)=>const [PopupMenuItem(value:'pay', child: Text('Receive Payment')), PopupMenuItem(value:'wa', child: Text('WhatsApp Reminder'))]), children: tx.map((e)=>ListTile(dense:true, title: Text(e.type), subtitle: Text('${e.date} ${e.note.isEmpty?'':'• ${e.note}'}'), trailing: Text('₹${e.amount.toStringAsFixed(2)}'))).toList())); }));
  }
}

class PaymentReminderPage extends StatelessWidget {
  final List<Client> clients;
  final Future<void> Function(Client) onReminder;
  final Future<void> Function(Client) onReceivePayment;
  const PaymentReminderPage({super.key, required this.clients, required this.onReminder, required this.onReceivePayment});

  @override
  Widget build(BuildContext context) {
    final due = clients.where((c) => c.balance > 0).toList();
    final total = due.fold<double>(0, (s, c) => s + c.balance);
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Reminders')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(Icons.notifications_active),
              title: Text('${due.length} clients pending'),
              trailing: Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
          Expanded(
            child: due.isEmpty
                ? const Center(child: Text('No pending payments.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: due.length,
                    itemBuilder: (_, i) {
                      final c = due[i];
                      return Card(
                        child: ListTile(
                          title: Text(c.name),
                          subtitle: Text('${c.mobile}\nPending: ₹${c.balance.toStringAsFixed(2)}'),
                          isThreeLine: true,
                          trailing: Wrap(
                            children: [
                              IconButton(tooltip: 'Receive Payment', onPressed: () => onReceivePayment(c), icon: const Icon(Icons.payments)),
                              IconButton(tooltip: 'WhatsApp', onPressed: () => onReminder(c), icon: const Icon(Icons.chat)),
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
}

class PayablePage extends StatelessWidget {
  final List<Purchase> purchases;
  final List<LedgerEntry> ledger;
  final Future<void> Function(String) onPay;
  const PayablePage({super.key, required this.purchases, required this.ledger, required this.onPay});

  double due(String name) {
    final total = purchases.where((p) => p.supplierName.toLowerCase() == name.toLowerCase()).fold<double>(0, (s, p) => s + p.total);
    final paid = ledger.where((e) => e.clientName.toLowerCase() == name.toLowerCase() && e.type == 'Supplier Payment').fold<double>(0, (s, e) => s + e.amount);
    return (total - paid).clamp(0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final names = purchases.map((p) => p.supplierName).where((n) => n.trim().isNotEmpty).toSet().toList();
    final pending = names.where((n) => due(n) > 0).toList();
    final total = pending.fold<double>(0, (s, n) => s + due(n));
    return Scaffold(
      appBar: AppBar(title: const Text('Payable — Supplier Payments')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(Icons.call_made),
              title: Text('${pending.length} suppliers pending'),
              subtitle: const Text('Payment to give'),
              trailing: Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: pending.isEmpty
                ? const Center(child: Text('No supplier payment pending.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: pending.length,
                    itemBuilder: (_, i) {
                      final n = pending[i];
                      final d = due(n);
                      return Card(
                        child: ListTile(
                          title: Text(n, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Pending: ₹${d.toStringAsFixed(2)}'),
                          trailing: FilledButton.icon(onPressed: () => onPay(n), icon: const Icon(Icons.payments), label: const Text('Pay')),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class BalanceSheetPage extends StatelessWidget {
  final double sales,purchases,stockValue,receivable,payable,gstInput,gstOutput,cashIn,cashOut;
  const BalanceSheetPage({super.key,required this.sales,required this.purchases,required this.stockValue,required this.receivable,required this.payable,required this.gstInput,required this.gstOutput,required this.cashIn,required this.cashOut});
  Widget row(String a,double v,{bool bold=false})=>Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(a,style:TextStyle(fontWeight:bold?FontWeight.bold:FontWeight.normal)),Text('₹${v.toStringAsFixed(2)}',style:TextStyle(fontWeight:bold?FontWeight.bold:FontWeight.normal))]));
  @override Widget build(BuildContext context){
    final gstPayable=(gstOutput-gstInput);
    final assets=stockValue+receivable+cashIn;
    final liabilities=payable+(gstPayable>0?gstPayable:0);
    return Scaffold(appBar:AppBar(title:const Text('Balance Sheet')),body:ListView(padding:const EdgeInsets.all(14),children:[
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('ASSETS',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),row('Stock Value',stockValue),row('Customer Receivable',receivable),row('Estimated Cash / Bank',cashIn),const Divider(),row('Total Assets',assets,bold:true)]))),
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('LIABILITIES',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),row('Supplier Payable',payable),row('GST Payable',gstPayable>0?gstPayable:0),const Divider(),row('Total Liabilities',liabilities,bold:true)]))),
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('BUSINESS SUMMARY',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),row('Total Sales',sales),row('Total Purchase',purchases),row('Input GST',gstInput),row('Output GST',gstOutput),row('GST Credit',gstPayable<0?-gstPayable:0)]))),
    ]));
  }
}

class PurchasesPage extends StatelessWidget {
  final List<Purchase> purchases;
  const PurchasesPage({super.key, required this.purchases});

  @override
  Widget build(BuildContext context) {
    final total = purchases.fold<double>(0, (sum, p) => sum + p.total);
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Reports')),
      body: Column(children: [
        Card(margin: const EdgeInsets.all(12), child: ListTile(title: const Text('Total Purchase'), subtitle: Text('${purchases.length} purchase entries'), trailing: Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)))),
        Expanded(child: purchases.isEmpty ? const Center(child: Text('No purchases yet.')) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: purchases.length, itemBuilder: (_, i) { final p=purchases[i]; return Card(child: ListTile(title: Text(p.supplierName.isEmpty ? 'Cash Purchase' : p.supplierName), subtitle: Text('${p.date}\n${p.items.length} items • GST ₹${(p.cgst + p.sgst + p.igst).toStringAsFixed(2)} • Paid ₹${p.amountPaid.toStringAsFixed(2)} • Due ₹${(p.total-p.amountPaid).clamp(0,double.infinity).toStringAsFixed(2)}${p.supplierGstin.isEmpty ? '' : '\nGSTIN: ${p.supplierGstin}'}'), isThreeLine: true, trailing: Text('₹${p.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)))); }))
      ]),
    );
  }
}

class ReportsPage extends StatelessWidget {
  final List<Product> products;
  final List<SavedBill> bills;
  final List<Purchase> purchases;
  final List<Client> clients;
  final int totalStock;
  final int lowStock;
  final int nilStock;

  const ReportsPage({super.key, required this.products, required this.bills, required this.purchases, required this.clients, required this.totalStock, required this.lowStock, required this.nilStock});

  @override
  Widget build(BuildContext context) {
    final sales = bills.fold<double>(0, (s, b) => s + b.total);
    final purchase = purchases.fold<double>(0, (s, p) => s + p.total);
    final net = sales - purchase;
    final outputGst = bills.fold<double>(0, (s, b) => s + b.gst);
    final inputGst = purchases.fold<double>(0, (s, p) => s + p.cgst + p.sgst + p.igst);
    final gstPayable = outputGst - inputGst;
    return Scaffold(
      appBar: AppBar(title: const Text('All Reports')),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        const Text('Business Summary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: _reportCard('Total Sales', '₹${sales.toStringAsFixed(2)}', Icons.trending_up)), const SizedBox(width: 8), Expanded(child: _reportCard('Purchases', '₹${purchase.toStringAsFixed(2)}', Icons.shopping_cart))]),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: _reportCard('Net', '₹${net.toStringAsFixed(2)}', Icons.account_balance)), const SizedBox(width: 8), Expanded(child: _reportCard('Clients', clients.length.toString(), Icons.people))]),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: _reportCard('Output GST', '₹${outputGst.toStringAsFixed(2)}', Icons.upload)), const SizedBox(width: 8), Expanded(child: _reportCard('Input GST', '₹${inputGst.toStringAsFixed(2)}', Icons.download))]),
        const SizedBox(height: 8),
        _reportCard('GST Payable / (Credit)', '₹${gstPayable.toStringAsFixed(2)}', Icons.account_balance_wallet),
        const SizedBox(height: 14),
        Card(child: ListTile(leading: const Icon(Icons.inventory_2), title: const Text('Stock Report'), subtitle: Text('Products: ${products.length}\nTotal Qty: $totalStock\nLow Stock: $lowStock\nNil Stock: $nilStock'))),
        Card(child: ListTile(leading: const Icon(Icons.receipt_long), title: const Text('Sales Report'), subtitle: Text('Invoices: ${bills.length}\nTotal Sales: ₹${sales.toStringAsFixed(2)}'))),
        Card(child: ListTile(leading: const Icon(Icons.shopping_bag), title: const Text('Purchase Report'), subtitle: Text('Entries: ${purchases.length}\nTotal Purchase: ₹${purchase.toStringAsFixed(2)}'))),
        Card(child: ListTile(leading: const Icon(Icons.people_alt), title: const Text('Client Report'), subtitle: Text('Total Clients: ${clients.length}'))),
      ]),
    );
  }

  static Widget _reportCard(String title, String value, IconData icon) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 28), const SizedBox(height: 8), Text(title, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))])));
}

class GstReportPage extends StatelessWidget {
  final List<SavedBill> bills;
  final List<Purchase> purchases;
  const GstReportPage({super.key, required this.bills, required this.purchases});

  @override
  Widget build(BuildContext context) {
    final output = bills.fold<double>(0, (s, b) => s + b.gst);
    final outputCgst = bills.fold<double>(0, (s, b) => s + b.cgst);
    final outputSgst = bills.fold<double>(0, (s, b) => s + b.sgst);
    final outputIgst = bills.fold<double>(0, (s, b) => s + b.igst);
    final input = purchases.fold<double>(0, (s, p) => s + p.cgst + p.sgst + p.igst);
    final inputCgst = purchases.fold<double>(0, (s, p) => s + p.cgst);
    final inputSgst = purchases.fold<double>(0, (s, p) => s + p.sgst);
    final inputIgst = purchases.fold<double>(0, (s, p) => s + p.igst);
    return Scaffold(appBar: AppBar(title: const Text('GST Report')), body: ListView(padding: const EdgeInsets.all(14), children: [
      Card(child: ListTile(title: const Text('Output GST — Sales'), subtitle: Text('CGST ₹${outputCgst.toStringAsFixed(2)}\nSGST ₹${outputSgst.toStringAsFixed(2)}\nIGST ₹${outputIgst.toStringAsFixed(2)}'), trailing: Text('₹${output.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)))),
      Card(child: ListTile(title: const Text('Input GST — Purchases'), subtitle: Text('CGST ₹${inputCgst.toStringAsFixed(2)}\nSGST ₹${inputSgst.toStringAsFixed(2)}\nIGST ₹${inputIgst.toStringAsFixed(2)}'), trailing: Text('₹${input.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)))),
      Card(color: Theme.of(context).colorScheme.primaryContainer, child: ListTile(title: const Text('Net GST Payable / Credit', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(output - input >= 0 ? 'Payable after input tax credit' : 'Input tax credit available'), trailing: Text('₹${(output - input).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)))),
      const SizedBox(height: 8),
      const Text('Note: This is a management report. GST returns, e-invoice and e-way bill filing should be verified with your tax professional/GST portal before submission.', style: TextStyle(color: Colors.grey)),
    ]));
  }
}

class BillingPage extends StatefulWidget {
  final List<Product> products;
  final GstSettings gstSettings;

  const BillingPage({super.key, required this.products, required this.gstSettings});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final customerName = TextEditingController();
  final customerMobile = TextEditingController();
  final customerGstin = TextEditingController();
  final discountController = TextEditingController(text: '0');
  final List<BillItem> items = [];

  double get subtotal => items.fold(0, (sum, item) => sum + item.amount);

  double get discount {
    final value = double.tryParse(discountController.text) ?? 0;
    return value.clamp(0, subtotal).toDouble();
  }

  double get taxable => (subtotal - discount).clamp(0, double.infinity);
  double get gst => items.fold(0, (sum, item) => item.gstAmount) * (subtotal == 0 ? 0 : taxable / subtotal);
  double get cgst => widget.gstSettings.interState ? 0 : gst / 2;
  double get sgst => widget.gstSettings.interState ? 0 : gst / 2;
  double get igst => widget.gstSettings.interState ? gst : 0;
  double get total => taxable + gst;

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
    String selectedUnit = available.first.alternateUnit.isEmpty ? available.first.unit : available.first.alternateUnit;

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
              DropdownButtonFormField<String>(
                value: selectedUnit,
                decoration: const InputDecoration(labelText: 'Sale Unit', border: OutlineInputBorder()),
                items: [selected.unit, if (selected.alternateUnit.isNotEmpty) selected.alternateUnit].toSet().map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setDialogState(() => selectedUnit = v ?? selected.unit),
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
                final qty = double.tryParse(qtyController.text) ?? 0;
                final stockQty = selectedUnit == selected.unit ? qty * selected.conversion : qty;
                if (qty <= 0 || stockQty > selected.stock) {
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
                    rate: selectedUnit == selected.unit ? selected.price : selected.price / selected.conversion,
                    unit: selectedUnit,
                    stockQuantity: stockQty,
                    hsn: selected.hsn,
                    gstRate: selected.gstRate,
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
        if (items[existingIndex].stockQuantity + result.stockQuantity > product.stock) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Total quantity stock se zyada hai.')),
          );
          return;
        }
        items[existingIndex] = BillItem(
          productName: result.productName,
          quantity: newQty,
          rate: result.rate,
          hsn: result.hsn,
          gstRate: result.gstRate,
          unit: result.unit,
          stockQuantity: items[existingIndex].stockQuantity + result.stockQuantity,
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
      if (item.stockQuantity > product.stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} ka stock kam hai.')),
        );
        return;
      }
    }

    for (final item in items) {
      final product =
          widget.products.firstWhere((p) => p.name == item.productName);
      product.stock -= item.stockQuantity.round();
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
      customerGstin: customerGstin.text.trim().toUpperCase(),
      subtotal: subtotal,
      discount: discount,
      taxable: taxable,
      cgst: cgst,
      sgst: sgst,
      igst: igst,
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
    customerGstin.dispose();
    discountController.dispose();
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
          const SizedBox(height: 10),
          TextField(controller: customerGstin, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Customer GSTIN (optional)', prefixIcon: Icon(Icons.badge_outlined), border: OutlineInputBorder())),
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
                        '${entry.value.quantity.toStringAsFixed(entry.value.quantity % 1 == 0 ? 0 : 2)} ${entry.value.unit} × ₹${entry.value.rate.toStringAsFixed(2)}',
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
              Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(widget.gstSettings.interState ? 'IGST Mode' : 'CGST + SGST Mode', style: const TextStyle(fontWeight: FontWeight.bold))))),
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
                  summaryRow('Taxable Value', taxable),
                  if (!widget.gstSettings.interState) ...[summaryRow('CGST', cgst), summaryRow('SGST', sgst)] else summaryRow('IGST', igst),
                  summaryRow('Total GST', gst),
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
