import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jewelry_store_app/models/invoice_model.dart';
import 'package:jewelry_store_app/services/pdf_servies.dart';


class InvoicePreviewScreen extends StatelessWidget {
  final Invoice invoice;
  final File pdfFile;

  const InvoicePreviewScreen({
    Key? key,
    required this.invoice,
    required this.pdfFile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => PdfService.printPdf(pdfFile),
            tooltip: 'Print Invoice',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => PdfService.sharePdf(pdfFile),
            tooltip: 'Share Invoice',
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: pdfFile.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Failed to load PDF'));
          }
          
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: buildInvoicePreview(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildInvoicePreview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Divider(height: 32),
              _buildCustomerInfo(),
              const SizedBox(height: 24),
              _buildItemsTable(),
              const SizedBox(height: 24),
              _buildTotals(),
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildNotes(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'JEWELRY STORE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Premium Jewelry Collections'),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'INVOICE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('# ${invoice.id.substring(0, 8)}'),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    final dateFormat = DateFormat('MMMM dd, yyyy');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bill To:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(invoice.customerName),
            if (invoice.customerPhone != null) Text(invoice.customerPhone!),
            if (invoice.customerEmail != null) Text(invoice.customerEmail!),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Invoice Date:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(dateFormat.format(invoice.date)),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.grey[200],
          child: Row(
            children: [
              _tableHeader('Item', flex: 3),
              _tableHeader('Price'),
              _tableHeader('Qty'),
              _tableHeader('Tax'),
              _tableHeader('Disc'),
              _tableHeader('Amount'),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: invoice.items.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
          itemBuilder: (context, index) {
            final item = invoice.items[index];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _tableCell(item.productName, flex: 3, alignment: CrossAxisAlignment.start),
                  _tableCell('\$${item.price.toStringAsFixed(2)}'),
                  _tableCell('${item.quantity}'),
                  _tableCell('${item.tax}%'),
                  _tableCell('${item.discount}%'),
                  _tableCell('\$${item.subtotal.toStringAsFixed(2)}'),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _tableHeader(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _tableCell(String text, {int flex = 1, CrossAxisAlignment alignment = CrossAxisAlignment.center}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: alignment == CrossAxisAlignment.start
            ? Text(text)
            : Text(text, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildTotals() {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 200,
        child: Column(
          children: [
            _buildTotalRow('Subtotal:', '\$${invoice.subtotal.toStringAsFixed(2)}'),
            _buildTotalRow('Tax:', '\$${invoice.taxAmount.toStringAsFixed(2)}'),
            _buildTotalRow('Discount:', '- \$${invoice.discountAmount.toStringAsFixed(2)}'),
            const Divider(),
            _buildTotalRow(
              'Total:',
              '\$${invoice.total.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(invoice.notes!),
      ],
    );
  }
}