import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';
import 'session_service.dart';

class PdfReportSections {
  final bool summary;
  final bool chart;
  final bool collectionHistory;
  final bool issues;

  const PdfReportSections({
    this.summary = true,
    this.chart = true,
    this.collectionHistory = true,
    this.issues = true,
  });

  bool get hasSelection => summary || chart || collectionHistory || issues;
}

class PdfChartSeries {
  final String name;
  final String colorHex;
  final List<double> values;

  const PdfChartSeries({
    required this.name,
    required this.colorHex,
    required this.values,
  });
}

class PdfReportService {
  static final DateFormat _generatedDateFormat = DateFormat('dd/MM/yyyy HH:mm');

  static Future<void> exportUserCollectionReport({
    required String periodLabel,
    required String machineLabel,
    required String wasteTypeLabel,
    required Map<String, double> totals,
    required List<CollectionHistoryItem> history,
    required List<IssueReportItem> issues,
    required List<DateTime> chartDates,
    required List<PdfChartSeries> chartSeries,
    required PdfReportSections sections,
  }) async {
    final bytes = await buildUserCollectionReport(
      periodLabel: periodLabel,
      machineLabel: machineLabel,
      wasteTypeLabel: wasteTypeLabel,
      totals: totals,
      history: history,
      issues: issues,
      chartDates: chartDates,
      chartSeries: chartSeries,
      sections: sections,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'smart_recycle_report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }

  static Future<Uint8List> buildUserCollectionReport({
    required String periodLabel,
    required String machineLabel,
    required String wasteTypeLabel,
    required Map<String, double> totals,
    required List<CollectionHistoryItem> history,
    required List<IssueReportItem> issues,
    required List<DateTime> chartDates,
    required List<PdfChartSeries> chartSeries,
    required PdfReportSections sections,
  }) async {
    if (!sections.hasSelection) {
      throw ArgumentError('ต้องเลือกอย่างน้อยหนึ่งส่วนของรายงาน');
    }

    final fontData = await rootBundle.load('assets/fonts/tahoma.ttf');
    final logoData = await rootBundle.load('assets/images/logo.png');
    final thaiFont = pw.Font.ttf(fontData);
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());
    final generatedAt = _generatedDateFormat.format(DateTime.now());
    final documentNumber =
        'SR-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}';
    final document = pw.Document(
      title: 'Smart Recycle User Collection Report',
      author: 'Smart Recycle',
      subject: 'User collection data report',
      theme: pw.ThemeData.withFont(base: thaiFont, bold: thaiFont),
    );

    final content = <pw.Widget>[
      _reportHeader(
        logo: logo,
        generatedAt: generatedAt,
        documentNumber: documentNumber,
        periodLabel: periodLabel,
        machineLabel: machineLabel,
        wasteTypeLabel: wasteTypeLabel,
      ),
      pw.SizedBox(height: 18),
    ];

    if (sections.summary) {
      content.addAll([
        _sectionTitle('สรุปข้อมูลการเก็บขยะ'),
        _summary(totals, history.length, issues),
        pw.SizedBox(height: 18),
      ]);
    }
    if (sections.chart) {
      content.addAll([
        _sectionTitle('กราฟปริมาณขยะที่เก็บแล้ว'),
        pw.Text(
          'แสดงน้ำหนักขยะที่ผู้ใช้งานรายนี้เป็นผู้เก็บ แยกตามเครื่องและวันที่',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
        _chart(chartDates, chartSeries),
        pw.SizedBox(height: 18),
      ]);
    }
    if (sections.collectionHistory) {
      if (sections.chart) {
        content.add(pw.NewPage());
      }
      content.addAll([
        _sectionTitle('รายละเอียดประวัติการเก็บขยะ'),
        _historyTable(history),
        pw.SizedBox(height: 18),
      ]);
    }
    if (sections.issues) {
      content.addAll([
        _sectionTitle('รายการแจ้งปัญหา'),
        _issueTable(issues),
      ]);
    }

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 36),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Smart Recycle - $documentNumber',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'หน้า ${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
        build: (_) => content,
      ),
    );
    return document.save();
  }

