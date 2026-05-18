// export_service.dart
// Genera y comparte el resumen del día en PDF o Excel.
//
// Añade en pubspec.yaml (bajo dependencies):
//   pdf: ^3.11.1
//   printing: ^5.13.1
//   excel: ^4.0.3
//   path_provider: ^2.1.4
//   share_plus: ^10.0.2

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  // ── Punto de entrada público ─────────────────────────────────────────────
  Future<void> exportarResumen({
    required DateTime             fecha,
    required String               formato,  // 'PDF' | 'Excel'
    String?                       sucursalNombre,
    required Map<String, dynamic> data, String? idSucursal,
  }) async {
    if (formato == 'PDF') {
      await _generarPDF(fecha: fecha, sucursalNombre: sucursalNombre, data: data);
    } else {
      await _generarExcel(fecha: fecha, sucursalNombre: sucursalNombre, data: data);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PDF
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _generarPDF({
    required DateTime             fecha,
    String?                       sucursalNombre,
    required Map<String, dynamic> data,
  }) async {
    // Colores de la app
    final azul    = PdfColor.fromHex('2563EB');
    final gris    = PdfColor.fromHex('64748B');
    final borde   = PdfColor.fromHex('E2E8F0');
    final verde   = PdfColor.fromHex('059669');
    final naranja = PdfColor.fromHex('D97706');
    final fondo   = PdfColor.fromHex('F1F5F9');

    final doc    = pw.Document();
    final fuente = await PdfGoogleFonts.nunitoRegular();
    final fNegri = await PdfGoogleFonts.nunitoBold();

    // Datos del resumen
    final totalDia     = _dbl(data, 'total_dia');
    final totalVentas  = _dbl(data, 'total_ventas');
    final totalAbonos  = _dbl(data, 'total_abonos');
    final totalFiados  = _dbl(data, 'total_fiados');
    final cantVentas   = _int(data, 'cantidad_ventas');
    final cantAbonos   = _int(data, 'cantidad_abonos');
    final cantFiados   = _int(data, 'cantidad_fiados');
    final metodos      = (data['ventas_por_metodo']  as List?) ?? [];
    final productos    = (data['productos_vendidos'] as List?) ?? [];

    doc.addPage(pw.MultiPage(
      pageFormat:   PdfPageFormat.a4,
      margin:       const pw.EdgeInsets.all(36),
      theme:        pw.ThemeData.withFont(base: fuente, bold: fNegri),
      build: (ctx) => [

        // ── Encabezado ────────────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color:        azul,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Resumen del día',
                    style: pw.TextStyle(font: fNegri, fontSize: 20, color: PdfColors.white)),
                pw.SizedBox(height: 4),
                pw.Text(_labelFecha(fecha),
                    style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex('CBD5E1'))),
                if (sucursalNombre != null && sucursalNombre.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(sucursalNombre,
                      style: pw.TextStyle(fontSize: 11, color: PdfColor.fromHex('93C5FD'))),
                ],
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('ReyesCompany',
                    style: pw.TextStyle(font: fNegri, fontSize: 13, color: PdfColors.white)),
                pw.SizedBox(height: 4),
                pw.Text('Total del día',
                    style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('CBD5E1'))),
                pw.Text('\$${_fmt(totalDia)}',
                    style: pw.TextStyle(font: fNegri, fontSize: 22, color: PdfColors.white)),
              ]),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // ── Métricas principales ──────────────────────────────────────────
        pw.Row(children: [
          _pdfMetrica(fNegri, 'Ventas contado', totalVentas, '$cantVentas transac.', azul),
          pw.SizedBox(width: 10),
          _pdfMetrica(fNegri, 'Cobros fiados',  totalAbonos, '$cantAbonos pagos',   verde),
          if (cantFiados > 0) ...[
            pw.SizedBox(width: 10),
            _pdfMetrica(fNegri, 'Fiados generados', totalFiados, '$cantFiados créd.', naranja),
          ],
        ]),

        pw.SizedBox(height: 20),

        // ── Métodos de pago ───────────────────────────────────────────────
        if (metodos.isNotEmpty) ...[
          pw.Text('Desglose por método de pago',
              style: pw.TextStyle(font: fNegri, fontSize: 13)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: borde, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: [
              // Cabecera
              pw.TableRow(
                decoration: pw.BoxDecoration(color: fondo),
                children: ['Método', 'Ventas', 'Subtotal', '%']
                    .map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(h,
                      style: pw.TextStyle(font: fNegri, fontSize: 10, color: gris)),
                ))
                    .toList(),
              ),
              // Filas
              ...metodos.map((m) {
                final sub  = _dbl(m as Map, 'subtotal');
                final cant = _int(m, 'cantidad');
                final pct  = totalVentas > 0 ? (sub / totalVentas * 100) : 0;
                return pw.TableRow(children: [
                  _celda(m['metodo']?.toString() ?? '', fNegri),
                  _celda('$cant', fNegri),
                  _celda('\$${_fmt(sub)}', fNegri),
                  _celda('${pct.toStringAsFixed(0)}%', fNegri),
                ]);
              }),
            ],
          ),
          pw.SizedBox(height: 20),
        ],

        // ── Productos vendidos ────────────────────────────────────────────
        if (productos.isNotEmpty) ...[
          pw.Text('Productos vendidos',
              style: pw.TextStyle(font: fNegri, fontSize: 13)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: borde, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(28),
              1: const pw.FlexColumnWidth(4),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: fondo),
                children: ['#', 'Producto', 'Cant.', 'Total']
                    .map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(h,
                      style: pw.TextStyle(font: fNegri, fontSize: 10, color: gris)),
                ))
                    .toList(),
              ),
              ...productos.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value as Map;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: i.isOdd ? fondo : PdfColors.white),
                  children: [
                    _celda('${i + 1}', fNegri),
                    _celda(p['nombre']?.toString() ?? '', fNegri),
                    _celda('${_int(p, 'cantidad')}', fNegri),
                    _celda('\$${_fmt(_dbl(p, 'total'))}', fNegri),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 20),
        ],

        // ── Pie ───────────────────────────────────────────────────────────
        pw.Divider(color: borde),
        pw.SizedBox(height: 6),
        pw.Text('Generado el ${_labelFechaCompleta(DateTime.now())}',
            style: pw.TextStyle(fontSize: 9, color: gris)),
      ],
    ));

    // Compartir / imprimir
    await Printing.sharePdf(
      bytes:    await doc.save(),
      filename: 'resumen_${_dateToStr(fecha)}.pdf',
    );
  }

  pw.Widget _pdfMetrica(pw.Font fNegri, String label, double valor,
      String sub, PdfColor color) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            border:       pw.Border.all(color: color, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('64748B'))),
            pw.SizedBox(height: 4),
            pw.Text('\$${_fmt(valor)}',
                style: pw.TextStyle(font: fNegri, fontSize: 16, color: color)),
            pw.Text(sub, style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('64748B'))),
          ]),
        ),
      );

  pw.Widget _celda(String texto, pw.Font fNegri) => pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child:   pw.Text(texto, style: pw.TextStyle(fontSize: 10)),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // EXCEL
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _generarExcel({
    required DateTime             fecha,
    String?                       sucursalNombre,
    required Map<String, dynamic> data,
  }) async {
    final excel = Excel.createExcel();

    // ── Hoja 1: Resumen ───────────────────────────────────────────────────
    final sheet1 = excel['Resumen'];
    excel.setDefaultSheet('Resumen');

    final estiloTitulo = CellStyle(
      bold:            true,
      backgroundColorHex: ExcelColor.fromHexString('2563EB'),
      fontColorHex:    ExcelColor.fromHexString('FFFFFF'),
      fontSize:        13,
    );
    final estiloCab = CellStyle(
      bold:            true,
      backgroundColorHex: ExcelColor.fromHexString('F1F5F9'),
      fontColorHex:    ExcelColor.fromHexString('0F172A'),
    );

    // Título
    sheet1.cell(CellIndex.indexByString('A1')).value = TextCellValue('ReyesCompany – Resumen del día');
    sheet1.cell(CellIndex.indexByString('A1')).cellStyle = estiloTitulo;
    sheet1.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('D1'));

    sheet1.cell(CellIndex.indexByString('A2')).value = TextCellValue(_labelFecha(fecha));
    if (sucursalNombre != null && sucursalNombre.isNotEmpty) {
      sheet1.cell(CellIndex.indexByString('B2')).value = TextCellValue(sucursalNombre);
    }

    // Métricas
    sheet1.cell(CellIndex.indexByString('A4')).value = TextCellValue('Concepto');
    sheet1.cell(CellIndex.indexByString('B4')).value = TextCellValue('Monto');
    sheet1.cell(CellIndex.indexByString('C4')).value = TextCellValue('Cantidad');
    sheet1.cell(CellIndex.indexByString('A4')).cellStyle = estiloCab;
    sheet1.cell(CellIndex.indexByString('B4')).cellStyle = estiloCab;
    sheet1.cell(CellIndex.indexByString('C4')).cellStyle = estiloCab;

    final filas = [
      ['Total del día',       _dbl(data, 'total_dia'),     null],
      ['Ventas contado',      _dbl(data, 'total_ventas'),  _int(data, 'cantidad_ventas')],
      ['Cobros fiados',       _dbl(data, 'total_abonos'),  _int(data, 'cantidad_abonos')],
      ['Fiados generados',    _dbl(data, 'total_fiados'),  _int(data, 'cantidad_fiados')],
    ];

    for (int i = 0; i < filas.length; i++) {
      final f = filas[i];
      final row = 5 + i;
      sheet1.cell(CellIndex.indexByString('A$row')).value = TextCellValue(f[0] as String);
      sheet1.cell(CellIndex.indexByString('B$row')).value = DoubleCellValue(f[1] as double);
      if (f[2] != null) {
        sheet1.cell(CellIndex.indexByString('C$row')).value = IntCellValue(f[2] as int);
      }
    }

    // ── Hoja 2: Métodos de pago ───────────────────────────────────────────
    final metodos = (data['ventas_por_metodo'] as List?) ?? [];
    if (metodos.isNotEmpty) {
      final sheet2 = excel['Métodos de pago'];
      sheet2.cell(CellIndex.indexByString('A1')).value = TextCellValue('Método');
      sheet2.cell(CellIndex.indexByString('B1')).value = TextCellValue('Ventas');
      sheet2.cell(CellIndex.indexByString('C1')).value = TextCellValue('Subtotal');
      sheet2.cell(CellIndex.indexByString('A1')).cellStyle = estiloCab;
      sheet2.cell(CellIndex.indexByString('B1')).cellStyle = estiloCab;
      sheet2.cell(CellIndex.indexByString('C1')).cellStyle = estiloCab;

      for (int i = 0; i < metodos.length; i++) {
        final m   = metodos[i] as Map;
        final row = 2 + i;
        sheet2.cell(CellIndex.indexByString('A$row')).value = TextCellValue(m['metodo']?.toString() ?? '');
        sheet2.cell(CellIndex.indexByString('B$row')).value = IntCellValue(_int(m, 'cantidad'));
        sheet2.cell(CellIndex.indexByString('C$row')).value = DoubleCellValue(_dbl(m, 'subtotal'));
      }
    }

    // ── Hoja 3: Productos vendidos ────────────────────────────────────────
    final productos = (data['productos_vendidos'] as List?) ?? [];
    if (productos.isNotEmpty) {
      final sheet3 = excel['Productos vendidos'];
      sheet3.cell(CellIndex.indexByString('A1')).value = TextCellValue('#');
      sheet3.cell(CellIndex.indexByString('B1')).value = TextCellValue('Producto');
      sheet3.cell(CellIndex.indexByString('C1')).value = TextCellValue('Cantidad');
      sheet3.cell(CellIndex.indexByString('D1')).value = TextCellValue('Total');
      for (final col in ['A1','B1','C1','D1']) {
        sheet3.cell(CellIndex.indexByString(col)).cellStyle = estiloCab;
      }

      for (int i = 0; i < productos.length; i++) {
        final p   = productos[i] as Map;
        final row = 2 + i;
        sheet3.cell(CellIndex.indexByString('A$row')).value = IntCellValue(i + 1);
        sheet3.cell(CellIndex.indexByString('B$row')).value = TextCellValue(p['nombre']?.toString() ?? '');
        sheet3.cell(CellIndex.indexByString('C$row')).value = IntCellValue(_int(p, 'cantidad'));
        sheet3.cell(CellIndex.indexByString('D$row')).value = DoubleCellValue(_dbl(p, 'total'));
      }
    }

    // Guardar y compartir
    final bytes = excel.save();
    if (bytes == null) throw Exception('Error al generar el archivo Excel');

    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/resumen_${_dateToStr(fecha)}.xlsx');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'Resumen ${_labelFecha(fecha)}',
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  double _dbl(Map d, String k) => (d[k] as num?)?.toDouble() ?? 0;
  int    _int(Map d, String k) => (d[k] as num?)?.toInt()    ?? 0;

  String _dateToStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _labelFecha(DateTime f) {
    const m = ['','Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${f.day} ${m[f.month]} ${f.year}';
  }

  String _labelFechaCompleta(DateTime f) {
    final h   = f.hour.toString().padLeft(2, '0');
    final min = f.minute.toString().padLeft(2, '0');
    return '${_labelFecha(f)} a las $h:$min';
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}