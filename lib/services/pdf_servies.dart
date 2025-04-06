import 'dart:io';
import 'package:jewelry_store_app/models/invoice_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<File> generateInvoice(Invoice invoice) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(invoice, boldFont),
            pw.SizedBox(height: 30),
            _buildInvoiceInfo(invoice, font, boldFont),
            pw.SizedBox(height: 30),
            _buildItemsTable(invoice, font, boldFont),
            pw.SizedBox(height: 30),
            _buildTotal(invoice, font, boldFont),
            pw.SizedBox(height: 20),
            if (invoice.notes != null && invoice.notes!.isNotEmpty)
              _buildNotes(invoice.notes!, font),
            pw.SizedBox(height: 20),
            _buildFooter(font),
          ];
        },
      ),
    );

    return await _savePdfFile(pdf, 'invoice_${invoice.id}.pdf');
  }

  static pw.Widget _buildHeader(Invoice invoice, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('JEWELRY STORE', style: pw.TextStyle(font: boldFont, fontSize: 24)),
                pw.Text('Premium Jewelry Collections', style: pw.TextStyle(fontSize: 12)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('INVOICE', style: pw.TextStyle(font: boldFont, fontSize: 24)),
                pw.Text('# ${invoice.id}', style: pw.TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildInvoiceInfo(Invoice invoice, pw.Font font, pw.Font boldFont) {
    final dateFormat = DateFormat('MMMM dd, yyyy');
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Bill To:', style: pw.TextStyle(font: boldFont)),
            pw.Text(invoice.customerName),
            if (invoice.customerPhone != null) pw.Text(invoice.customerPhone!),
            if (invoice.customerEmail != null) pw.Text(invoice.customerEmail!),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Invoice Date:', style: pw.TextStyle(font: boldFont)),
            pw.Text(dateFormat.format(invoice.date)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(Invoice invoice, pw.Font font, pw.Font boldFont) {
    final headers = [
      'Item',
      'Price',
      'Qty',
      'Tax',
      'Discount',
      'Amount'
    ];

    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: headers.map((header) => pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(header, style: pw.TextStyle(font: boldFont)),
          )).toList(),
        ),
        ...invoice.items.map((item) => pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item.productName)),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('\$${item.price.toStringAsFixed(2)}')),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${item.quantity}')),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${item.tax}%')),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${item.discount}%')),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('\$${item.subtotal.toStringAsFixed(2)}')),
          ],
        )).toList(),
      ],
    );
  }

  static pw.Widget _buildTotal(Invoice invoice, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildTotalRow('Subtotal:', '\$${invoice.subtotal.toStringAsFixed(2)}', font),
          _buildTotalRow('Tax:', '\$${invoice.taxAmount.toStringAsFixed(2)}', font),
          _buildTotalRow('Discount:', '\$${invoice.discountAmount.toStringAsFixed(2)}', font),
          pw.Divider(),
          _buildTotalRow('Total:', '\$${invoice.total.toStringAsFixed(2)}', boldFont, isTotal: true),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(String title, String value, pw.Font font, {bool isTotal = false}) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: font,
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.SizedBox(width: 100),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: font,
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildNotes(String notes, pw.Font font) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(notes),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text('Thank you for your business!', style: pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 5),
        pw.Text('Jewelry Store | 123 Gem Avenue | jewels@example.com', style: pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static Future<File> _savePdfFile(pw.Document pdf, String fileName) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> printPdf(File pdfFile) async {
    await Printing.layoutPdf(
      onLayout: (_) => pdfFile.readAsBytes(),
    );
  }

  static Future<void> sharePdf(File pdfFile) async {
    await Printing.sharePdf(bytes: await pdfFile.readAsBytes(), filename: pdfFile.path.split('/').last);
  }
}