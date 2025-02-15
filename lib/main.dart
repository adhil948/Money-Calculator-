import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('paymentBox'); // Open a box for storing data

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Payment Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto', // Beautiful font family
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Rounded corners
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            textStyle: TextStyle(fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // Rounded borders
            borderSide: BorderSide(color: Colors.blue, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.blue),
        ),
      ),
      home: NameEntryScreen(),
    );
  }
}

class NameEntryScreen extends StatefulWidget {
  @override
  _NameEntryScreenState createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final Box paymentBox = Hive.box('paymentBox'); // Reference to the Hive box

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _totalAmountController.text =
        paymentBox.get('totalAmount', defaultValue: 0.0).toString();
  }

  void addName() {
    String name = _nameController.text.trim();
    if (name.isNotEmpty) {
      List<String> names =
          List<String>.from(paymentBox.get('names', defaultValue: []));
      Map<String, double> payments = Map<String, double>.from(
          paymentBox.get('payments', defaultValue: {}));

      names.add(name);
      payments[name] = 0.0; // Initialize payment for the new name

      paymentBox.put('names', names); // Save names to Hive
      paymentBox.put('payments', payments); // Save payments to Hive

      setState(() {}); // Refresh the UI
      _nameController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Name cannot be empty")),
      );
    }
  }

  void saveTotalAmount() {
    double amount = double.tryParse(_totalAmountController.text) ?? 0.0;
    if (amount > 0) {
      paymentBox.put('totalAmount', amount); // Save total payment to Hive
      setState(() {}); // Refresh the UI
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid total payment amount")),
      );
    }
  }

  void deleteName(String name) {
    List<String> names =
        List<String>.from(paymentBox.get('names', defaultValue: []));
    Map<String, double> payments =
        Map<String, double>.from(paymentBox.get('payments', defaultValue: {}));

    names.remove(name); // Remove the name
    payments.remove(name); // Remove associated payment data

    paymentBox.put('names', names); // Save updated names
    paymentBox.put('payments', payments); // Save updated payments

    setState(() {}); // Refresh the UI
  }

  void proceedToNextScreen() {
    List<String> names =
        List<String>.from(paymentBox.get('names', defaultValue: []));
    double totalAmount = paymentBox.get('totalAmount', defaultValue: 0.0);

    if (names.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please add at least one name")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EnterDataScreen(names: names, totalAmount: totalAmount),
      ),
    ).then((_) {
      setState(() {}); // Refresh data when returning to this screen
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Names and Total Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _totalAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Total Payment',
                prefixIcon: Icon(Icons.money),
              ),
              onSubmitted: (_) => saveTotalAmount(),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Enter Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: addName,
              child: Text('Add Name'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: paymentBox.listenable(),
                builder: (context, box, _) {
                  List<String> names =
                      List<String>.from(box.get('names', defaultValue: []));
                  Map<String, double> payments = Map<String, double>.from(
                      box.get('payments', defaultValue: {}));
                  double totalAmount =
                      box.get('totalAmount', defaultValue: 0.0);

                  return ListView.builder(
                    itemCount: names.length,
                    itemBuilder: (context, index) {
                      String name = names[index];
                      double paidAmount = payments[name] ?? 0.0;
                      double remainingAmount = totalAmount - paidAmount;

                      return Card(
                        elevation: 5,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(
                            name,
                            style: TextStyle(fontSize: 18),
                          ),
                          subtitle: Text(
                            'Paid: ₹${paidAmount.toStringAsFixed(2)}, Remaining: ₹${remainingAmount.toStringAsFixed(2)}',
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteName(name),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: proceedToNextScreen,
              child: Text('Enter payments'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailsScreen(),
                  ),
                );
              },
              child: Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }
}

class EnterDataScreen extends StatefulWidget {
  final List<String> names;
  final double totalAmount;

  EnterDataScreen({required this.names, required this.totalAmount});

  @override
  _EnterDataScreenState createState() => _EnterDataScreenState();
}

class _EnterDataScreenState extends State<EnterDataScreen> {
  final _paymentController = TextEditingController();
  final Box paymentBox = Hive.box('paymentBox');
  String? selectedName;
  bool isAddingPayment = true;
  Map<String, double> payments = {};

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  void _loadPayments() {
    setState(() {
      payments = Map<String, double>.from(
          paymentBox.get('payments', defaultValue: {}));
    });
  }

  void addOrSubtractPayment() {
    if (selectedName == null || selectedName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a name first")),
      );
      return;
    }

    double payment = double.tryParse(_paymentController.text) ?? 0.0;

    if (payment <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter a valid payment amount")),
      );
      return;
    }

    setState(() {
      if (isAddingPayment) {
        payments[selectedName!] = (payments[selectedName!] ?? 0.0) + payment;
      } else {
        payments[selectedName!] = (payments[selectedName!] ?? 0.0) - payment;
      }

      // Save payments to Hive
      paymentBox.put('payments', payments);
    });

    _paymentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Payments'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Total Amount: ₹${widget.totalAmount}'),
            DropdownButton<String>(
              hint: Text('Select a name'),
              value: selectedName,
              items: widget.names
                  .map((name) => DropdownMenuItem(
                        value: name,
                        child: Text(name),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedName = value;
                });
              },
            ),
            TextField(
              controller: _paymentController,
              decoration: InputDecoration(
                labelText: 'Enter Payment',
                prefixIcon: Icon(Icons.money),
              ),
              keyboardType: TextInputType.number,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isAddingPayment = true;
                    });
                    addOrSubtractPayment();
                  },
                  child: Text('Add Payment'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isAddingPayment = false;
                    });
                    addOrSubtractPayment();
                  },
                  child: Text('Subtract Payment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ValueListenableBuilder(
          valueListenable: Hive.box('paymentBox').listenable(),
          builder: (context, box, _) {
            List<String> names =
                List<String>.from(box.get('names', defaultValue: []));
            double totalPaymentPerPerson =
                box.get('totalAmount', defaultValue: 0.0);
            Map<String, double> payments = box.get('payments', defaultValue: {});

            // Total Amount Needed is the product of totalPaymentPerPerson and number of people
            double totalAmountNeeded = totalPaymentPerPerson * names.length;

            // Total Amount Got is the sum of all individual payments
            double totalAmountGot = payments.values.fold(0.0, (sum, value) => sum + value);

            // Calculate the remaining amount
            double totalRemaining = totalAmountNeeded - totalAmountGot;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display the total amount needed
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Total Amount Needed: ₹${totalAmountNeeded.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                // Display the total amount got
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Total Amount Got: ₹${totalAmountGot.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                // Display the total remaining
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Total Remaining: ₹${totalRemaining.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                // Display the list of names and payments
                Expanded(
                  child: ListView.builder(
                    itemCount: names.length,
                    itemBuilder: (context, index) {
                      String name = names[index];

                      return Card(
                        elevation: 5,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(
                            name,
                            style: TextStyle(fontSize: 18),
                          ),
                          subtitle: Text(
                            'Amount Paid: ₹${payments[name]?.toStringAsFixed(2) ?? 0.0}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
