import 'package:flutter/material.dart';

void main() => runApp(const CallAPK());

class CallAPK extends StatelessWidget {
  const CallAPK({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CallAPK',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const CallHomePage(),
    );
  }
}

class Client {
  String name, mobile, work, place, charges, parts, remark, status;
  DateTime callDate;
  DateTime? closeDate;

  Client({
    required this.name,
    required this.mobile,
    required this.work,
    required this.place,
    required this.charges,
    required this.parts,
    required this.remark,
    required this.status,
    required this.callDate,
    this.closeDate,
  });
}

class CallHomePage extends StatefulWidget {
  const CallHomePage({super.key});

  @override
  State<CallHomePage> createState() => _CallHomePageState();
}

class _CallHomePageState extends State<CallHomePage> {
  final List<Client> clients = [];
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    final visible = clients.where((c) {
      return filter == 'All' || c.status == filter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CallAPK'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => filter = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'All', child: Text('All Calls')),
              PopupMenuItem(value: 'Open', child: Text('Open')),
              PopupMenuItem(value: 'Pending', child: Text('Pending')),
              PopupMenuItem(value: 'Closed', child: Text('Closed')),
            ],
          ),
        ],
      ),
      body: visible.isEmpty
          ? const Center(
              child: Text(
                'Abhi koi call nahi hai.\nNiche + Client Add button dabayein.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: visible.length,
              itemBuilder: (_, i) => _callCard(visible[i]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addClient,
        icon: const Icon(Icons.person_add),
        label: const Text('Client Add'),
      ),
    );
  }

  Widget _callCard(Client c) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(c.name.isEmpty ? '?' : c.name[0])),
        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${c.mobile}\n${c.work}\n${c.place}'),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Chip(label: Text(c.status)),
            Text('₹${c.charges}'),
          ],
        ),
        onTap: () => _editCall(c),
      ),
    );
  }

  Future<void> _addClient() async {
    final result = await _clientForm();
    if (result != null) setState(() => clients.insert(0, result));
  }

  Future<void> _editCall(Client c) async {
    final result = await _clientForm(existing: c);
    if (result != null) setState(() {});
  }

  Future<Client?> _clientForm({Client? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final mobile = TextEditingController(text: existing?.mobile ?? '');
    final work = TextEditingController(text: existing?.work ?? '');
    final place = TextEditingController(text: existing?.place ?? '');
    final charges = TextEditingController(text: existing?.charges ?? '');
    final parts = TextEditingController(text: existing?.parts ?? '');
    final remark = TextEditingController(text: existing?.remark ?? '');
    String status = existing?.status ?? 'Open';

    return showDialog<Client>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(existing == null ? 'Add Client / New Call' : 'Edit Call'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(name, 'Client Name'),
                _field(mobile, 'Mobile No.', TextInputType.phone),
                _field(work, 'Kaam / Complaint'),
                _field(place, 'Place / Address'),
                _field(charges, 'Charges', TextInputType.number),
                _field(parts, 'Parts Details'),
                _field(remark, 'Remark / Extra Details'),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Call Status'),
                  items: const [
                    DropdownMenuItem(value: 'Open', child: Text('Open')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                  ],
                  onChanged: (v) => setDialog(() => status = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty || mobile.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Client Name aur Mobile No. zaruri hai')),
                  );
                  return;
                }
                final now = DateTime.now();
                if (existing != null) {
                  existing
                    ..name = name.text.trim()
                    ..mobile = mobile.text.trim()
                    ..work = work.text.trim()
                    ..place = place.text.trim()
                    ..charges = charges.text.trim()
                    ..parts = parts.text.trim()
                    ..remark = remark.text.trim()
                    ..status = status
                    ..closeDate = status == 'Closed' ? (existing.closeDate ?? now) : null;
                  Navigator.pop(context, existing);
                } else {
                  Navigator.pop(
                    context,
                    Client(
                      name: name.text.trim(),
                      mobile: mobile.text.trim(),
                      work: work.text.trim(),
                      place: place.text.trim(),
                      charges: charges.text.trim(),
                      parts: parts.text.trim(),
                      remark: remark.text.trim(),
                      status: status,
                      callDate: now,
                      closeDate: status == 'Closed' ? now : null,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, [
    TextInputType type = TextInputType.text,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}
