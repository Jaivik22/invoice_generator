import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';

void main() {
  runApp(const InvoiceGeneratorApp());
}

class InvoiceGeneratorApp extends StatelessWidget {
  const InvoiceGeneratorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
      home: const InvoiceHomePage(),
    );
  }
}

class InvoiceHomePage extends StatefulWidget {
  const InvoiceHomePage({Key? key}) : super(key: key);

  @override
  _InvoiceHomePageState createState() => _InvoiceHomePageState();
}

class _InvoiceHomePageState extends State<InvoiceHomePage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedColor = 'Blue';
  String _selectedLayout = 'Professional';
  File? _logoFile;
  final ImagePicker _picker = ImagePicker();

  final Map<String, Color> _colorOptions = {
    'Blue': Colors.blue,
    'Green': Colors.green,
    'Purple': Colors.purple,
    'Red': Colors.red,
  };
  final List<String> _layoutOptions = [
    'Professional',
    'Modern',
    'Minimal',
    'Elegant',
    'Compact'
  ];

  // User info fields
  String _businessName = '';
  String _businessAddress = '';
  String _clientName = '';
  String _clientEmail = '';
  List<Map<String, dynamic>> _items = [
    {'description': '', 'quantity': 0, 'price': 0.0},
  ];

  // TextEditingControllers for form fields
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessAddressController =
      TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientEmailController = TextEditingController();
  List<Map<String, TextEditingController>> _itemControllers = [];

  @override
  void initState() {
    super.initState();
    // Initialize item controllers for the default item
    _itemControllers.add({
      'description': TextEditingController(),
      'quantity': TextEditingController(),
      'price': TextEditingController(),
    });
    // _loadSavedInfo();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _clientNameController.dispose();
    _clientEmailController.dispose();
    for (var controllerMap in _itemControllers) {
      controllerMap['description']?.dispose();
      controllerMap['quantity']?.dispose();
      controllerMap['price']?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSavedInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _businessName = prefs.getString('businessName') ?? '';
      _businessAddress = prefs.getString('businessAddress') ?? '';
      _clientName = prefs.getString('clientName') ?? '';
      _clientEmail = prefs.getString('clientEmail') ?? '';
      _logoFile =
          prefs.getString('logoPath') != null &&
                  File(prefs.getString('logoPath')!).existsSync()
              ? File(prefs.getString('logoPath')!)
              : null;

      // Update TextEditingControllers
      _businessNameController.text = _businessName;
      _businessAddressController.text = _businessAddress;
      _clientNameController.text = _clientName;
      _clientEmailController.text = _clientEmail;
    });
  }

  Future<void> _saveInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('businessName', _businessName);
    await prefs.setString('businessAddress', _businessAddress);
    await prefs.setString('clientName', _clientName);
    await prefs.setString('clientEmail', _clientEmail);
    if (_logoFile != null) {
      await prefs.setString('logoPath', _logoFile!.path);
    }
  }

  Future<void> _pickLogo() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }

  // Future<void> _generatePDF() async {
  //   final pdf = pw.Document();
  //   final themeColor = _colorOptions[_selectedColor]!;
  //   pw.MemoryImage? logoImage;
  //   if (_logoFile != null && _logoFile!.existsSync()) {
  //     logoImage = pw.MemoryImage(_logoFile!.readAsBytesSync());
  //   }
  //
  //   pdf.addPage(
  //     pw.Page(
  //       build: (pw.Context context) {
  //         switch (_selectedLayout) {
  //           case 'Modern':
  //             return _buildModernLayout(themeColor, logoImage);
  //           case 'Minimal':
  //             return _buildMinimalLayout(themeColor, logoImage);
  //           default:
  //             return _buildProfessionalLayout(themeColor, logoImage);
  //         }
  //       },
  //     ),
  //   );

  //   final output = await getTemporaryDirectory();
  //   final file = File(
  //     '${output.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf',
  //   );
  //   await file.writeAsBytes(await pdf.save());
  //   await OpenFile.open(file.path);
  // }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    final themeColor = _colorOptions[_selectedColor]!;
    pw.MemoryImage? logoImage;
    if (_logoFile != null && _logoFile!.existsSync()) {
      logoImage = pw.MemoryImage(_logoFile!.readAsBytesSync());
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          switch (_selectedLayout) {
            case 'Modern':
              return _buildModernLayout(themeColor, logoImage);
            case 'Minimal':
              return _buildMinimalLayout(themeColor, logoImage);
            case 'Elegant':
              return _buildElegantLayout(themeColor, logoImage);
            case 'Compact':
              return _buildCompactLayout(themeColor, logoImage);
            default:
              return _buildProfessionalLayout(themeColor, logoImage);
          }
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  pw.Widget _buildElegantLayout(Color themeColor, pw.MemoryImage? logoImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            logoImage != null
                ? pw.Image(logoImage, width: 120, height: 120)
                : pw.SizedBox(width: 120, height: 120),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 30,
                    color: PdfColor.fromInt(themeColor.value),
                    fontWeight: pw.FontWeight.bold,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
                pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}'),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 30),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(themeColor.value), width: 2)),
          ),
          child: pw.Text(
            _businessName,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(_businessAddress),
        pw.SizedBox(height: 20),
        pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(_clientName),
        pw.Text(_clientEmail),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          headers: ['Description', 'Qty', 'Price', 'Total'],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(themeColor.value)),
          cellStyle: const pw.TextStyle(fontSize: 12),
          data: _items
              .map((item) => [
            item['description'],
            item['quantity'].toString(),
            '\$${item['price'].toStringAsFixed(2)}',
            '\$${(item['quantity'] * item['price']).toStringAsFixed(2)}'
          ])
              .toList(),
        ),
        pw.SizedBox(height: 20),
        pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Total: \$${calculateTotal().toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCompactLayout(Color themeColor, pw.MemoryImage? logoImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            logoImage != null
                ? pw.Image(logoImage, width: 60, height: 60)
                : pw.SizedBox(width: 60, height: 60),
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 20,
                color: PdfColor.fromInt(themeColor.value),
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(_businessName, style: const pw.TextStyle(fontSize: 14)),
            pw.Text(_clientName, style: const pw.TextStyle(fontSize: 14)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          headers: ['Item', 'Total'],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(themeColor.value)),
          cellStyle: const pw.TextStyle(fontSize: 10),
          data: _items
              .map((item) => [
            item['description'],
            '\$${(item['quantity'] * item['price']).toStringAsFixed(2)}'
          ])
              .toList(),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Total: \$${calculateTotal().toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }
//sdfnasfa
  pw.Widget _buildProfessionalLayout(
    Color themeColor,
    pw.MemoryImage? logoImage,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            logoImage != null
                ? pw.Image(logoImage, width: 100, height: 100)
                : pw.SizedBox(width: 100, height: 100),
            pw.Container(
              color: PdfColor.fromInt(themeColor.value),
              padding: const pw.EdgeInsets.all(16),
              child: pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 24,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          _businessName,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(_businessAddress),
        pw.SizedBox(height: 20),
        pw.Text(
          'Bill To:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(_clientName),
        pw.Text(_clientEmail),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          headers: ['Description', 'Quantity', 'Price', 'Total'],
          data:
              _items
                  .map(
                    (item) => [
                      item['description'],
                      item['quantity'].toString(),
                      '\$${item['price'].toStringAsFixed(2)}',
                      '\$${(item['quantity'] * item['price']).toStringAsFixed(2)}',
                    ],
                  )
                  .toList(),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Total: \$${calculateTotal().toStringAsFixed(2)}',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildModernLayout(Color themeColor, pw.MemoryImage? logoImage) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            logoImage != null
                ? pw.Image(logoImage, width: 80, height: 80)
                : pw.SizedBox(width: 80, height: 80),
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 28,
                color: PdfColor.fromInt(themeColor.value),
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 30),
        pw.Divider(color: PdfColor.fromInt(themeColor.value)),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'From:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(_businessName),
                pw.Text(_businessAddress),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'To:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(_clientName),
                pw.Text(_clientEmail),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          headers: ['Item', 'Qty', 'Price', 'Total'],
          data:
              _items
                  .map(
                    (item) => [
                      item['description'],
                      item['quantity'].toString(),
                      '\$${item['price'].toStringAsFixed(2)}',
                      '\$${(item['quantity'] * item['price']).toStringAsFixed(2)}',
                    ],
                  )
                  .toList(),
        ),
        pw.SizedBox(height: 20),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Total: \$${calculateTotal().toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildMinimalLayout(Color themeColor, pw.MemoryImage? logoImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            logoImage != null
                ? pw.Image(logoImage, width: 60, height: 60)
                : pw.SizedBox(width: 60, height: 60),
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 20,
                color: PdfColor.fromInt(themeColor.value),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(_businessName),
        pw.Text(_clientName),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          headers: ['Description', 'Total'],
          data:
              _items
                  .map(
                    (item) => [
                      item['description'],
                      '\$${(item['quantity'] * item['price']).toStringAsFixed(2)}',
                    ],
                  )
                  .toList(),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Total: \$${calculateTotal().toStringAsFixed(2)}',
          style: pw.TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  double calculateTotal() {
    return _items.fold(
      0,
      (sum, item) => sum + (item['quantity'] * item['price']),
    );
  }

  void _addItem() {
    setState(() {
      _items.add({'description': '', 'quantity': 0, 'price': 0.0});
      _itemControllers.add({
        'description': TextEditingController(),
        'quantity': TextEditingController(),
        'price': TextEditingController(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Generator'),
        backgroundColor: _colorOptions[_selectedColor],
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _saveInfo();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Information saved')),
                      );
                    }
                  },
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loadSavedInfo,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Load'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _generatePDF();
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Generate'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme and Layout Selection
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preferences',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedColor,
                          decoration: const InputDecoration(
                            labelText: 'Color Theme',
                            prefixIcon: Icon(Icons.color_lens),
                          ),
                          items: _colorOptions.keys
                              .map((color) => DropdownMenuItem(
                            value: color,
                            child: Text(color),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedColor = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedLayout,
                          decoration: const InputDecoration(
                            labelText: 'Layout Style',
                            prefixIcon: Icon(Icons.grid_view),
                          ),
                          items: _layoutOptions
                              .map((layout) => DropdownMenuItem(
                            value: layout,
                            child: Text(layout),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedLayout = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Logo Upload
              const SizedBox(height: 16),
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Logo',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _logoFile != null && _logoFile!.existsSync()
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(_logoFile!, height: 80, fit: BoxFit.contain),
                              )
                                  : Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(child: Text('No logo selected')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _pickLogo,
                              icon: const Icon(Icons.upload, size: 18),
                              label: const Text('Upload'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Business Info
              const SizedBox(height: 16),
              FadeInDown(
                duration: const Duration(milliseconds: 700),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Information',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _businessNameController,
                          decoration: const InputDecoration(
                            labelText: 'Business Name',
                            prefixIcon: Icon(Icons.business),
                          ),
                          onChanged: (value) => _businessName = value,
                          validator: (value) => value!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _businessAddressController,
                          decoration: const InputDecoration(
                            labelText: 'Business Address',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          onChanged: (value) => _businessAddress = value,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Client Info
              const SizedBox(height: 16),
              FadeInDown(
                duration: const Duration(milliseconds: 800),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Client Information',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _clientNameController,
                          decoration: const InputDecoration(
                            labelText: 'Client Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                          onChanged: (value) => _clientName = value,
                          validator: (value) => value!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _clientEmailController,
                          decoration: const InputDecoration(
                            labelText: 'Client Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          onChanged: (value) => _clientEmail = value,
                          validator: (value) => value!.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Items
              const SizedBox(height: 16),
              FadeInDown(
                duration: const Duration(milliseconds: 900),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Items',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._items.asMap().entries.map((entry) {
                          int index = entry.key;
                          return Column(
                            children: [
                              TextFormField(
                                controller: _itemControllers[index]['description'],
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                  prefixIcon: Icon(Icons.description),
                                ),
                                onChanged: (value) =>
                                _items[index]['description'] = value,
                                validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _itemControllers[index]['quantity'],
                                      decoration: const InputDecoration(
                                        labelText: 'Quantity',
                                        prefixIcon: Icon(Icons.numbers),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) => _items[index]
                                      ['quantity'] =
                                          int.tryParse(value) ?? 0,
                                      validator: (value) =>
                                      value!.isEmpty ? 'Required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _itemControllers[index]['price'],
                                      decoration: const InputDecoration(
                                        labelText: 'Price',
                                        prefixIcon: Icon(Icons.attach_money),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) => _items[index]['price'] =
                                          double.tryParse(value) ?? 0.0,
                                      validator: (value) =>
                                      value!.isEmpty ? 'Required' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          );
                        }),
                        TextButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2C3E50)),
                          label: Text(
                            'Add Item',
                            style: GoogleFonts.poppins(color: const Color(0xFF2C3E50)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
