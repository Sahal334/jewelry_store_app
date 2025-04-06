// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoiceAdapter extends TypeAdapter<Invoice> {
  @override
  final int typeId = 1;

  @override
  Invoice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Invoice(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      customerName: fields[2] as String,
      customerPhone: fields[3] as String?,
      customerEmail: fields[4] as String?,
      items: (fields[5] as List).cast<InvoiceItem>(),
      subtotal: fields[6] as double,
      taxAmount: fields[7] as double,
      discountAmount: fields[8] as double,
      total: fields[9] as double,
      notes: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Invoice obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.customerName)
      ..writeByte(3)
      ..write(obj.customerPhone)
      ..writeByte(4)
      ..write(obj.customerEmail)
      ..writeByte(5)
      ..write(obj.items)
      ..writeByte(6)
      ..write(obj.subtotal)
      ..writeByte(7)
      ..write(obj.taxAmount)
      ..writeByte(8)
      ..write(obj.discountAmount)
      ..writeByte(9)
      ..write(obj.total)
      ..writeByte(10)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InvoiceItemAdapter extends TypeAdapter<InvoiceItem> {
  @override
  final int typeId = 2;

  @override
  InvoiceItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvoiceItem(
      productId: fields[0] as String,
      productName: fields[1] as String,
      price: fields[2] as double,
      quantity: fields[3] as int,
      tax: fields[4] as double,
      discount: fields[5] as double,
      subtotal: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.tax)
      ..writeByte(5)
      ..write(obj.discount)
      ..writeByte(6)
      ..write(obj.subtotal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
