// modulo_historial_ventas.dart
// CU07 – Consultar historial de ventas
// Acceso: SOLO Administrador

import 'package:flutter/material.dart';
import 'database_service.dart';

// ── Paleta ───────────────────────────────────────────────────────────────────
const _cAccent  = Color(0xFF2563EB);
const _cGreen   = Color(0xFF059669);
const _cOrange  = Color(0xFFD97706);
const _cRed     = Color(0xFFDC2626);
const _cBg      = Color(0xFFF1F5F9);
const _cWhite   = Color(0xFFFFFFFF);
const _cBorder  = Color(0xFFE2E8F0);
const _cText    = Color(0xFF0F172A);
const _cSubtext = Color(0xFF64748B);

// ── Modelo de venta ──────────────────────────────────────────────────────────
class VentaHistorial {
  final String  id;
  final DateTime fecha;
  final double  monto;
  final String  metodo;
  final String  cliente;
  final String  usuario;
  final String  sucursal;
  final String  tipo;   // 'venta' | 'abono' | 'fiado'
  final List<Map<String, dynamic>> productos;

  const VentaHistorial({
    required this.id,
    required this.fecha,
    required this.monto,
    required this.metodo,
    required this.cliente,
    required this.usuario,
    required this.sucursal,
    required this.tipo,
    this.productos = const [],
  });

  factory VentaHistorial.fromMap(Map<String, dynamic> m) => VentaHistorial(
    id:        m['id']?.toString() ?? '',
    fecha:     m['fecha'] is DateTime
        ? m['fecha'] as DateTime
        : DateTime.tryParse(m['fecha']?.toString() ?? '') ?? DateTime.now(),
    monto:     (m['monto']  as num?)?.toDouble() ?? 0,
    metodo:    m['metodo']?.toString()   ?? '',
    cliente:   m['cliente']?.toString()  ?? '',
    usuario:   m['usuario']?.toString()  ?? '',
    sucursal:  m['sucursal']?.toString() ?? '',
    tipo:      m['tipo']?.toString()     ?? 'venta',
    productos: (m['productos'] as List?)?.cast<Map<String, dynamic>>() ?? [],
  );
}

// ── Widget principal ─────────────────────────────────────────────────────────
class ModuloHistorialVentas extends StatefulWidget {
  final String? idSucursal;

  const ModuloHistorialVentas({super.key, this.idSucursal});

  @override
  State<ModuloHistorialVentas> createState() => _ModuloHistorialVentasState();
}

class _ModuloHistorialVentasState extends State<ModuloHistorialVentas> {
  final _svc          = DatabaseService();
  final _searchCtrl   = TextEditingController();

  bool _cargando      = false;
  bool _cargandoMas   = false;

  List<VentaHistorial> _ventas    = [];
  List<VentaHistorial> _filtradas = [];

  // Filtros activos
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  String    _filtroTipo    = 'Todos';      // Todos | Venta | Abono | Fiado
  String    _filtroMetodo  = 'Todos';
  String    _busqueda      = '';

  // Para paginación simple
  int  _pagina     = 0;
  bool _hayMas     = false;
  static const int _porPagina = 30;

