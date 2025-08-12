// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoiceInfoAdapter extends TypeAdapter<InvoiceInfo> {
  @override
  final int typeId = 0;

  @override
  InvoiceInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvoiceInfo(
      businessName: fields[0] as String,
      businessAddress: fields[1] as String,
      clientEmail: fields[2] as String,
      yourName: fields[3] as String,
      companyCityStateZip: fields[4] as String,
      companyCountry: fields[5] as String,
      clientCompany: fields[6] as String,
      clientCityStateZip: fields[7] as String,
      clientCountry: fields[8] as String,
      invoiceNumber: fields[9] as String,
      invoiceDate: fields[10] as String,
      dueDate: fields[11] as String,
      currency: fields[12] as String,
      taxPercentage: fields[13] as double,
      logoPath: fields[14] as String?,
      taxId: fields[15] as String,
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceInfo obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.businessName)
      ..writeByte(1)
      ..write(obj.businessAddress)
      ..writeByte(2)
      ..write(obj.clientEmail)
      ..writeByte(3)
      ..write(obj.yourName)
      ..writeByte(4)
      ..write(obj.companyCityStateZip)
      ..writeByte(5)
      ..write(obj.companyCountry)
      ..writeByte(6)
      ..write(obj.clientCompany)
      ..writeByte(7)
      ..write(obj.clientCityStateZip)
      ..writeByte(8)
      ..write(obj.clientCountry)
      ..writeByte(9)
      ..write(obj.invoiceNumber)
      ..writeByte(10)
      ..write(obj.invoiceDate)
      ..writeByte(11)
      ..write(obj.dueDate)
      ..writeByte(12)
      ..write(obj.currency)
      ..writeByte(13)
      ..write(obj.taxPercentage)
      ..writeByte(14)
      ..write(obj.logoPath)
      ..writeByte(15)
      ..write(obj.taxId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
