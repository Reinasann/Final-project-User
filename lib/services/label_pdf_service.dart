import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';

class LabelPdfService {
  static const PdfPageFormat labelFormat = PdfPageFormat(
    100 * PdfPageFormat.mm,
    150 * PdfPageFormat.mm,
  );

  static Future<Uint8List> buildLabel({
    required String batchCode,
    required String machineName,
    required String wasteType,
    required double weightKg,
    required DateTime collectedAt,
    required String collectorName,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/tahoma.ttf');
    final logoData = await rootBundle.load('assets/images/logo.png');
    final thaiFont = pw.Font.ttf(fontData);
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());
    final document = pw.Document(
      title: 'Smart Recycle Label - $batchCode',
      author: 'Smart Recycle',
      subject: 'Waste collection label',
      theme: pw.ThemeData.withFont(base: thaiFont, bold: thaiFont),
    );
    final collectedDate = formatAppDate(collectedAt);
    final collectedTime = DateFormat('HH:mm').format(collectedAt);
    final qrPayload = [
      'batch=$batchCode',
      'machine=$machineName',
      'type=$wasteType',
      'weight=${weightKg.toStringAsFixed(2)}kg',
      'collected=${collectedAt.toIso8601String()}',
      'collector=$collectorName',
    ].join('|');

    document.addPage(
      pw.Page(
        pageFormat: labelFormat,
        margin: const pw.EdgeInsets.all(7 * PdfPageFormat.mm),
        build: (_) => pw.Container(
          padding: const pw.EdgeInsets.all(6 * PdfPageFormat.mm),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1.6),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Image(
                        logo,
                        width: 14 * PdfPageFormat.mm,
                        height: 14 * PdfPageFormat.mm,
                        fit: pw.BoxFit.contain,
                      ),
                      pw.SizedBox(width: 3 * PdfPageFormat.mm),
                      pw.Text(
                        'SMART RECYCLE',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green50,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Text(
                      'ฉลากขยะรีไซเคิล',
                      style: pw.TextStyle(
                        color: PdfColors.green800,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1.5, color: PdfColors.black),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrPayload,
                  width: 39 * PdfPageFormat.mm,
                  height: 39 * PdfPageFormat.mm,
                  drawText: false,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  batchCode,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              pw.SizedBox(height: 15),
              _informationRow('เครื่องคัดแยก', machineName),
              _informationRow('ประเภทขยะ', wasteType),
              _informationRow(
                'น้ำหนักสุทธิ',
                '${weightKg.toStringAsFixed(2)} กก.',
                emphasize: true,
              ),
              _informationRow('วันที่เก็บ', collectedDate),
              _informationRow('เวลา', '$collectedTime น.'),
              _informationRow('ผู้เก็บขยะ', collectorName),
              pw.Spacer(),
              pw.Divider(
                color: PdfColors.grey500,
                borderStyle: pw.BorderStyle.dashed,
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'สแกน QR Code เพื่อตรวจสอบข้อมูลการเก็บขยะ',
                textAlign: pw.TextAlign.center,
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
      ),
    );
    return document.save();
  }

  static Future<void> printToPrinter({
    required String batchCode,
    required String machineName,
    required String wasteType,
    required double weightKg,
    required DateTime collectedAt,
    required String collectorName,
  }) async {
    final bytes = await buildLabel(
      batchCode: batchCode,
      machineName: machineName,
      wasteType: wasteType,
      weightKg: weightKg,
      collectedAt: collectedAt,
      collectorName: collectorName,
    );
    await Printing.layoutPdf(
      name: 'ฉลาก $batchCode',
      format: labelFormat,
      dynamicLayout: false,
      onLayout: (_) async => bytes,
    );
  }

  static Future<void> exportPdf({
    required String batchCode,
    required String machineName,
    required String wasteType,
    required double weightKg,
    required DateTime collectedAt,
    required String collectorName,
  }) async {
    final bytes = await buildLabel(
      batchCode: batchCode,
      machineName: machineName,
      wasteType: wasteType,
      weightKg: weightKg,
      collectedAt: collectedAt,
      collectorName: collectorName,
    );
    final safeCode = batchCode.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'smart_recycle_label_$safeCode.pdf',
    );
  }

  static pw.Widget _informationRow(
    String label,
    String value, {
    bool emphasize = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 31 * PdfPageFormat.mm,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: emphasize ? 12 : 9,
                fontWeight:
                    emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
