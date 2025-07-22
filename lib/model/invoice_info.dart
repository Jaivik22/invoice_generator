import 'package:hive/hive.dart';

part 'invoice_info.g.dart';

@HiveType(typeId: 0)
class InvoiceInfo extends HiveObject {
  @HiveField(0)
  String businessName;

  @HiveField(1)
  String businessAddress;

  @HiveField(2)
  String clientEmail;

  @HiveField(3)
  String yourName;

  @HiveField(4)
  String companyCityStateZip;

  @HiveField(5)
  String companyCountry;

  @HiveField(6)
  String clientCompany;

  @HiveField(7)
  String clientCityStateZip;

  @HiveField(8)
  String clientCountry;

  @HiveField(9)
  String invoiceNumber;

  @HiveField(10)
  String invoiceDate;

  @HiveField(11)
  String dueDate;

  @HiveField(12)
  String currency;

  @HiveField(13)
  double taxPercentage;

  @HiveField(14)
  String? logoPath;

  @HiveField(15)
  String taxId;

  InvoiceInfo({
    required this.businessName,
    required this.businessAddress,
    required this.clientEmail,
    required this.yourName,
    required this.companyCityStateZip,
    required this.companyCountry,
    required this.clientCompany,
    required this.clientCityStateZip,
    required this.clientCountry,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.currency,
    required this.taxPercentage,
    this.logoPath,
    required this.taxId
  });
}
