import 'dart:math' as math;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/api_models.dart';

class ReportService {
  static Future<void> generateAndShareReport({
    required String title,
    required String analysisPeriodLabel,
    required Map<String, double> keyStats,
    ForecastData? forecast,
    SavingsPlan? savingsPlan,
  }) async {
    final pdf = await _buildDocument(
      title: title,
      analysisPeriodLabel: analysisPeriodLabel,
      keyStats: keyStats,
      forecast: forecast,
      savingsPlan: savingsPlan,
    );
    final now = DateTime.now();
    await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'FinSight-Report-${now.millisecondsSinceEpoch}.pdf');
  }

  static Future<String> generateAndSaveReport({
    required String title,
    required String analysisPeriodLabel,
    required Map<String, double> keyStats,
    ForecastData? forecast,
    SavingsPlan? savingsPlan,
  }) async {
    final pdf = await _buildDocument(
      title: title,
      analysisPeriodLabel: analysisPeriodLabel,
      keyStats: keyStats,
      forecast: forecast,
      savingsPlan: savingsPlan,
    );

    final bytes = await pdf.save();
    final docs = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${docs.path}/reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${reportsDir.path}/FinSight_Report_$ts.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return filePath;
  }

  static Future<pw.Document> _buildDocument({
    required String title,
    required String analysisPeriodLabel,
    required Map<String, double> keyStats,
    ForecastData? forecast,
    SavingsPlan? savingsPlan,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final df = DateFormat('yyyy-MM-dd HH:mm');

    pw.Widget buildHeader() {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.purple,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    )),
                pw.SizedBox(height: 4),
                pw.Text('Generated: ${df.format(now)}',
                    style: const pw.TextStyle(color: PdfColors.white))
              ],
            ),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text('Analysis: $analysisPeriodLabel',
                  style: pw.TextStyle(color: PdfColors.purple, fontSize: 10)),
            )
          ],
        ),
      );
    }

    pw.Widget buildKeyStats() {
      final rows = keyStats.entries
          .map((e) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(e.key, style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('₹${e.value.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ))
          .toList();

      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(children: rows),
      );
    }

    pw.Widget buildSavingsSection() {
      if (savingsPlan == null) return pw.SizedBox();
      final plan = savingsPlan!;

      final headerColor =
          plan.planPossible ? PdfColors.green600 : PdfColors.red600;
      final cutsRows = plan.suggestedCuts.entries.map((e) {
        return pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(child: pw.Text(e.key)),
            pw.Text('₹${e.value.toStringAsFixed(0)}'),
          ],
        );
      }).toList();

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: headerColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  plan.planPossible ? 'Plan Achievable' : 'Plan Not Achievable',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                    'Monthly Savings: ₹${plan.monthlySavingsAchieved.toStringAsFixed(0)}',
                    style: const pw.TextStyle(color: PdfColors.white)),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          if (plan.messages.isNotEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: plan.messages
                    .map((m) => pw.Row(children: [
                          pw.Text('• '),
                          pw.Expanded(child: pw.Text(m))
                        ]))
                    .toList(),
              ),
            ),
          pw.SizedBox(height: 8),
          pw.Text('Suggested Spending Cuts',
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          cutsRows.isEmpty
              ? pw.Text('No spending cuts suggested')
              : pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(children: cutsRows),
                ),
        ],
      );
    }

    pw.Widget buildForecastLine() {
      if (forecast == null || forecast!.forecastedSpends.isEmpty)
        return pw.SizedBox();
      final data = forecast!.forecastedSpends.map((e) => e.amount).toList();

      final points = List<pw.PointChartValue>.generate(
        data.length,
        (i) => pw.PointChartValue(i.toDouble(), data[i]),
      );

      final maxY = data.reduce(math.max);
      final step = (maxY / 5).clamp(1, double.infinity);
      final yTicks = List<double>.generate(6, (i) => (step * i).toDouble());

      return pw.Container(
        height: 180,
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Chart(
          grid: pw.CartesianGrid(
            xAxis: pw.FixedAxis.fromStrings(
              List<String>.generate(data.length, (i) => (i + 1).toString()),
              marginStart: 0,
              marginEnd: 0,
            ),
            yAxis: pw.FixedAxis(
              yTicks,
              format: (num v) => '₹${v.toStringAsFixed(0)}',
            ),
          ),
          datasets: [
            pw.LineDataSet(
              color: PdfColors.purple,
              drawSurface: true,
              isCurved: true,
              data: points,
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: await _theme(),
        build: (context) => [
          buildHeader(),
          pw.SizedBox(height: 16),
          pw.Text('Overview',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          buildKeyStats(),
          pw.SizedBox(height: 20),
          pw.Text('Spending Forecast',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          buildForecastLine(),
          pw.SizedBox(height: 20),
          pw.Text('Savings Plan',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          buildSavingsSection(),
        ],
      ),
    );

    return pdf;
  }

  static Future<pw.PageTheme> _theme() async {
    return pw.PageTheme(
      margin: const pw.EdgeInsets.all(24),
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.robotoRegular(),
        bold: await PdfGoogleFonts.robotoBold(),
      ),
    );
  }
}