  static pw.Widget _reportHeader({
    required pw.MemoryImage logo,
    required String generatedAt,
    required String documentNumber,
    required String periodLabel,
    required String machineLabel,
    required String wasteTypeLabel,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(height: 7, color: PdfColors.teal600),
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
          color: PdfColors.teal50,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(
                logo,
                width: 48,
                height: 48,
                fit: pw.BoxFit.contain,
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'รายงานข้อมูลการเก็บขยะ',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal800,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'ระบบบริหารจัดการขยะ Smart Recycle',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('เลขที่รายงาน $documentNumber'),
                  pw.Text('จัดทำเมื่อ $generatedAt'),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              _informationRow(
                  'ผู้จัดเก็บ', '${currentUser.name} (${currentUser.id})'),
              _informationRow(
                'หน่วยงาน',
                currentUser.organizationName.isEmpty
                    ? '-'
                    : currentUser.organizationName,
              ),
              _informationRow('ช่วงวันที่', periodLabel),
              _informationRow('เครื่องคัดแยก', machineLabel),
              _informationRow('ประเภทขยะ', wasteTypeLabel),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _informationRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 76,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: const pw.BoxDecoration(
        color: PdfColors.teal50,
        border: pw.Border(
          left: pw.BorderSide(color: PdfColors.teal600, width: 4),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _summary(
    Map<String, double> totals,
    int collectionCount,
    List<IssueReportItem> issues,
  ) {
    final openIssues = issues.where((item) {
      return item.status != 'Completed' && item.status != 'Resolved';
    }).length;
    return pw.Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        _metricBox('น้ำหนักรวม', '${_number(totals['total'])} กก.'),
        _metricBox('จำนวนครั้งที่เก็บ', '$collectionCount ครั้ง'),
        _metricBox('พลาสติก', '${_number(totals['plastic'])} กก.'),
        _metricBox('แก้ว', '${_number(totals['glass'])} กก.'),
        _metricBox('กระป๋อง', '${_number(totals['can'])} กก.'),
        _metricBox('ปัญหารอดำเนินการ', '$openIssues รายการ'),
      ],
    );
  }

  static pw.Widget _metricBox(String label, String value) {
    return pw.Container(
      width: 168,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _chart(
    List<DateTime> dates,
    List<PdfChartSeries> series,
  ) {
    if (dates.isEmpty || series.isEmpty) {
      return _emptyBox('ไม่มีข้อมูลสำหรับแสดงกราฟ');
    }
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.SvgImage(svg: _chartSvg(dates, series), height: 220),
          pw.SizedBox(height: 8),
          pw.Wrap(
            alignment: pw.WrapAlignment.center,
            spacing: 12,
            runSpacing: 5,
            children: series.map((item) {
              return pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Container(
                    width: 20,
                    height: 3,
                    color: PdfColor.fromHex(item.colorHex),
                  ),
                  pw.SizedBox(width: 5),
                  pw.Text(item.name, style: const pw.TextStyle(fontSize: 8)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static String _chartSvg(
    List<DateTime> dates,
    List<PdfChartSeries> series,
  ) {
    const width = 720.0;
    const height = 260.0;
    const left = 48.0;
    const right = 12.0;
    const top = 12.0;
    const bottom = 32.0;
    const plotWidth = width - left - right;
    const plotHeight = height - top - bottom;
    final values = series.expand((item) => item.values).toList();
    final maximum = values.isEmpty ? 0.0 : values.reduce(math.max);
    final yMaximum = maximum <= 10 ? 10.0 : (maximum / 10).ceil() * 10.0;
    final buffer = StringBuffer(
      '<svg xmlns="http://www.w3.org/2000/svg" '
      'width="$width" height="$height" viewBox="0 0 $width $height">',
    );
    buffer.write('<rect width="$width" height="$height" fill="#ffffff"/>');
    for (var index = 0; index <= 4; index++) {
      final y = top + plotHeight / 4 * index;
      final value = yMaximum - yMaximum / 4 * index;
      buffer.write(
        '<line x1="$left" y1="$y" x2="${width - right}" y2="$y" '
        'stroke="#e2e8f0" stroke-width="1" stroke-dasharray="4 4"/>',
      );
      buffer.write(
        '<text x="${left - 7}" y="${y + 3}" text-anchor="end" '
        'font-family="Arial" font-size="10" fill="#64748b">'
        '${_number(value)} kg</text>',
      );
    }
    final labelStep = dates.length <= 5 ? 1 : ((dates.length - 1) / 4).ceil();
    for (var index = 0; index < dates.length; index++) {
      if (index != 0 && index != dates.length - 1 && index % labelStep != 0) {
        continue;
      }
      final x = _chartX(index, dates.length, left, plotWidth);
      final date = dates[index];
      final dateLabel = formatAppDate(date);
      buffer.write(
        '<text x="$x" y="${height - 8}" text-anchor="middle" '
        'font-family="Arial" font-size="10" fill="#64748b">'
        '$dateLabel</text>',
      );
    }
    for (final item in series) {
      final pointCount = math.min(item.values.length, dates.length);
      final points = <String>[];
      for (var index = 0; index < pointCount; index++) {
        final x = _chartX(index, dates.length, left, plotWidth);
        final y = top + plotHeight - item.values[index] / yMaximum * plotHeight;
        points.add('$x,$y');
      }
      buffer.write(
        '<polyline points="${points.join(' ')}" fill="none" '
        'stroke="${item.colorHex}" stroke-width="3" '
        'stroke-linecap="round" stroke-linejoin="round"/>',
      );
      for (var index = 0; index < pointCount; index++) {
        final x = _chartX(index, dates.length, left, plotWidth);
        final y = top + plotHeight - item.values[index] / yMaximum * plotHeight;
        buffer.write(
          '<circle cx="$x" cy="$y" r="3.5" fill="${item.colorHex}"/>',
        );
      }
    }
    buffer.write('</svg>');
    return buffer.toString();
  }

  static double _chartX(int index, int length, double left, double width) {
    if (length <= 1) return left + width / 2;
    return left + width / (length - 1) * index;
  }

  static pw.Widget _historyTable(List<CollectionHistoryItem> history) {
    if (history.isEmpty) return _emptyBox('ไม่พบประวัติการเก็บขยะ');
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.teal100),
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(5),
      headers: ['วันที่', 'เวลา', 'เครื่องคัดแยก', 'ประเภทขยะ', 'น้ำหนัก'],
      data: history.map((item) {
        return [
          formatAppDate(parseAppDate(item.date)),
          item.time,
          item.machineName,
          item.type,
          item.weight,
        ];
      }).toList(),
    );
  }

  static pw.Widget _issueTable(List<IssueReportItem> issues) {
    if (issues.isEmpty) return _emptyBox('ไม่มีรายการแจ้งปัญหา');
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.orange100),
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(5),
      headers: ['วันที่', 'เครื่องคัดแยก', 'หัวข้อ', 'รายละเอียด', 'สถานะ'],
      data: issues.map((item) {
        return [
          formatAppDate(parseAppDate(item.date)),
          item.machineName.isEmpty ? item.machineId : item.machineName,
          item.title,
          item.description,
          _statusLabel(item.status),
        ];
      }).toList(),
    );
  }

  static pw.Widget _emptyBox(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(18),
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child:
          pw.Text(message, style: const pw.TextStyle(color: PdfColors.grey700)),
    );
  }

  static String _statusLabel(String status) {
    return switch (status) {
      'Waiting' => 'รอดำเนินการ',
      'In Progress' => 'กำลังดำเนินการ',
      'Completed' || 'Resolved' => 'เสร็จสิ้น',
      _ => status,
    };
  }

  static String _number(double? value) {
    final number = value ?? 0;
    return number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toStringAsFixed(2);
  }
}
