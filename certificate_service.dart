import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class CertificateService {
  static Future<void> generateCertificate({
    required String studentName,
    required String mentorName,
    required String courseTitle,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.amber800, width: 5),
            ),
            child: pw.Container(
              padding: const pw.EdgeInsets.all(30),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.amber400, width: 2),
              ),
              child: pw.Stack(
                children: [
                  // Decorative Corner
                  pw.Positioned(
                    top: -10, right: -10,
                    child: pw.Icon(const pw.IconData(0xe838), color: PdfColors.amber100, size: 100),
                  ),
                  
                  pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        'UNIVERSITY MENTORSHIP PLATFORM',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700, letterSpacing: 2),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Divider(color: PdfColors.amber200, thickness: 1, indent: 150, endIndent: 150),
                      pw.SizedBox(height: 25),
                      
                      pw.Text(
                        'CERTIFICATE OF COMPLETION',
                        style: pw.TextStyle(fontSize: 38, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.SizedBox(height: 20),
                      
                      // FIXED: Removed const from TextStyle to avoid fontStyle error
                      pw.Text('This prestigious award is presented to', style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic)),
                      pw.SizedBox(height: 15),
                      
                      pw.Text(
                        studentName.toUpperCase(),
                        style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.black, letterSpacing: 1.5),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Container(width: 300, height: 2, color: PdfColors.amber800),
                      pw.SizedBox(height: 20),
                      
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 60),
                        child: pw.Text(
                          'For successfully fulfilling all academic requirements and demonstrating exceptional skill in the professional mentorship program.',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
                        ),
                      ),
                      
                      pw.SizedBox(height: 20),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text('Specialization in: ', style: const pw.TextStyle(fontSize: 14)),
                          pw.Text(
                            courseTitle,
                            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700),
                          ),
                        ],
                      ),
                      
                      pw.SizedBox(height: 50),
                      
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: [
                          pw.Column(
                            children: [
                              pw.Text(
                                mentorName,
                                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                              ),
                              pw.Container(width: 150, height: 1, color: PdfColors.grey400, margin: const pw.EdgeInsets.symmetric(vertical: 5)),
                              pw.Text('Assigned Mentor', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                            ],
                          ),
                          
                          pw.Container(
                            width: 60, height: 60,
                            decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: PdfColors.amber50),
                            child: pw.Center(child: pw.Icon(const pw.IconData(0xe838), color: PdfColors.amber800, size: 30)),
                          ),
                          
                          pw.Column(
                            children: [
                              pw.Text(
                                DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                              ),
                              pw.Container(width: 150, height: 1, color: PdfColors.grey400, margin: const pw.EdgeInsets.symmetric(vertical: 5)),
                              pw.Text('Date of Achievement', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Mentorship_Certificate_${studentName.replaceAll(" ", "_")}.pdf',
    );
  }
}