import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data' show Uint8List;

import '../model/invoice_info.dart';
import 'home_page.dart';

void main() {
  runApp(const InvoiceGeneratorApp());
}

/// define the observer
final RouteObserver<ModalRoute<void>> routeObserver =
RouteObserver<ModalRoute<void>>();

class InvoiceGeneratorApp extends StatelessWidget {
  const InvoiceGeneratorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      navigatorObservers: [routeObserver],
      home: const HomePage(),
    );
  }
}

class InvoiceHomePage extends StatefulWidget {
  final String? invoiceKey; // Add invoiceKey parameter
  const InvoiceHomePage({super.key, this.invoiceKey});

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
    'Compact',
  ];

  // User info fields
  // Existing state variables...
  String _businessName = '';
  String _businessAddress = '';

  // String _clientName = '';
  String _clientEmail = '';
  List<Map<String, dynamic>> _items = [
    {'description': '', 'quantity': 0, 'price': 0.0},
  ];

  String _selectedCurrency = '\$'; // Default to USD
  final Map<String, String> _currencyOptions = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
    'JPY': '¥',
  };

  // New state variables
  String _yourName = '';
  String _companyCityStateZip = '';
  String _companyCountry = '';
  String _clientCompany = '';

  // String _clientAddress = '';
  String _clientCityStateZip = '';
  String _clientCountry = '';
  String _invoiceNumber = '';
  String _invoiceDate =
      DateTime.now().toString().split(' ')[0]; // Default to today (2025-07-03)
  String _dueDate = DateTime.now().toString().split(' ')[0]; // Default to today
  double _taxPercentage = 0.0; // Add this line
  final _taxController = TextEditingController(); // Add this line
  String keyName = '';

  // Existing controllers...
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessAddressController =
      TextEditingController();

  // final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientEmailController = TextEditingController();

  // New controllers
  final TextEditingController _yourNameController = TextEditingController();
  final TextEditingController _companyCityStateZipController =
      TextEditingController();
  final TextEditingController _companyCountryController =
      TextEditingController();
  final TextEditingController _clientCompanyController =
      TextEditingController();
  final TextEditingController _clientCityStateZipController =
      TextEditingController();
  final TextEditingController _clientCountryController =
      TextEditingController();
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final TextEditingController _invoiceDateController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
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
    // Initialize date controllers with default values
    _invoiceDateController.text = _invoiceDate;
    _dueDateController.text = _dueDate;

    if (widget.invoiceKey != null && widget.invoiceKey!.isNotEmpty) {
      _loadSavedInfo();
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    // _clientNameController.dispose();
    _clientEmailController.dispose();
    _yourNameController.dispose();
    _companyCityStateZipController.dispose();
    _companyCountryController.dispose();
    _clientCompanyController.dispose();
    _clientCityStateZipController.dispose();
    _clientCountryController.dispose();
    _invoiceNumberController.dispose();
    _invoiceDateController.dispose();
    _dueDateController.dispose();
    for (var controllerMap in _itemControllers) {
      controllerMap['description']?.dispose();
      controllerMap['quantity']?.dispose();
      controllerMap['price']?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSavedInfo() async {
    final loaded = loadInvoice();

    if (loaded != null) {
      _businessName = loaded.businessName;
      _businessAddress = loaded.businessAddress;
      _clientEmail = loaded.clientEmail;
      _yourName = loaded.yourName;
      _companyCityStateZip = loaded.clientCityStateZip;
      _companyCountry = loaded.companyCountry;
      _clientCompany = loaded.clientCompany;
      _clientCityStateZip = loaded.clientCityStateZip;
      _clientCountry = loaded.clientCountry;
      _invoiceNumber = loaded.invoiceNumber;
      _invoiceDate = loaded.invoiceDate;
      _dueDate = loaded.dueDate;
      _selectedCurrency = loaded.currency ?? '\$'; // Load currency
      _logoFile =
          loaded.logoPath != null && File(loaded.logoPath!).existsSync()
              ? File(loaded.logoPath!)
              : null;

      _taxPercentage = loaded.taxPercentage ?? 0.0;
      _taxController.text = _taxPercentage.toString();
    }

    setState(() {
      // Update TextEditingControllers
      _businessNameController.text = _businessName;
      _businessAddressController.text = _businessAddress;
      _clientEmailController.text = _clientEmail;
      _yourNameController.text = _yourName;
      _companyCityStateZipController.text = _companyCityStateZip;
      _companyCountryController.text = _companyCountry;
      _clientCompanyController.text = _clientCompany;
      _clientCityStateZipController.text = _clientCityStateZip;
      _clientCountryController.text = _clientCountry;
      _invoiceNumberController.text = _invoiceNumber;
      _invoiceDateController.text = _invoiceDate;
      _dueDateController.text = _dueDate;
    });
  }

  Future<void> _saveInfo(String keyName) async {
    final invoice = InvoiceInfo(
      businessName: _businessName,
      businessAddress: _businessAddress,
      clientEmail: _clientEmail,
      yourName: _yourName,
      companyCityStateZip: _companyCityStateZip,
      companyCountry: _companyCountry,
      clientCompany: _clientCompany,
      clientCityStateZip: _clientCityStateZip,
      clientCountry: _clientCountry,
      invoiceNumber: _invoiceNumber,
      invoiceDate: _invoiceDate,
      dueDate: _dueDate,
      currency: _selectedCurrency,
      taxPercentage: _taxPercentage,
      logoPath: _logoFile != null ? _logoFile!.path : "",
    );

    await saveInvoice(invoice,keyName);
  }

  Future<void> _pickLogo() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> saveInvoice(InvoiceInfo info,String keyName) async {
    final box = Hive.box<InvoiceInfo>('invoiceBox');
    await box.put(keyName, info); // single record
  }

  InvoiceInfo? loadInvoice() {
    final box = Hive.box<InvoiceInfo>('invoiceBox');
    return box.get(widget.invoiceKey);
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    final themeColor = _colorOptions[_selectedColor]!;
    pw.MemoryImage? logoImage;
    if (_logoFile != null && _logoFile!.existsSync()) {
      logoImage = pw.MemoryImage(_logoFile!.readAsBytesSync());
    }

    // Load Roboto font
    final fontData = await DefaultAssetBundle.of(
      context,
    ).load('assets/fonts/Roboto-Regular.ttf');
    final robotoFont = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          switch (_selectedLayout) {
            case 'Modern':
              return _buildModernLayout(themeColor, logoImage, robotoFont);
            case 'Minimal':
              return _buildMinimalLayout(themeColor, logoImage, robotoFont);
            case 'Elegant':
              return _buildElegantLayout(themeColor, logoImage, robotoFont);
            case 'Compact':
              return _buildCompactLayout(themeColor, logoImage, robotoFont);
            default:
              return _buildProfessionalLayout(
                themeColor,
                logoImage,
                robotoFont,
              );
          }
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  Future<void> _generateAndSharePdf() async {
    final pdf = pw.Document();
    final themeColor = _colorOptions[_selectedColor]!;
    pw.MemoryImage? logoImage;
    if (_logoFile != null && _logoFile!.existsSync()) {
      logoImage = pw.MemoryImage(_logoFile!.readAsBytesSync());
    }

    // Load Roboto font
    final fontData = await DefaultAssetBundle.of(
      context,
    ).load('assets/fonts/Roboto-Regular.ttf');
    final robotoFont = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          switch (_selectedLayout) {
            case 'Modern':
              return _buildModernLayout(themeColor, logoImage, robotoFont);
            case 'Minimal':
              return _buildMinimalLayout(themeColor, logoImage, robotoFont);
            case 'Elegant':
              return _buildElegantLayout(themeColor, logoImage, robotoFont);
            case 'Compact':
              return _buildCompactLayout(themeColor, logoImage, robotoFont);
            default:
              return _buildProfessionalLayout(
                themeColor,
                logoImage,
                robotoFont,
              );
          }
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    // Share the PDF
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: 'Invoice #$_invoiceNumber',
      subject: 'Invoice from $_businessName',
    );
  }

  pw.Widget _buildProfessionalLayout(
    Color themeColor,
    pw.MemoryImage? logoImage,
    pw.Font robotoFont,
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
            pw.Column(
              children: [
                pw.Container(
                  color: PdfColor.fromInt(themeColor.value),
                  padding: const pw.EdgeInsets.all(16),
                  child: pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 24,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      font: robotoFont,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Invoice #$_invoiceNumber',
                  style: pw.TextStyle(fontSize: 14, font: robotoFont),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'From:',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            font: robotoFont,
          ),
        ),
        pw.Text(_businessName, style: pw.TextStyle(font: robotoFont)),
        pw.Text(_yourName, style: pw.TextStyle(font: robotoFont)),
        pw.Text(_businessAddress, style: pw.TextStyle(font: robotoFont)),
        pw.Text(_companyCityStateZip, style: pw.TextStyle(font: robotoFont)),
        pw.Text(_companyCountry, style: pw.TextStyle(font: robotoFont)),
        pw.SizedBox(height: 20),
        pw.Text(
          'Bill to:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: robotoFont),
        ),
        pw.Text(_clientCompany, style: pw.TextStyle(font: robotoFont)),
        pw.Text(_clientCityStateZip, style: pw.TextStyle(font: robotoFont)),
        pw.Text(_clientCountry, style: pw.TextStyle(font: robotoFont)),
        pw.Text(_clientEmail, style: pw.TextStyle(font: robotoFont)),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Invoice Date: $_invoiceDate',
              style: pw.TextStyle(font: robotoFont),
            ),
            pw.Text(
              'Due Date: $_dueDate',
              style: pw.TextStyle(font: robotoFont),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          headers: ['Description', 'Quantity', 'Price', 'Total'],
          headerStyle: pw.TextStyle(
            font: robotoFont,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: pw.TextStyle(font: robotoFont),
          data:
              _items
                  .map(
                    (item) => [
                      item['description'],
                      item['quantity'].toString(),
                      '$_selectedCurrency${item['price'].toStringAsFixed(2)}',
                      '$_selectedCurrency${(item['quantity'] * item['price']).toStringAsFixed(2)}',
                    ],
                  )
                  .toList(),
        ),
        pw.SizedBox(height: 20),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Subtotal: $_selectedCurrency${_items.fold<double>(0.0, (sum, item) => sum + item['quantity'] * item['price']).toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 14, font: robotoFont),
            ),
            pw.Text(
              'Tax (${_taxPercentage.toStringAsFixed(1)}%): $_selectedCurrency${(_items.fold<double>(0.0, (sum, item) => sum + item['quantity'] * item['price']) * (_taxPercentage / 100)).toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 14, font: robotoFont),
            ),
            pw.Text(
              'Total: $_selectedCurrency${calculateTotal().toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                font: robotoFont,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildModernLayout(
    Color themeColor,
    pw.MemoryImage? logoImage,
    pw.Font robotoFont,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            logoImage != null
                ? pw.Image(logoImage, width: 80, height: 80)
                : pw.SizedBox(width: 80, height: 80),
            pw.Column(
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 28,
                    color: PdfColor.fromInt(themeColor.value),
                    fontWeight: pw.FontWeight.bold,
                    font: robotoFont,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Invoice #$_invoiceNumber',
                  style: pw.TextStyle(fontSize: 14, font: robotoFont),
                ),
              ],
            ),
          ],
        ),
        // pw.SizedBox(height: 10),
        // pw.Text('Invoice #$_invoiceNumber', style: const pw.TextStyle(fontSize: 14)),
        pw.SizedBox(height: 20),
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
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    font: robotoFont,
                  ),
                ),
                pw.Text(_businessName, style: pw.TextStyle(font: robotoFont)),
                pw.Text(_yourName, style: pw.TextStyle(font: robotoFont)),
                pw.Text(
                  _businessAddress,
                  style: pw.TextStyle(font: robotoFont),
                ),
                pw.Text(
                  _companyCityStateZip,
                  style: pw.TextStyle(font: robotoFont),
                ),
                pw.Text(_companyCountry, style: pw.TextStyle(font: robotoFont)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Bill to:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    font: robotoFont,
                  ),
                ),
                pw.Text(_clientCompany, style: pw.TextStyle(font: robotoFont)),
                pw.Text(
                  _clientCityStateZip,
                  style: pw.TextStyle(font: robotoFont),
                ),
                pw.Text(_clientCountry, style: pw.TextStyle(font: robotoFont)),
                pw.Text(_clientEmail, style: pw.TextStyle(font: robotoFont)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Invoice Date: $_invoiceDate',
              style: pw.TextStyle(font: robotoFont),
            ),
            pw.Text(
              'Due Date: $_dueDate',
              style: pw.TextStyle(font: robotoFont),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          headers: ['Item', 'Qty', 'Price', 'Total'],
          headerStyle: pw.TextStyle(
            font: robotoFont,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: pw.TextStyle(font: robotoFont),
          data:
              _items
                  .map(
                    (item) => [
                      item['description'],
                      item['quantity'].toString(),
                      '$_selectedCurrency${item['price'].toStringAsFixed(2)}',
                      '$_selectedCurrency${(item['quantity'] * item['price']).toStringAsFixed(2)}',
                    ],
                  )
                  .toList(),
        ),
        pw.SizedBox(height: 20),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Subtotal: $_selectedCurrency${_items.fold<double>(0.0, (sum, item) => sum + item['quantity'] * item['price']).toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 14, font: robotoFont),
              ),
              pw.Text(
                'Tax (${_taxPercentage.toStringAsFixed(1)}%): $_selectedCurrency${(_items.fold<double>(0.0, (sum, item) => sum + item['quantity'] * item['price']) * (_taxPercentage / 100)).toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 14, font: robotoFont),
              ),
              pw.Text(
                'Total: $_selectedCurrency${calculateTotal().toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  font: robotoFont,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildMinimalLayout(
    Color themeColor,
    pw.MemoryImage? logoImage,
    pw.Font robotoFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            logoImage != null
                ? pw.Image(logoImage, width: 60, height: 60)
                : pw.SizedBox(width: 60, height: 60),
            pw.Column(
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 20,
                    color: PdfColor.fromInt(themeColor.value),
                    font: robotoFont,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Invoice #$_invoiceNumber',
                  style: pw.TextStyle(fontSize: 12, font: robotoFont),
                ),
              ],
            ),
          ],
        ),
        // pw.SizedBox(height: 10),
        // pw.Text('Invoice #$_invoiceNumber', style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 20),
        pw.Text(
          'From:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: robotoFont),
        ),
        pw.Text(_businessName, style: pw.TextStyle(font: robotoFont)),
        pw.Text(_yourName, style: pw.TextStyle(font: robotoFont)),
        pw.Text(_businessAddress, style: pw.TextStyle(font: robotoFont)),
        pw.Text(_companyCityStateZip, style: pw.TextStyle(font: robotoFont)),
        pw.Text(_companyCountry, style: pw.TextStyle(font: robotoFont)),
        pw.SizedBox(height: 10),
        pw.Text(
          'Bill to:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: robotoFont),
        ),
        pw.Text(_clientCompany, style: pw.TextStyle(font: robotoFont)),
        // pw.Text(_clientName),
        // pw.Text(_clientAddress),
        pw.Text(_clientCityStateZip, style: pw.TextStyle(font: robotoFont)),
        pw.Text(_clientCountry, style: pw.TextStyle(font: robotoFont)),
        pw.Text(_clientEmail, style: pw.TextStyle(font: robotoFont)),
        pw.SizedBox(height: 20),
        pw.Text(
          'Invoice Date: $_invoiceDate',
          style: pw.TextStyle(font: robotoFont),
        ),
        pw.Text('Due Date: $_dueDate', style: pw.TextStyle(font: robotoFont)),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          headers: ['Description', 'Total'],
          headerStyle: pw.TextStyle(
            font: robotoFont,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: pw.TextStyle(font: robotoFont),
          data:
              _items
                  .map(
                    (item) => [
                      item['description'],
                      '$_selectedCurrency${(item['quantity'] * item['price']).toStringAsFixed(2)}',
                    ],
                  )
                  .toList(),
        ),
        pw.SizedBox(height: 20),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Subtotal: $_selectedCurrency${_items.fold<double>(0.0, (sum, item) => sum + item['quantity'] * item['price']).toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 12, font: robotoFont),
            ),
            pw.Text(
              'Tax (${_taxPercentage.toStringAsFixed(1)}%): $_selectedCurrency${(_items.fold<double>(0.0, (sum, item) => sum + item['quantity'] * item['price']) * (_taxPercentage / 100)).toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 12, font: robotoFont),
            ),
            pw.Text(
              'Total: $_selectedCurrency${calculateTotal().toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 14, font: robotoFont),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildElegantLayout(
    Color themeColor,
    pw.MemoryImage? logoImage,
    pw.Font robotoFont,
  ) {
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
                    font: robotoFont,
                  ),
                ),
                pw.Text(
                  'Invoice #$_invoiceNumber',
                  style: pw.TextStyle(fontSize: 14, font: robotoFont),
                ),
                pw.Text(
                  'Invoice Date: $_invoiceDate',
                  style: pw.TextStyle(font: robotoFont),
                ),
                pw.Text(
                  'Due Date: $_dueDate',
                  style: pw.TextStyle(font: robotoFont),
                ),
              ],
            ),
          ],
        ),
        // pw.SizedBox(height: 10),
        // pw.Text('Invoice #$_invoiceNumber', style: const pw.TextStyle(fontSize: 14)),
        pw.SizedBox(height: 20),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                color: PdfColor.fromInt(themeColor.value),
                width: 2,
              ),
            ),
          ),
          child: pw.Text(
            _businessName,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              font: robotoFont,
            ),
          ),
        ),
        pw.Text(_yourName, style: pw.TextStyle(font: robotoFont)),
        pw.Text(_businessAddress, style: pw.TextStyle(font: robotoFont)),
        pw.Text(_companyCityStateZip, style: pw.TextStyle(font: robotoFont)),
        pw.Text(_companyCountry, style: pw.TextStyle(font: robotoFont)),
        pw.SizedBox(height: 20),
        pw.Text(
          'Bill to:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: robotoFont),
        ),
        pw.Text(_clientCompany, style: pw.TextStyle(font: robotoFont)),
        // pw.Text(_clientName),
        // pw.Text(_clientAddress),
        pw.Text(_clientCityStateZip, style: pw.TextStyle(font: robotoFont)),
        pw.Text(_clientCountry, style: pw.TextStyle(font: robotoFont)),
        pw.Text(_clientEmail, style: pw.TextStyle(font: robotoFont)),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          headers: ['Description', 'Qty', 'Price', 'Total'],
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(themeColor.value),
            font: robotoFont,
          ),
          cellStyle: pw.TextStyle(fontSize: 12, font: robotoFont),
          data:
              _items
                  .map(
                    (item) => [
                      item['description'],
                      item['quantity'].toString(),
                      '$_selectedCurrency${item['price'].toStringAsFixed(2)}',
                      '$_selectedCurrency${(item['quantity'] * item['price']).toStringAsFixed(2)}',
                    ],
                  )
                  .toList(),
        ),
        pw.SizedBox(height: 20),
        pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Subtotal: $_selectedCurrency${_items.fold<double>(0.0, (sum, item) => sum + item['quantity'] * item['price']).toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 14, font: robotoFont),
              ),
              pw.Text(
                'Tax (${_taxPercentage.toStringAsFixed(1)}%): $_selectedCurrency${(_items.fold<double>(0.0, (sum, item) => sum + item['quantity'] * item['price']) * (_taxPercentage / 100)).toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 14, font: robotoFont),
              ),
              pw.Text(
                'Total: $_selectedCurrency${calculateTotal().toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  font: robotoFont,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCompactLayout(
    Color themeColor,
    pw.MemoryImage? logoImage,
    pw.Font robotoFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            logoImage != null
                ? pw.Image(logoImage, width: 60, height: 60)
                : pw.SizedBox(width: 60, height: 60),
            pw.Column(
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 20,
                    color: PdfColor.fromInt(themeColor.value),
                    fontWeight: pw.FontWeight.bold,
                    font: robotoFont,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Invoice #$_invoiceNumber',
                  style: pw.TextStyle(fontSize: 12, font: robotoFont),
                ),
              ],
            ),
          ],
        ),
        // pw.SizedBox(height: 10),
        // pw.Text('Invoice #$_invoiceNumber', style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'From:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    font: robotoFont,
                  ),
                ),
                pw.Text(
                  _businessName,
                  style: pw.TextStyle(fontSize: 14, font: robotoFont),
                ),
                pw.Text(
                  _yourName,
                  style: pw.TextStyle(fontSize: 12, font: robotoFont),
                ),
                pw.Text(
                  _businessAddress,
                  style: pw.TextStyle(fontSize: 12, font: robotoFont),
                ),
                pw.Text(
                  _companyCityStateZip,
                  style: pw.TextStyle(fontSize: 12, font: robotoFont),
                ),
                pw.Text(
                  _companyCountry,
                  style: pw.TextStyle(fontSize: 12, font: robotoFont),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Bill to:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    font: robotoFont,
                  ),
                ),
                pw.Text(
                  _clientCompany,
                  style: pw.TextStyle(fontSize: 14, font: robotoFont),
                ),
                pw.Text(
                  _clientCityStateZip,
                  style: pw.TextStyle(fontSize: 12, font: robotoFont),
                ),
                pw.Text(
                  _clientCountry,
                  style: pw.TextStyle(fontSize: 12, font: robotoFont),
                ),
                pw.Text(
                  _clientEmail,
                  style: pw.TextStyle(fontSize: 12, font: robotoFont),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Invoice Date: $_invoiceDate',
          style: pw.TextStyle(fontSize: 12, font: robotoFont),
        ),
        pw.Text(
          'Due Date: $_dueDate',
          style: pw.TextStyle(fontSize: 12, font: robotoFont),
        ),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          headers: ['Item', 'Total'],
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(themeColor.value),
            font: robotoFont,
          ),
          cellStyle: pw.TextStyle(fontSize: 10, font: robotoFont),
          data:
              _items
                  .map(
                    (item) => [
                      item['description'],
                      '$_selectedCurrency${(item['quantity'] * item['price']).toStringAsFixed(2)}',
                    ],
                  )
                  .toList(),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Subtotal: $_selectedCurrency${_items.fold<double>(0.0, (sum, item) => sum + item['quantity'] * item['price']).toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 10, font: robotoFont),
              ),
              pw.Text(
                'Tax (${_taxPercentage.toStringAsFixed(1)}%): $_selectedCurrency${(_items.fold<double>(0.0, (sum, item) => sum + item['quantity'] * item['price']) * (_taxPercentage / 100)).toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 10, font: robotoFont),
              ),
              pw.Text(
                'Total: $_selectedCurrency${calculateTotal().toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  font: robotoFont,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double calculateTotal() {
    double subtotal = 0.0;
    for (var item in _items) {
      subtotal += item['quantity'] * item['price'];
    }
    double taxAmount = subtotal * (_taxPercentage / 100);
    return subtotal + taxAmount;
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

  Future<String?> showKeyNameDialog(BuildContext context) async {

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Key Name'),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: 'Enter a key name'),
            onChanged: (value) {
              keyName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // cancel
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (keyName.trim().isNotEmpty) {
                  _saveInfo(keyName);
                  Navigator.of(context).pop(keyName.trim());
                }
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
  Future<Uint8List> compressImage(String path) async {
    final image = img.decodeImage(File(path).readAsBytesSync())!;
    final resized = img.copyResize(image, width: 800);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 70));
  }


// Add this method:
  Future<void> _generateAndSavePDF() async {
    final pdf = pw.Document();
    final themeColor = _colorOptions[_selectedColor]!;
    pw.MemoryImage? logoImage;

    // if (_logoFile != null && _logoFile!.existsSync()) {
    //   logoImage = pw.MemoryImage(_logoFile!.readAsBytesSync());
    // }

    if (_logoFile != null && _logoFile!.existsSync()) {
      final compressedImage = await compressImage(_logoFile!.path);
      logoImage = pw.MemoryImage(compressedImage);
    }

    // Load Roboto font
    final fontData = await DefaultAssetBundle.of(context).load('assets/fonts/Roboto-Regular.ttf');
    final robotoFont = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          switch (_selectedLayout) {
            case 'Modern':
              return _buildModernLayout(themeColor, logoImage, robotoFont);
            case 'Minimal':
              return _buildMinimalLayout(themeColor, logoImage, robotoFont);
            case 'Elegant':
              return _buildElegantLayout(themeColor, logoImage, robotoFont);
            case 'Compact':
              return _buildCompactLayout(themeColor, logoImage, robotoFont);
            default:
              return _buildProfessionalLayout(themeColor, logoImage, robotoFont);
          }
        },
      ),
    );

    // Request storage permission (needed for Android 10 and below)
    if (Platform.isAndroid) {
      await Permission.storage.request();
    }

    Directory? downloadsDir;

    if (Platform.isAndroid || Platform.isIOS) {
      downloadsDir = await getExternalStorageDirectory(); // falls back to app dir
    } else {
      downloadsDir = await getDownloadsDirectory();
    }

    final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final filePath = '/storage/emulated/0/Download/$fileName';
    final file = File(filePath);

    await file.writeAsBytes(await pdf.save());

    // // Optionally open the file
    // await OpenFile.open(file.path);
    print('PDF saved to ${file.path}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved to ${file.path}')),
    );
  }

  void _removeItem(int index) {
    if (_items.length > 1) { // Prevent removing the last item
      setState(() {
        _items.removeAt(index);
        _itemControllers.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one item is required')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // if (_formKey.currentState!.validate()) {
                    if (_businessNameController.text.isNotEmpty &&
                        _clientCompanyController.text.isNotEmpty) {
                      if (widget.invoiceKey != null &&
                          widget.invoiceKey!.isNotEmpty) {
                        _saveInfo(widget.invoiceKey!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Information saved')),
                        );
                      } else {
                        print("showKeyNameDialog");
                        showKeyNameDialog(context);
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Your company and Client's company are necessary to save form")),
                      );
                    }
                  },
                  icon: const Icon(Icons.save, size: 16,color: Color(0xFF2E8B77),),
                  label: const Text('Save',style: TextStyle(color: Color(0xFF2E8B77)),),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),


                const SizedBox(width: 5),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _generatePDF();
                    }
                    else{
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill necessary fields")),
                      );
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 16,color: Color(0xFF2E8B77),),
                  label: const Text('Preview',style: TextStyle(color: Color(0xFF2E8B77)),),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),

                const SizedBox(width: 5),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _generateAndSharePdf();
                    }
                    else{
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill necessary fields")),
                      );
                    }
                  },
                  icon: const Icon(Icons.share, size: 16,color: Color(0xFF2E8B77),),
                  label: const Text('Share',style: TextStyle(color: Color(0xFF2E8B77)),),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),


                const SizedBox(width: 5),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _generateAndSavePDF();
                    }
                    else{
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill necessary fields")),
                      );
                    }
                  },
                  icon:  Image.asset( 'assets/images/download_icon.png',height: 16,width: 16,),
                  label: const Text('Download',style: TextStyle(color: Color(0xFF2E8B77)),),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE9DFFF), Color(0xFFD1E7FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 1.0],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE9DFFF), Color(0xFFD1E7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 1.0],
          ),
        ),
        child: SingleChildScrollView(
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
                            items:
                                _colorOptions.keys
                                    .map(
                                      (color) => DropdownMenuItem(
                                        value: color,
                                        child: Text(color),
                                      ),
                                    )
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
                            items:
                                _layoutOptions
                                    .map(
                                      (layout) => DropdownMenuItem(
                                        value: layout,
                                        child: Text(layout),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedLayout = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedCurrency,
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                              prefixIcon: Icon(Icons.monetization_on),
                            ),
                            items:
                                _currencyOptions.entries
                                    .map(
                                      (entry) => DropdownMenuItem(
                                        value: entry.value,
                                        child: Text(
                                          '${entry.key} (${entry.value})',
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCurrency = value!;
                                print("_selectedCurrency" + _selectedCurrency);
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
                                child:
                                    _logoFile != null && _logoFile!.existsSync()
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.file(
                                            _logoFile!,
                                            height: 80,
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                        : Container(
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text('No logo selected'),
                                          ),
                                        ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _pickLogo,
                                icon: const Icon(Icons.upload, size: 18,color: Color(0xFF2E8B77)),
                                label: const Text('Upload',style: TextStyle(color: Color(0xFF2E8B77))),
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
                              labelText: 'Your Company',
                              prefixIcon: Icon(Icons.business),
                            ),
                            onChanged: (value) => _businessName = value,
                            validator:
                                (value) => value!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _yourNameController,
                            decoration: const InputDecoration(
                              labelText: 'Your Name',
                              prefixIcon: Icon(Icons.person),
                            ),
                            onChanged: (value) => _yourName = value,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _businessAddressController,
                            decoration: const InputDecoration(
                              labelText: 'Company Address',
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            onChanged: (value) => _businessAddress = value,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _companyCityStateZipController,
                            decoration: const InputDecoration(
                              labelText: 'City, State, Zip',
                              prefixIcon: Icon(Icons.location_city),
                            ),
                            onChanged: (value) => _companyCityStateZip = value,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _companyCountryController,
                            decoration: const InputDecoration(
                              labelText: 'Country',
                              prefixIcon: Icon(Icons.flag),
                            ),
                            onChanged: (value) => _companyCountry = value,
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
                            controller: _clientCompanyController,
                            decoration: const InputDecoration(
                              labelText: 'Client\'s Company or Name',
                              prefixIcon: Icon(Icons.business),
                            ),
                            onChanged: (value) => _clientCompany = value,
                            validator:
                                (value) => value!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _clientEmailController,
                            decoration: const InputDecoration(
                              labelText: 'Client Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                            onChanged: (value) => _clientEmail = value,
                            // validator: (value) => value!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _clientCityStateZipController,
                            decoration: const InputDecoration(
                              labelText: 'City, State, Zip',
                              prefixIcon: Icon(Icons.location_city),
                            ),
                            onChanged: (value) => _clientCityStateZip = value,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _clientCountryController,
                            decoration: const InputDecoration(
                              labelText: 'Country',
                              prefixIcon: Icon(Icons.flag),
                            ),
                            onChanged: (value) => _clientCountry = value,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Invoice Details
                const SizedBox(height: 16),
                FadeInDown(
                  duration: const Duration(milliseconds: 850),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice Details',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _invoiceNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Invoice #',
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            onChanged: (value) => _invoiceNumber = value,
                            // validator: (value) => value!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _invoiceDateController,
                            decoration: const InputDecoration(
                              labelText: 'Invoice Date (YYYY-MM-DD)',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            // Prevent manual input
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  _invoiceDate =
                                      pickedDate.toString().split(' ')[0];
                                  _invoiceDateController.text = _invoiceDate;
                                });
                              }
                            },
                            onChanged: (value) => _invoiceDate = value,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _dueDateController,
                            decoration: const InputDecoration(
                              labelText: 'Due Date (YYYY-MM-DD)',
                              prefixIcon: Icon(Icons.calendar_month),
                            ),
                            readOnly: true,
                            // Prevent manual input
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  _dueDate =
                                      pickedDate.toString().split(' ')[0];
                                  _dueDateController.text = _dueDate;
                                });
                              }
                            },
                            onChanged: (value) => _dueDate = value,
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _itemControllers[index]['description'],
                                        decoration: const InputDecoration(
                                          labelText: 'Description',
                                          prefixIcon: Icon(Icons.description),
                                        ),
                                        onChanged: (value) => _items[index]['description'] = value,
                                        validator: (value) {
                                          if (_items.every((item) => item['description'].isEmpty)) {
                                            return index == 0 ? 'At least one item description is required' : null;
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeItem(index),
                                    ),
                                  ],
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
                                        onChanged: (value) => _items[index]['quantity'] = int.tryParse(value) ?? 0,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _itemControllers[index]['price'],
                                        decoration: InputDecoration(
                                          labelText: 'Price',
                                          prefixIcon: const Icon(Icons.monetization_on),
                                          prefixText: _selectedCurrency,
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) => _items[index]['price'] = double.tryParse(value) ?? 0.0,
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
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: Color(0xFF2C3E50),
                            ),
                            label: Text(
                              'Add Item',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _taxController,
                            decoration: InputDecoration(
                              labelText: 'Tax (%)',
                              prefixIcon: const Icon(Icons.percent),
                              suffixText: '%',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _taxPercentage = double.tryParse(value) ?? 0.0;
                              });
                            },
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
      ),
    );
  }
}
