// modulo_resumen_diario.dart
// CU03 – Generar resumen diario
// Acceso: Administrador y Empleado

import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/export_service.dart';

// ── Paleta (igual que dashboard) ────────────────────────────────────────────
const _cAccent  = Color(0xFF2563EB);
const _cGreen   = Color(0xFF059669);
const _cOrange  = Color(0xFFD97706);
const _cRed     = Color(0xFFDC2626);
const _cBg      = Color(0xFFF1F5F9);
const _cWhite   = Color(0xFFFFFFFF);
const _cBorder  = Color(0xFFE2E8F0);
const _cText    = Color(0xFF0F172A);
const _cSubtext = Color(0xFF64748B);

// ── Widget principal ─────────────────────────────────────────────────────────
class ModuloResumenDiario extends StatefulWidget {
  final String idUsuario;
  final String? idSucursal;
  final String sucursalNombre;

  const ModuloResumenDiario({
    super.key,
    required this.idUsuario,
    this.idSucursal,
    this.sucursalNombre = '',
  });

  @override
  State<ModuloResumenDiario> createState() => _ModuloResumenDiarioState();
}

class _ModuloResumenDiarioState extends State<ModuloResumenDiario> {
  final _svc = DatabaseService();

  DateTime _fechaSeleccionada = DateTime.now();
  bool     _cargando          = true;
  bool     _exportando        = false;
  bool     _mensual           = false;
  Map<String, dynamic> _data  = {};
  Timer?   _refresco;

