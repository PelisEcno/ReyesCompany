import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'guardar_archivo.dart';

class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  static const String _mimeExcel = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  Future<void> exportarResumen({
    required DateTime             fecha,
    required String               formato,
    String?                       sucursalNombre,
    required Map<String, dynamic> data,
    String?                       idSucursal,
    bool                          mensual = false,
  }) async {
    if (formato == 'PDF') {
      await _generarPDF(fecha: fecha, sucursalNombre: sucursalNombre, data: data, mensual: mensual);
    } else {
      await _generarExcel(fecha: fecha, sucursalNombre: sucursalNombre, data: data, mensual: mensual);
    }
  }

  Future<void> exportarTabla({
    required String             titulo,
    required String             subtitulo,
    required List<String>       encabezados,
    required List<List<Object>> filas,
    required String             formato,
    required String             nombreArchivo,
  }) async {
    if (formato == 'PDF') {
      await _tablaPDF(titulo, subtitulo, encabezados, filas, nombreArchivo);
    } else {
      await _tablaExcel(titulo, subtitulo, encabezados, filas, nombreArchivo);
    }
  }

  Future<void> _tablaPDF(String titulo, String subtitulo, List<String> encabezados,
      List<List<Object>> filas, String nombreArchivo) async {
    final azul  = PdfColor.fromHex('2563EB');
    final gris  = PdfColor.fromHex('64748B');
    final borde = PdfColor.fromHex('E2E8F0');
    final fondo = PdfColor.fromHex('F1F5F9');

    final doc    = pw.Document();
    final fuente = await PdfGoogleFonts.nunitoRegular();
    final negrita = await PdfGoogleFonts.nunitoBold();

    final alineaciones = <int, pw.Alignment>{};
    for (int c = 0; c < encabezados.length; c++) {
      final esNumero = filas.isNotEmpty && filas.first.length > c && filas.first[c] is num;
      alineaciones[c] = esNumero ? pw.Alignment.centerRight : pw.Alignment.centerLeft;
    }

    doc.addPage(pw.MultiPage(
      pageFormat: encabezados.length > 6 ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
      margin:     const pw.EdgeInsets.all(32),
      theme:      pw.ThemeData.withFont(base: fuente, bold: negrita),
      build: (contexto) => [
        pw.Container(
          padding: const pw.EdgeInsets.all(18),
          decoration: pw.BoxDecoration(
            color:        azul,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(titulo, style: pw.TextStyle(font: negrita, fontSize: 18, color: PdfColors.white)),
                pw.SizedBox(height: 4),
                pw.Text(subtitulo, style: pw.TextStyle(fontSize: 11, color: PdfColor.fromHex('CBD5E1'))),
              ]),
              pw.Text('ReyesCompany', style: pw.TextStyle(font: negrita, fontSize: 13, color: PdfColors.white)),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          context:           contexto,
          headers:           encabezados,
          data:              filas.map((f) => f.map(_textoCelda).toList()).toList(),
          headerStyle:       pw.TextStyle(font: negrita, fontSize: 9, color: PdfColors.white),
          headerDecoration:  pw.BoxDecoration(color: azul),
          cellStyle:         const pw.TextStyle(fontSize: 9),
          cellAlignments:    alineaciones,
          oddRowDecoration:  pw.BoxDecoration(color: fondo),
          border:            pw.TableBorder.all(color: borde, width: 0.5),
          cellPadding:       const pw.EdgeInsets.all(6),
        ),
        pw.SizedBox(height: 12),
        pw.Text('Total de registros: ${filas.length}   ·   Generado el ${_labelFechaCompleta(DateTime.now())}',
            style: pw.TextStyle(fontSize: 9, color: gris)),
      ],
    ));

    await Printing.sharePdf(bytes: await doc.save(), filename: '$nombreArchivo.pdf');
  }

  Future<void> _tablaExcel(String titulo, String subtitulo, List<String> encabezados,
      List<List<Object>> filas, String nombreArchivo) async {
    final excel = Excel.createExcel();
    final hoja  = excel['Datos'];
    excel.setDefaultSheet('Datos');
    excel.delete('Sheet1');

    final estiloTitulo = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('2563EB'),
      fontColorHex: ExcelColor.fromHexString('FFFFFF'),
      fontSize: 13,
    );
    final estiloCab = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('F1F5F9'),
      fontColorHex: ExcelColor.fromHexString('0F172A'),
    );

    hoja.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('ReyesCompany – $titulo');
    hoja.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = estiloTitulo;
    hoja.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: encabezados.length - 1, rowIndex: 0),
    );
    hoja.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = TextCellValue(subtitulo);

    for (int c = 0; c < encabezados.length; c++) {
      final celda = hoja.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3));
      celda.value = TextCellValue(encabezados[c]);
      celda.cellStyle = estiloCab;
    }

    for (int f = 0; f < filas.length; f++) {
      for (int c = 0; c < filas[f].length; c++) {
        final valor = filas[f][c];
        final celda = hoja.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 4 + f));
        if (valor is int) {
          celda.value = IntCellValue(valor);
        } else if (valor is double) {
          celda.value = DoubleCellValue(valor);
        } else {
          celda.value = TextCellValue(valor.toString());
        }
      }
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('Error al generar el archivo Excel');
    await guardarArchivo(bytes, '$nombreArchivo.xlsx', _mimeExcel);
  }

  Future<void> _generarPDF({
    required DateTime             fecha,
    String?                       sucursalNombre,
    required Map<String, dynamic> data,
    required bool                 mensual,
  }) async {
    final azul    = PdfColor.fromHex('2563EB');
    final gris    = PdfColor.fromHex('64748B');
    final borde   = PdfColor.fromHex('E2E8F0');
    final verde   = PdfColor.fromHex('059669');
    final naranja = PdfColor.fromHex('D97706');
    final fondo   = PdfColor.fromHex('F1F5F9');

    final doc    = pw.Document();
    final fuente = await PdfGoogleFonts.nunitoRegular();
    final fNegri = await PdfGoogleFonts.nunitoBold();

    final totalDia     = _dbl(data, 'total_dia');
    final totalVentas  = _dbl(data, 'total_ventas');
    final totalAbonos  = _dbl(data, 'total_abonos');
    final totalFiados  = _dbl(data, 'total_fiados');
    final cantVentas   = _int(data, 'cantidad_ventas');
    final cantAbonos   = _int(data, 'cantidad_abonos');
    final cantFiados   = _int(data, 'cantidad_fiados');
    final metodos      = (data['ventas_por_metodo']  as List?) ?? [];
    final productos    = (data['productos_vendidos'] as List?) ?? [];
    final dias         = (data['por_dia']            as List?) ?? [];

    final tituloResumen = mensual ? 'Resumen del mes' : 'Resumen del día';
    final etiquetaTotal = mensual ? 'Total del mes' : 'Total del día';
    final periodo       = mensual ? _labelMes(fecha) : _labelFecha(fecha);

    doc.addPage(pw.MultiPage(
      pageFormat:   PdfPageFormat.a4,
      margin:       const pw.EdgeInsets.all(36),
      theme:        pw.ThemeData.withFont(base: fuente, bold: fNegri),
      build: (ctx) => [
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
                pw.Text(tituloResumen,
                    style: pw.TextStyle(font: fNegri, fontSize: 20, color: PdfColors.white)),
                pw.SizedBox(height: 4),
                pw.Text(periodo,
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
                pw.Text(etiquetaTotal,
                    style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('CBD5E1'))),
                pw.Text('\$${_fmt(totalDia)}',
                    style: pw.TextStyle(font: fNegri, fontSize: 22, color: PdfColors.white)),
              ]),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

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
              ...metodos.map((m) {
                final sub  = _dbl(m as Map, 'subtotal');
                final cant = _int(m, 'cantidad');
                final pct  = totalVentas > 0 ? (sub / totalVentas * 100) : 0;
                return pw.TableRow(children: [
                  _celda(m['metodo']?.toString() ?? ''),
                  _celda('$cant'),
                  _celda('\$${_fmt(sub)}'),
                  _celda('${pct.toStringAsFixed(0)}%'),
                ]);
              }),
            ],
          ),
          pw.SizedBox(height: 20),
        ],

        if (mensual && dias.isNotEmpty) ...[
          pw.Text('Ventas por día',
              style: pw.TextStyle(font: fNegri, fontSize: 13)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: borde, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: fondo),
                children: ['Fecha', 'Ventas', 'Total']
                    .map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(h,
                      style: pw.TextStyle(font: fNegri, fontSize: 10, color: gris)),
                ))
                    .toList(),
              ),
              ...dias.map((d) => pw.TableRow(children: [
                _celda(d['fecha']?.toString() ?? ''),
                _celda('${_int(d as Map, 'cantidad')}'),
                _celda('\$${_fmt(_dbl(d, 'total'))}'),
              ])),
            ],
          ),
          pw.SizedBox(height: 20),
        ],

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
                    _celda('${i + 1}'),
                    _celda(p['nombre']?.toString() ?? ''),
                    _celda('${_int(p, 'cantidad')}'),
                    _celda('\$${_fmt(_dbl(p, 'total'))}'),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 20),
        ],

        pw.Divider(color: borde),
        pw.SizedBox(height: 6),
        pw.Text('Generado el ${_labelFechaCompleta(DateTime.now())}',
            style: pw.TextStyle(fontSize: 9, color: gris)),
      ],
    ));

    await Printing.sharePdf(
      bytes:    await doc.save(),
      filename: '${_nombreResumen(fecha, mensual)}.pdf',
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

  pw.Widget _celda(String texto) => pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child:   pw.Text(texto, style: pw.TextStyle(fontSize: 10)),
  );

  Future<void> _generarExcel({
    required DateTime             fecha,
    String?                       sucursalNombre,
    required Map<String, dynamic> data,
    required bool                 mensual,
  }) async {
    final excel = Excel.createExcel();

    final sheet1 = excel['Resumen'];
    excel.setDefaultSheet('Resumen');
    excel.delete('Sheet1');

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

    final periodo = mensual ? _labelMes(fecha) : _labelFecha(fecha);

    sheet1.cell(CellIndex.indexByString('A1')).value = TextCellValue(mensual ? 'ReyesCompany – Resumen del mes' : 'ReyesCompany – Resumen del día');
    sheet1.cell(CellIndex.indexByString('A1')).cellStyle = estiloTitulo;
    sheet1.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('D1'));

    sheet1.cell(CellIndex.indexByString('A2')).value = TextCellValue(periodo);
    if (sucursalNombre != null && sucursalNombre.isNotEmpty) {
      sheet1.cell(CellIndex.indexByString('B2')).value = TextCellValue(sucursalNombre);
    }

    sheet1.cell(CellIndex.indexByString('A4')).value = TextCellValue('Concepto');
    sheet1.cell(CellIndex.indexByString('B4')).value = TextCellValue('Monto');
    sheet1.cell(CellIndex.indexByString('C4')).value = TextCellValue('Cantidad');
    sheet1.cell(CellIndex.indexByString('A4')).cellStyle = estiloCab;
    sheet1.cell(CellIndex.indexByString('B4')).cellStyle = estiloCab;
    sheet1.cell(CellIndex.indexByString('C4')).cellStyle = estiloCab;

    final filas = [
      [mensual ? 'Total del mes' : 'Total del día', _dbl(data, 'total_dia'), null],
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

    final dias = (data['por_dia'] as List?) ?? [];
    if (mensual && dias.isNotEmpty) {
      final sheetDias = excel['Ventas por día'];
      sheetDias.cell(CellIndex.indexByString('A1')).value = TextCellValue('Fecha');
      sheetDias.cell(CellIndex.indexByString('B1')).value = TextCellValue('Ventas');
      sheetDias.cell(CellIndex.indexByString('C1')).value = TextCellValue('Total');
      for (final col in ['A1', 'B1', 'C1']) {
        sheetDias.cell(CellIndex.indexByString(col)).cellStyle = estiloCab;
      }

      for (int i = 0; i < dias.length; i++) {
        final d   = dias[i] as Map;
        final row = 2 + i;
        sheetDias.cell(CellIndex.indexByString('A$row')).value = TextCellValue(d['fecha']?.toString() ?? '');
        sheetDias.cell(CellIndex.indexByString('B$row')).value = IntCellValue(_int(d, 'cantidad'));
        sheetDias.cell(CellIndex.indexByString('C$row')).value = DoubleCellValue(_dbl(d, 'total'));
      }
    }

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

    final bytes = excel.save();
    if (bytes == null) throw Exception('Error al generar el archivo Excel');
    await guardarArchivo(bytes, '${_nombreResumen(fecha, mensual)}.xlsx', _mimeExcel);
  }

  double _dbl(Map d, String k) => (d[k] as num?)?.toDouble() ?? 0;
  int    _int(Map d, String k) => (d[k] as num?)?.toInt()    ?? 0;

  String _nombreResumen(DateTime fecha, bool mensual) {
    final mes = fecha.month.toString().padLeft(2, '0');
    if (mensual) return 'resumen_mensual_${fecha.year}-$mes';
    return 'resumen_${_dateToStr(fecha)}';
  }

  String _dateToStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _labelFecha(DateTime f) {
    const m = ['','Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${f.day} ${m[f.month]} ${f.year}';
  }

  String _labelMes(DateTime f) {
    const m = ['','Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
    return '${m[f.month]} ${f.year}';
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

  String _textoCelda(Object valor) {
    if (valor is num) return _miles(valor);
    return valor.toString();
  }

  String _miles(num valor) {
    final texto = valor.round().toString();
    final resultado = StringBuffer();
    for (int i = 0; i < texto.length; i++) {
      if (i > 0 && (texto.length - i) % 3 == 0) resultado.write('.');
      resultado.write(texto[i]);
    }
    return resultado.toString();
  }
}