  @override
  void initState() { super.initState(); _cargar(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  // ── Carga ─────────────────────────────────────────────────────────────────
  Future<void> _cargar({bool resetear = true}) async {
    if (resetear) setState(() { _cargando = true; _pagina = 0; _ventas = []; });
    try {
      final lista = await _svc.getHistorialVentasFiltrado(
        idSucursal: widget.idSucursal,
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
        tipo:       _filtroTipo  == 'Todos' ? null : _filtroTipo.toLowerCase(),
        metodo:     _filtroMetodo == 'Todos' ? null : _filtroMetodo,
        busqueda:   _busqueda.isEmpty ? null : _busqueda,
        limite:     _porPagina,
        offset:     _pagina * _porPagina,
      );
      final nuevas = lista.map((m) => VentaHistorial.fromMap(m)).toList();
      setState(() {
        if (resetear) {
          _ventas = nuevas;
        } else {
          _ventas = [..._ventas, ...nuevas];
        }
        _hayMas   = nuevas.length == _porPagina;
        _filtradas = _ventas;
      });
    } catch (_) {
      setState(() => _ventas = _filtradas = []);
    } finally {
      if (mounted) setState(() { _cargando = false; _cargandoMas = false; });
    }
  }

  Future<void> _cargarMas() async {
    if (_cargandoMas || !_hayMas) return;
    setState(() { _cargandoMas = true; _pagina++; });
    await _cargar(resetear: false);
  }

  // ── Filtros ───────────────────────────────────────────────────────────────
  void _aplicarBusqueda(String q) {
    setState(() => _busqueda = q);
    _cargar();
  }

  Future<void> _seleccionarFechaDesde() async {
    final p = await _datePicker(_fechaDesde ?? DateTime.now().subtract(const Duration(days: 30)));
    if (p != null) { setState(() => _fechaDesde = p); _cargar(); }
  }

  Future<void> _seleccionarFechaHasta() async {
    final p = await _datePicker(_fechaHasta ?? DateTime.now());
    if (p != null) { setState(() => _fechaHasta = p); _cargar(); }
  }

  Future<DateTime?> _datePicker(DateTime initial) => showDatePicker(
    context:     context,
    initialDate: initial,
    firstDate:   DateTime(2020),
    lastDate:    DateTime.now(),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _cAccent)),
      child: child!,
    ),
  );

  void _limpiarFiltros() {
    setState(() {
      _fechaDesde   = null;
      _fechaHasta   = null;
      _filtroTipo   = 'Todos';
      _filtroMetodo = 'Todos';
      _busqueda     = '';
      _searchCtrl.clear();
    });
    _cargar();
  }

  bool get _hayFiltrosActivos =>
      _fechaDesde != null || _fechaHasta != null ||
          _filtroTipo != 'Todos' || _filtroMetodo != 'Todos' ||
          _busqueda.isNotEmpty;

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) => Column(children: [
    _barraFiltros(),
    Expanded(
      child: _cargando
          ? const Center(child: CircularProgressIndicator(color: _cAccent))
          : RefreshIndicator(
        onRefresh: _cargar,
        color:     _cAccent,
        child:     _listaVentas(),
      ),
    ),
  ]);

  // ── Barra de filtros ──────────────────────────────────────────────────────
  Widget _barraFiltros() => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
    decoration: const BoxDecoration(
      color:  _cWhite,
      border: Border(bottom: BorderSide(color: _cBorder)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Búsqueda
      TextField(
        controller:    _searchCtrl,
        onChanged:     _aplicarBusqueda,
        style: const TextStyle(fontSize: 13, color: _cText),
        decoration: InputDecoration(
          hintText:    'Buscar por cliente o producto…',
          hintStyle:   const TextStyle(color: _cSubtext, fontSize: 13),
          prefixIcon:  const Icon(Icons.search_rounded, color: _cSubtext, size: 18),
          suffixIcon:  _busqueda.isNotEmpty
              ? IconButton(
              icon:     const Icon(Icons.close_rounded, size: 16, color: _cSubtext),
              onPressed: () { _searchCtrl.clear(); _aplicarBusqueda(''); })
              : null,
          filled:      true,
          fillColor:   _cBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 10),
      // Chips de filtros
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          // Fecha desde
          _chipFiltro(
            label:   _fechaDesde != null ? 'Desde: ${_shortFecha(_fechaDesde!)}' : 'Desde',
            activo:  _fechaDesde != null,
            icono:   Icons.calendar_today_rounded,
            onTap:   _seleccionarFechaDesde,
          ),
          const SizedBox(width: 8),
          // Fecha hasta
          _chipFiltro(
            label:   _fechaHasta != null ? 'Hasta: ${_shortFecha(_fechaHasta!)}' : 'Hasta',
            activo:  _fechaHasta != null,
            icono:   Icons.calendar_month_rounded,
            onTap:   _seleccionarFechaHasta,
          ),
          const SizedBox(width: 8),
          // Tipo
          _chipDropdown(
            label:   _filtroTipo,
            opciones: const ['Todos', 'Venta', 'Abono', 'Fiado'],
            onSelected: (v) { setState(() => _filtroTipo = v); _cargar(); },
          ),
          const SizedBox(width: 8),
          // Método de pago
          _chipDropdown(
            label:   _filtroMetodo == 'Todos' ? 'Método' : _filtroMetodo,
            opciones: const ['Todos', 'Efectivo', 'Nequi', 'Daviplata', 'Fiado'],
            onSelected: (v) { setState(() => _filtroMetodo = v); _cargar(); },
          ),
          if (_hayFiltrosActivos) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _limpiarFiltros,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: _cRed.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _cRed.withOpacity(0.2))),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.filter_alt_off_rounded, size: 13, color: _cRed),
                  SizedBox(width: 5),
                  Text('Limpiar', style: TextStyle(fontSize: 11, color: _cRed, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ]),
      ),
    ]),
  );

  Widget _chipFiltro({required String label, required bool activo,
    required IconData icono, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:        activo ? _cAccent.withOpacity(0.08) : _cBg,
            borderRadius: BorderRadius.circular(20),
            border:       Border.all(color: activo ? _cAccent.withOpacity(0.3) : _cBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icono, size: 13, color: activo ? _cAccent : _cSubtext),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: activo ? _cAccent : _cSubtext)),
          ]),
        ),
      );

  Widget _chipDropdown({required String label, required List<String> opciones,
    required void Function(String) onSelected}) =>
      PopupMenuButton<String>(
        onSelected:        onSelected,
        shape:             RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color:             _cWhite,
        itemBuilder: (_) => opciones.map((o) => PopupMenuItem(
          value: o,
          child: Text(o, style: const TextStyle(fontSize: 13, color: _cText)),
        )).toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:        _cBg,
            borderRadius: BorderRadius.circular(20),
            border:       Border.all(color: _cBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _cSubtext)),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded, size: 13, color: _cSubtext),
          ]),
        ),
      );

  // ── Lista de transacciones ─────────────────────────────────────────────────
  Widget _listaVentas() {
    if (_ventas.isEmpty) return _sinResultados();

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollEndNotification &&
            n.metrics.extentAfter < 120 && _hayMas) {
          _cargarMas();
        }
        return false;
      },
      child: ListView.builder(
        physics:     const AlwaysScrollableScrollPhysics(),
        padding:     const EdgeInsets.all(16),
        itemCount:   _ventas.length + (_hayMas ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == _ventas.length) {
            return _cargandoMas
                ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: _cAccent, strokeWidth: 2)))
                : const SizedBox();
          }
          final v = _ventas[i];
          // Agrupar por fecha: mostrar separador de día
          final mostrarSep = i == 0 || !_mismaFecha(v.fecha, _ventas[i - 1].fecha);
          return Column(children: [
            if (mostrarSep) _separadorFecha(v.fecha),
            _tarjetaVenta(v),
            const SizedBox(height: 8),
          ]);
        },
      ),
    );
  }

  Widget _separadorFecha(DateTime f) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Row(children: [
      Expanded(child: Divider(color: _cBorder, height: 1)),
      const SizedBox(width: 12),
      Text(_labelFecha(f),
          style: const TextStyle(color: _cSubtext, fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(width: 12),
      Expanded(child: Divider(color: _cBorder, height: 1)),
    ]),
  );

  Widget _tarjetaVenta(VentaHistorial v) {
    final color  = _colorTipo(v.tipo, v.metodo);
    final icono  = _iconoTipo(v.tipo, v.metodo);
    final badge  = _badgeTipo(v.tipo, v.metodo);
    final partes = <String>[];
    if (v.cliente.isNotEmpty && v.cliente != 'Contado') partes.add(v.cliente);
    if (v.usuario.isNotEmpty) partes.add(v.usuario);
    if (v.sucursal.isNotEmpty) partes.add(v.sucursal);

    return GestureDetector(
      onTap: () => _verDetalle(v),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        _cWhite,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: _cBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Ícono
          Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.09), borderRadius: BorderRadius.circular(11)),
              child: Icon(icono, color: color, size: 18)),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('${_shortId(v.id)}',
                  style: const TextStyle(color: _cText, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 6),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.09), borderRadius: BorderRadius.circular(6)),
                  child: Text(badge,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                          color: color, letterSpacing: 0.2))),
            ]),
            const SizedBox(height: 3),
            if (partes.isNotEmpty)
              Text(partes.join(' · '),
                  style: const TextStyle(color: _cSubtext, fontSize: 11),
                  overflow: TextOverflow.ellipsis),
            Text(_horaFecha(v.fecha),
                style: const TextStyle(color: _cSubtext, fontSize: 10)),
          ])),
          // Monto
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${_fmt(v.monto)}',
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right_rounded, size: 16, color: _cSubtext),
          ]),
        ]),
      ),
    );
  }

  // ── Detalle de venta (bottom sheet) ─────────────────────────────────────────
  void _verDetalle(VentaHistorial v) {
    showModalBottomSheet(
      context:            context,
      backgroundColor:    Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DetalleVentaSheet(venta: v),
    );
  }

  // ── Sin resultados ──────────────────────────────────────────────────────────
  Widget _sinResultados() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded, size: 38, color: _cSubtext)),
        const SizedBox(height: 20),
        const Text('Sin historial disponible',
            style: TextStyle(color: _cText, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('No se encontraron ventas con los\nfiltros aplicados.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _cSubtext, fontSize: 13)),
        if (_hayFiltrosActivos) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _limpiarFiltros,
            icon:      const Icon(Icons.filter_alt_off_rounded, size: 15),
            label:     const Text('Limpiar filtros'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _cAccent,
              side:            const BorderSide(color: _cAccent),
              shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding:         const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ]),
    ),
  );

  // ── Helpers ───────────────────────────────────────────────────────────────
  bool _mismaFecha(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _labelFecha(DateTime f) {
    final h = DateTime.now();
    final a = h.subtract(const Duration(days: 1));
    if (_mismaFecha(f, h)) return 'Hoy';
    if (_mismaFecha(f, a)) return 'Ayer';
    const m = ['','Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${f.day} ${m[f.month]} ${f.year}';
  }

  String _shortFecha(DateTime f) {
    const m = ['','Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${f.day} ${m[f.month]}';
  }

  String _horaFecha(DateTime f) {
    final h = f.hour.toString().padLeft(2, '0');
    final min = f.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }

  String _shortId(String id) {
    if (id.length > 8) return '#${id.substring(0, 8).toUpperCase()}';
    return '#${id.toUpperCase()}';
  }

  Color _colorTipo(String tipo, String metodo) {
    if (tipo == 'abono') return _cGreen;
    if (tipo == 'fiado') return _cOrange;
    switch (metodo.toLowerCase()) {
      case 'efectivo':  return _cGreen;
      case 'nequi':     return const Color(0xFF7C3AED);
      case 'daviplata': return _cOrange;
      default:          return _cAccent;
    }
  }

  IconData _iconoTipo(String tipo, String metodo) {
    if (tipo == 'abono') return Icons.payments_rounded;
    if (tipo == 'fiado') return Icons.handshake_rounded;
    switch (metodo.toLowerCase()) {
      case 'efectivo':  return Icons.payments_rounded;
      case 'nequi':     return Icons.phone_android_rounded;
      case 'daviplata': return Icons.account_balance_wallet_rounded;
      default:          return Icons.point_of_sale_rounded;
    }
  }

  String _badgeTipo(String tipo, String metodo) {
    if (tipo == 'abono') return 'ABONO';
    if (tipo == 'fiado') return 'FIADO';
    return metodo.toUpperCase().isEmpty ? 'VENTA' : metodo.toUpperCase();
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}K';
    return v.toStringAsFixed(0);
  }
}

// ── Detalle de venta ──────────────────────────────────────────────────────────
class _DetalleVentaSheet extends StatelessWidget {
  final VentaHistorial venta;
  const _DetalleVentaSheet({required this.venta});

  @override
  Widget build(BuildContext context) {
    final color = _colorTipo(venta.tipo, venta.metodo);
    return Container(
      decoration: const BoxDecoration(
        color:        _cWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24,
          24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Handle
        Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: _cBorder, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 18),
        // Cabecera
        Row(children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(_iconoTipo(venta.tipo, venta.metodo), color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_tituloDetalle(),
                style: const TextStyle(color: _cText, fontSize: 16, fontWeight: FontWeight.w700)),
            Text(_formatFechaCompleta(venta.fecha),
                style: const TextStyle(color: _cSubtext, fontSize: 12)),
          ])),
          Text('\$${_fmt(venta.monto)}',
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 20),
        const Divider(color: _cBorder, height: 1),
        const SizedBox(height: 16),

        // Información general
        _fila('Método', venta.metodo.isEmpty ? '—' : venta.metodo),
        if (venta.cliente.isNotEmpty && venta.cliente != 'Contado')
          _fila('Cliente', venta.cliente),
        if (venta.usuario.isNotEmpty)
          _fila('Registrado por', venta.usuario),
        if (venta.sucursal.isNotEmpty)
          _fila('Sucursal', venta.sucursal),

        // Productos
        if (venta.productos.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Productos', style: TextStyle(color: _cText, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color:        _cBg,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: _cBorder),
            ),
            child: Column(children: List.generate(venta.productos.length, (i) {
              final p    = venta.productos[i];
              final nom  = p['nombre']?.toString() ?? 'Producto';
              final cant = (p['cantidad'] as num?)?.toInt() ?? 1;
              final sub  = (p['subtotal'] as num?)?.toDouble() ?? 0;
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(nom, style: const TextStyle(color: _cText, fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('x$cant', style: const TextStyle(color: _cSubtext, fontSize: 11)),
                    ])),
                    Text('\$${_fmt(sub)}',
                        style: const TextStyle(color: _cText, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
                if (i < venta.productos.length - 1) const Divider(height: 1, color: _cBorder),
              ]);
            })),
          ),
        ],
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _fila(String label, String valor) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(color: _cSubtext, fontSize: 13))),
      Expanded(child: Text(valor,
          style: const TextStyle(color: _cText, fontSize: 13, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis)),
    ]),
  );

  String _tituloDetalle() {
    if (venta.tipo == 'abono') return 'Abono registrado';
    if (venta.tipo == 'fiado') return 'Venta fiada';
    return 'Venta #${venta.id.length > 8 ? venta.id.substring(0, 8).toUpperCase() : venta.id.toUpperCase()}';
  }

  String _formatFechaCompleta(DateTime f) {
    const dias = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const mes  = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    final h    = f.hour.toString().padLeft(2, '0');
    final min  = f.minute.toString().padLeft(2, '0');
    return '${dias[f.weekday]} ${f.day} ${mes[f.month]} ${f.year} · $h:$min';
  }

  Color _colorTipo(String tipo, String metodo) {
    if (tipo == 'abono') return _cGreen;
    if (tipo == 'fiado') return _cOrange;
    switch (metodo.toLowerCase()) {
      case 'efectivo':  return _cGreen;
      case 'nequi':     return const Color(0xFF7C3AED);
      case 'daviplata': return _cOrange;
      default:          return _cAccent;
    }
  }

  IconData _iconoTipo(String tipo, String metodo) {
    if (tipo == 'abono') return Icons.payments_rounded;
    if (tipo == 'fiado') return Icons.handshake_rounded;
    switch (metodo.toLowerCase()) {
      case 'efectivo':  return Icons.payments_rounded;
      case 'nequi':     return Icons.phone_android_rounded;
      case 'daviplata': return Icons.account_balance_wallet_rounded;
      default:          return Icons.point_of_sale_rounded;
    }
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}K';
    return v.toStringAsFixed(0);
  }
}