  @override
  void initState() {
    super.initState();
    _cargar();
    _refresco = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_esPeriodoActual) _cargar(silencioso: true);
    });
  }

  @override
  void dispose() {
    _refresco?.cancel();
    super.dispose();
  }

  bool get _esPeriodoActual {
    final hoy = DateTime.now();
    if (_mensual) return _fechaSeleccionada.year == hoy.year && _fechaSeleccionada.month == hoy.month;
    return _esHoy(_fechaSeleccionada);
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!silencioso) setState(() => _cargando = true);
    try {
      final d = _mensual
          ? await _svc.getResumenRango(
              desde:      DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month, 1),
              hasta:      DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month + 1, 0),
              idSucursal: widget.idSucursal,
            )
          : await _svc.getResumenFecha(
              fecha:      _fechaSeleccionada,
              idSucursal: widget.idSucursal,
            );
      if (!mounted) return;
      setState(() => _data = d);
    } catch (_) {
      if (mounted && !silencioso) setState(() => _data = {});
    } finally {
      if (mounted && !silencioso) setState(() => _cargando = false);
    }
  }

  void _cambiarModo(bool mensual) {
    if (_mensual == mensual) return;
    setState(() => _mensual = mensual);
    _cargar();
  }

  void _moverMes(int delta) {
    setState(() => _fechaSeleccionada = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month + delta, 1));
    _cargar();
  }

  bool get _puedeAvanzarMes {
    final hoy = DateTime.now();
    return _fechaSeleccionada.year * 12 + _fechaSeleccionada.month < hoy.year * 12 + hoy.month;
  }

  // ── Selector de fecha ───────────────────────────────────────────────────────
  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context:      context,
      initialDate:  _fechaSeleccionada,
      firstDate:    DateTime(2020),
      lastDate:     DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _cAccent),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() => _fechaSeleccionada = picked);
      await _cargar();
    }
  }

  // ── Exportación ─────────────────────────────────────────────────────────────
  Future<void> _exportar(String formato) async {
    Navigator.pop(context); // cierra bottom-sheet
    setState(() => _exportando = true);
    try {
      await ExportService.instance.exportarResumen(
        fecha:      _fechaSeleccionada,
        formato: formato, sucursalNombre: widget.sucursalNombre,         // 'PDF' | 'Excel'
        idSucursal: widget.idSucursal,
        data:       _data,
        mensual:    _mensual,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Resumen exportado como $formato ✓'),
        backgroundColor: _cGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al exportar: $e'),
        backgroundColor: _cRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  void _mostrarExportacion() {
    showModalBottomSheet(
      context:             context,
      backgroundColor:     Colors.transparent,
      isScrollControlled:  true,
      builder: (_) => _BottomSheetExportacion(onExportar: _exportar),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      body: Column(children: [
        _encabezado(),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator(color: _cAccent))
              : RefreshIndicator(
            onRefresh: _cargar,
            color:     _cAccent,
            child:     _cuerpo(),
          ),
        ),
      ]),
    );
  }

  // ── Encabezado con selector de fecha y botón exportar ───────────────────────
  Widget _encabezado() => Container(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
    decoration: const BoxDecoration(
      color:  _cWhite,
      border: Border(bottom: BorderSide(color: _cBorder)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _toggleModo(),
        const Spacer(),
        _exportando
            ? const SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: _cAccent))
            : ElevatedButton.icon(
          onPressed: _mostrarExportacion,
          icon:      const Icon(Icons.download_rounded, size: 16),
          label:     const Text('Exportar', style: TextStyle(fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _cAccent,
            foregroundColor: Colors.white,
            padding:         const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation:       0,
          ),
        ),
      ]),
      const SizedBox(height: 12),
      _mensual ? _selectorMes() : _selectorDia(),
    ]),
  );

  Widget _toggleModo() => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color:        _cBg,
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: _cBorder),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      _opcionModo('Día', !_mensual, () => _cambiarModo(false)),
      _opcionModo('Mes', _mensual, () => _cambiarModo(true)),
    ]),
  );

  Widget _opcionModo(String texto, bool activo, VoidCallback alTocar) => GestureDetector(
    onTap: alTocar,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color:        activo ? _cAccent : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(texto,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: activo ? Colors.white : _cSubtext)),
    ),
  );

  Widget _selectorDia() => GestureDetector(
    onTap: _seleccionarFecha,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        _cBg,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: _cBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.calendar_today_rounded, size: 15, color: _cAccent),
        const SizedBox(width: 8),
        Text(_labelFecha(_fechaSeleccionada),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _cText)),
        const SizedBox(width: 6),
        const Icon(Icons.expand_more_rounded, size: 16, color: _cSubtext),
      ]),
    ),
  );

  Widget _selectorMes() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color:        _cBg,
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: _cBorder),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        onPressed: () => _moverMes(-1),
        icon: const Icon(Icons.chevron_left_rounded, color: _cAccent),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(_labelMes(_fechaSeleccionada),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _cText)),
      ),
      IconButton(
        onPressed: _puedeAvanzarMes ? () => _moverMes(1) : null,
        icon: Icon(Icons.chevron_right_rounded, color: _puedeAvanzarMes ? _cAccent : _cBorder),
      ),
    ]),
  );

  // ── Cuerpo principal ────────────────────────────────────────────────────────
  Widget _cuerpo() {
    final totalVentas  = _num('total_ventas');
    final totalAbonos  = _num('total_abonos');
    final totalDia     = _num('total_dia');
    final totalFiados  = _num('total_fiados');
    final cantVentas   = _int('cantidad_ventas');
    final cantAbonos   = _int('cantidad_abonos');
    final cantFiados   = _int('cantidad_fiados');
    final metodos      = (_data['ventas_por_metodo'] as List?) ?? [];
    final productos    = (_data['productos_vendidos'] as List?) ?? [];
    final sinDatos     = totalDia == 0 && metodos.isEmpty && cantVentas == 0;

    if (sinDatos) return _sinDatos();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Tarjeta hero ─────────────────────────────────────────────────────
        _cardHero(totalDia, totalVentas, totalAbonos, totalFiados,
            cantVentas, cantAbonos, cantFiados),
        const SizedBox(height: 20),

        // ── Métricas rápidas ─────────────────────────────────────────────────
        Row(children: [
          _metrica('\$${_fmt(totalVentas)}', 'Ventas contado', '$cantVentas transac.',
              Icons.point_of_sale_rounded, _cAccent),
          const SizedBox(width: 12),
          _metrica('\$${_fmt(totalAbonos)}', 'Cobros fiados', '$cantAbonos pagos',
              Icons.payments_rounded, _cGreen),
          const SizedBox(width: 12),
          _metrica('\$${_fmt(totalFiados)}', 'Fiados generados', '$cantFiados créditos',
              Icons.handshake_rounded, _cOrange),
        ]),
        const SizedBox(height: 20),

        // ── Métodos de pago ──────────────────────────────────────────────────
        if (metodos.isNotEmpty) ...[
          _labelSeccion('Desglose por método de pago'),
          const SizedBox(height: 10),
          _cardMetodos(metodos, totalVentas),
          const SizedBox(height: 20),
        ],

        if (_mensual && ((_data['por_dia'] as List?) ?? []).isNotEmpty) ...[
          _labelSeccion('Ventas por día'),
          const SizedBox(height: 10),
          _cardDias((_data['por_dia'] as List)),
          const SizedBox(height: 20),
        ],

        // ── Productos más vendidos ───────────────────────────────────────────
        if (productos.isNotEmpty) ...[
          _labelSeccion('Productos vendidos'),
          const SizedBox(height: 10),
          _cardProductos(productos),
          const SizedBox(height: 20),
        ],
      ]),
    );
  }

  // ── Tarjeta hero ─────────────────────────────────────────────────────────────
  Widget _cardHero(double totalDia, double ventas, double abonos, double fiados,
      int cantV, int cantA, int cantF) =>
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors:  [Color(0xFF1E40AF), Color(0xFF1D4ED8), Color(0xFF2563EB)],
            begin:   Alignment.topLeft,
            end:     Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: _cAccent.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_mensual ? 'Total del mes' : 'Total del día',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text(_labelPeriodo(),
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
            const Spacer(),
            if (widget.sucursalNombre.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(widget.sucursalNombre,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
          ]),
          const SizedBox(height: 10),
          Text('\$${_fmt(totalDia)}',
              style: const TextStyle(color: Colors.white, fontSize: 38,
                  fontWeight: FontWeight.w800, letterSpacing: -1.5)),
          const SizedBox(height: 18),
          // Chips de desglose
          LayoutBuilder(builder: (_, c) {
            final chips = [
              _chipHero(Icons.point_of_sale_rounded, 'Ventas', '\$${_fmt(ventas)}', '$cantV operac.'),
              _chipHero(Icons.payments_rounded, 'Cobros', '\$${_fmt(abonos)}', '$cantA abonos'),
              if (cantF > 0)
                _chipHero(Icons.handshake_rounded, 'Fiados', '\$${_fmt(fiados)}', '$cantF créditos'),
            ];
            if (c.maxWidth > 500) {
              return Row(children: chips.map((w) => Expanded(child: Padding(
                  padding: EdgeInsets.only(right: chips.indexOf(w) < chips.length - 1 ? 10 : 0),
                  child: w))).toList());
            }
            return Column(children: [
              Row(children: [Expanded(child: chips[0]), const SizedBox(width: 10), Expanded(child: chips[1])]),
              if (cantF > 0) ...[const SizedBox(height: 10), chips[2]],
            ]);
          }),
        ]),
      );

  Widget _chipHero(IconData icono, String label, String valor, String sub) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icono, color: Colors.white70, size: 16), const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(valor, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            Text(sub, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          ])),
        ]),
      );

  // ── Tarjeta de métodos de pago ────────────────────────────────────────────
  Widget _cardMetodos(List metodos, double totalVentas) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _cardDeco(),
    child: Column(children: List.generate(metodos.length, (i) {
      final m     = metodos[i];
      final sub   = (m['subtotal'] as num?)?.toDouble() ?? 0;
      final pct   = totalVentas > 0 ? sub / totalVentas : 0.0;
      final color = _colorMetodo(m['metodo']?.toString() ?? '');
      final cant  = (m['cantidad'] as num?)?.toInt() ?? 0;
      return Padding(
        padding: EdgeInsets.only(bottom: i < metodos.length - 1 ? 16 : 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(_iconoMetodo(m['metodo']?.toString() ?? ''), color: color, size: 14)),
            const SizedBox(width: 10),
            Expanded(child: Text(m['metodo']?.toString() ?? '',
                style: const TextStyle(color: _cText, fontWeight: FontWeight.w600, fontSize: 13))),
            Text('$cant venta${cant != 1 ? "s" : ""}',
                style: const TextStyle(color: _cSubtext, fontSize: 11)),
            const SizedBox(width: 12),
            Text('\$${_fmt(sub)}',
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value:           pct.clamp(0.0, 1.0),
                minHeight:       5,
                backgroundColor: color.withOpacity(0.08),
                valueColor:      AlwaysStoppedAnimation<Color>(color),
              ),
            )),
            const SizedBox(width: 10),
            Text('${(pct * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: _cSubtext, fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
          if (i < metodos.length - 1) ...[
            const SizedBox(height: 16),
            const Divider(color: _cBorder, height: 1),
          ],
        ]),
      );
    })),
  );

  // ── Tarjeta de productos vendidos ─────────────────────────────────────────
  Widget _cardProductos(List productos) => Container(
    decoration: _cardDeco(),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(children: List.generate(productos.length, (i) {
        final p       = productos[i];
        final nombre  = p['nombre']?.toString() ?? 'Producto';
        final cant    = (p['cantidad'] as num?)?.toInt() ?? 0;
        final total   = (p['total'] as num?)?.toDouble() ?? 0;
        final esImpar = i.isOdd;
        return Column(children: [
          Container(
            color: esImpar ? const Color(0xFFFAFBFF) : _cWhite,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: _cAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('${i + 1}',
                    style: const TextStyle(color: _cAccent, fontWeight: FontWeight.w700, fontSize: 12))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nombre,
                    style: const TextStyle(color: _cText, fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                Text('$cant unidades vendidas',
                    style: const TextStyle(color: _cSubtext, fontSize: 11)),
              ])),
              Text('\$${_fmt(total)}',
                  style: const TextStyle(color: _cAccent, fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
          ),
          if (i < productos.length - 1) const Divider(height: 1, color: _cBorder),
        ]);
      })),
    ),
  );

  // ── Estado vacío ──────────────────────────────────────────────────────────
  Widget _sinDatos() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.bar_chart_rounded, size: 40, color: _cSubtext)),
        const SizedBox(height: 20),
        const Text('Sin datos disponibles',
            style: TextStyle(color: _cText, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('No hay ventas registradas para\n${_labelPeriodo()}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _cSubtext, fontSize: 13)),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _mensual ? () => _moverMes(-1) : _seleccionarFecha,
          icon:      const Icon(Icons.calendar_today_rounded, size: 15),
          label:     Text(_mensual ? 'Mes anterior' : 'Cambiar fecha'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _cAccent,
            side:            const BorderSide(color: _cAccent),
            shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding:         const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ]),
    ),
  );

  Widget _cardDias(List dias) {
    double maximo = 0;
    for (final d in dias) {
      final total = (d['total'] as num?)?.toDouble() ?? 0;
      if (total > maximo) maximo = total;
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDeco(),
      child: Column(children: List.generate(dias.length, (i) {
        final d      = dias[i];
        final total  = (d['total'] as num?)?.toDouble() ?? 0;
        final cant   = (d['cantidad'] as num?)?.toInt() ?? 0;
        final fecha  = DateTime.tryParse(d['fecha']?.toString() ?? '');
        final etiqueta = fecha != null ? '${fecha.day} ${_nombreMesCorto(fecha.month)}' : '';
        return Padding(
          padding: EdgeInsets.only(bottom: i < dias.length - 1 ? 12 : 0),
          child: Row(children: [
            SizedBox(width: 56, child: Text(etiqueta,
                style: const TextStyle(color: _cText, fontWeight: FontWeight.w600, fontSize: 12))),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value:           maximo > 0 ? total / maximo : 0,
                minHeight:       6,
                backgroundColor: _cAccent.withOpacity(0.08),
                valueColor:      const AlwaysStoppedAnimation<Color>(_cAccent),
              ),
            )),
            const SizedBox(width: 10),
            Text('$cant venta${cant != 1 ? "s" : ""}',
                style: const TextStyle(color: _cSubtext, fontSize: 10)),
            const SizedBox(width: 10),
            SizedBox(width: 64, child: Text('\$${_fmt(total)}',
                textAlign: TextAlign.right,
                style: const TextStyle(color: _cAccent, fontWeight: FontWeight.w700, fontSize: 12))),
          ]),
        );
      })),
    );
  }

  String _labelPeriodo() => _mensual ? _labelMes(_fechaSeleccionada) : _labelFecha(_fechaSeleccionada);

  String _labelMes(DateTime f) {
    const m = ['','Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
    return '${m[f.month]} ${f.year}';
  }

  String _nombreMesCorto(int mes) {
    const m = ['','Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return m[mes];
  }

  Widget _metrica(String valor, String label, String sub, IconData icono, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
              child: Icon(icono, color: color, size: 15)),
          const SizedBox(height: 10),
          Text(valor,
              style: const TextStyle(color: _cText, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(color: _cText, fontSize: 11, fontWeight: FontWeight.w500)),
          Text(sub, style: const TextStyle(color: _cSubtext, fontSize: 10)),
        ]),
      ));

  Widget _labelSeccion(String t) =>
      Text(t, style: const TextStyle(color: _cText, fontSize: 14, fontWeight: FontWeight.w700));

  BoxDecoration _cardDeco() => BoxDecoration(
    color:        _cWhite,
    borderRadius: BorderRadius.circular(16),
    border:       Border.all(color: _cBorder),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
  );

  String _labelFecha(DateTime f) {
    final esHoy  = _esHoy(f);
    final esAyer = _esAyer(f);
    if (esHoy)  return 'Hoy · ${_formatFecha(f)}';
    if (esAyer) return 'Ayer · ${_formatFecha(f)}';
    return _formatFecha(f);
  }

  bool _esHoy(DateTime f) {
    final h = DateTime.now();
    return f.year == h.year && f.month == h.month && f.day == h.day;
  }

  bool _esAyer(DateTime f) {
    final a = DateTime.now().subtract(const Duration(days: 1));
    return f.year == a.year && f.month == a.month && f.day == a.day;
  }

  String _formatFecha(DateTime f) {
    const m = ['','Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${f.day} ${m[f.month]} ${f.year}';
  }

  Color _colorMetodo(String n) {
    switch (n.toLowerCase()) {
      case 'efectivo':  return _cGreen;
      case 'nequi':     return const Color(0xFF7C3AED);
      case 'daviplata': return _cOrange;
      case 'fiado':     return _cRed;
      default:          return _cAccent;
    }
  }

  IconData _iconoMetodo(String n) {
    switch (n.toLowerCase()) {
      case 'efectivo':  return Icons.payments_rounded;
      case 'nequi':     return Icons.phone_android_rounded;
      case 'daviplata': return Icons.account_balance_wallet_rounded;
      case 'fiado':     return Icons.handshake_rounded;
      default:          return Icons.credit_card_rounded;
    }
  }

  double _num(String k) => ((_data[k]) as num?)?.toDouble() ?? 0;
  int    _int(String k) => ((_data[k]) as num?)?.toInt()    ?? 0;
  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}K';
    return v.toStringAsFixed(0);
  }
}

// ── Bottom Sheet de exportación (CU08) ───────────────────────────────────────
class _BottomSheetExportacion extends StatelessWidget {
  final void Function(String formato) onExportar;
  const _BottomSheetExportacion({required this.onExportar});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color:        _cWhite,
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Handle
      Center(child: Container(
          width: 36, height: 4,
          decoration: BoxDecoration(color: _cBorder, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 20),
      const Text('Exportar resumen',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _cText)),
      const SizedBox(height: 6),
      const Text('Elige el formato en que deseas exportar el resumen.',
          style: TextStyle(fontSize: 13, color: _cSubtext)),
      const SizedBox(height: 20),
      // Opción PDF
      _opcionFormato(
        context,
        icono:    Icons.picture_as_pdf_rounded,
        color:    _cRed,
        titulo:   'PDF',
        subtitulo: 'Documento listo para imprimir o compartir',
        onTap:    () => onExportar('PDF'),
      ),
      const SizedBox(height: 12),
      // Opción Excel
      _opcionFormato(
        context,
        icono:    Icons.table_chart_rounded,
        color:    _cGreen,
        titulo:   'Excel',
        subtitulo: 'Hoja de cálculo editable (.xlsx)',
        onTap:    () => onExportar('Excel'),
      ),
    ]),
  );

  Widget _opcionFormato(BuildContext context, {
    required IconData icono,
    required Color    color,
    required String   titulo,
    required String   subtitulo,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color:        color.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icono, color: color, size: 20)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo,
                  style: const TextStyle(color: _cText, fontWeight: FontWeight.w700, fontSize: 14)),
              Text(subtitulo,
                  style: const TextStyle(color: _cSubtext, fontSize: 12)),
            ])),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ]),
        ),
      );
}