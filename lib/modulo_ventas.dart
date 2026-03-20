import 'package:flutter/material.dart';
import 'database_service.dart';
import 'models.dart';

const _kPrimary = Color(0xFF1A5276);
const _kAccent  = Color(0xFF2E86C1);
const _kSuccess = Color(0xFF1ABC9C);
const _kDanger  = Color(0xFFE74C3C);
const _kWarning = Color(0xFFE67E22);
const _kBg      = Color(0xFFF0F4F8);

class ProductoVenta {
  final String id;
  final String nombre;
  final double precio;
  int stock;
  final String categoriaNombre;

  ProductoVenta({required this.id, required this.nombre, required this.precio, required this.stock, required this.categoriaNombre});

  factory ProductoVenta.fromProducto(Producto p) => ProductoVenta(
    id: p.idProducto, nombre: p.nombre, precio: p.precioVenta, stock: p.stockActual, categoriaNombre: p.categoriaNombre,
  );
}

class ItemCarrito {
  final ProductoVenta producto;
  int cantidad;
  ItemCarrito({required this.producto, required this.cantidad});
  double get subtotal => producto.precio * cantidad;
  Map<String, dynamic> toMap() => {
    'id_producto': producto.id, 'nombre_producto': producto.nombre,
    'cantidad': cantidad, 'precio_unitario': producto.precio, 'subtotal': subtotal,
  };
}

class ModuloVentas extends StatefulWidget {
  final String idUsuario;
  final String idSucursal;
  const ModuloVentas({super.key, required this.idUsuario, required this.idSucursal});
  @override
  State<ModuloVentas> createState() => _ModuloVentasState();
}

class _ModuloVentasState extends State<ModuloVentas> with SingleTickerProviderStateMixin {
  final _svc = DatabaseService();
  late TabController _tabCtrl;
  List<ProductoVenta> _productos  = [];
  List<Cliente>       _clientes   = [];
  List<MetodoPago>    _metodos    = [];
  List<Venta>         _historial  = [];
  List<ItemCarrito>   _carrito    = [];
  bool _cargando = true;
  String _busqueda = "";
  MetodoPago? _metodoSelec;
  TipoVenta _tipoVenta = TipoVenta.contado;
  Cliente? _clienteSelec;
  Map<String, dynamic> _resumen = {};

  // Datos del usuario y sucursal para registrar en la venta
  String _usuarioNombre  = '';
  String _sucursalNombre = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.index == 1) _cargarHistorial();
      if (_tabCtrl.index == 2) _cargarResumen();
    });
    _cargarDatos();
  }

  @override
  void didUpdateWidget(ModuloVentas old) {
    super.didUpdateWidget(old);
    if (old.idSucursal != widget.idSucursal) _cargarDatos();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final results = await Future.wait([
        _svc.getProductosConStock(idSucursal: widget.idSucursal),
        _svc.getClientes(),
        _svc.getMetodosPago(),
        _svc.getSucursales(),
      ]);
      // Obtener nombre del usuario actual
      final usuarios = await _svc.getUsuarios();
      final usuarioActual = usuarios.where((u) => u.idUsuario == widget.idUsuario).firstOrNull;
      _usuarioNombre = usuarioActual?.nombre ?? '';

      // Obtener nombre de la sucursal
      final sucursales = results[3] as List<Sucursal>;
      final suc = sucursales.where((s) => s.idSucursal == widget.idSucursal).firstOrNull;
      _sucursalNombre = suc?.nombre ?? '';

      setState(() {
        _productos = (results[0] as List<Producto>).map((p) => ProductoVenta.fromProducto(p)).toList();
        _clientes  = results[1] as List<Cliente>;
        _metodos   = results[2] as List<MetodoPago>;
        if (_metodos.isNotEmpty) _metodoSelec = _metodos.first;
      });
    } catch (e) { _snack("Error al cargar: $e", _kDanger); }
    finally { setState(() => _cargando = false); }
  }

  Future<void> _cargarHistorial() async {
    try {
      final ventas = await _svc.getHistorialVentas(idSucursal: widget.idSucursal);
      setState(() => _historial = ventas);
    } catch (e) { _snack("Error: $e", _kDanger); }
  }

  Future<void> _cargarResumen() async {
    try {
      final data = await _svc.getResumenDia(idSucursal: widget.idSucursal);
      setState(() => _resumen = data);
    } catch (e) { _snack("Error: $e", _kDanger); }
  }

  Future<void> _registrarVenta() async {
    if (_carrito.isEmpty) { _snack("Agrega productos al carrito", _kWarning); return; }
    if (_metodoSelec == null) { _snack("Selecciona un método de pago", _kWarning); return; }
    if (_tipoVenta == TipoVenta.fiado && _clienteSelec == null) { _snack("Selecciona un cliente para venta fiada", _kWarning); return; }

    final esFiado = _tipoVenta == TipoVenta.fiado;
    final total = _carrito.fold<double>(0, (s, i) => s + i.subtotal);
    try {
      await _svc.registrarVenta(
        idUsuario:        widget.idUsuario,
        usuarioNombre:    _usuarioNombre,
        idSucursal:       widget.idSucursal,
        sucursalNombre:   _sucursalNombre,
        // Fiado siempre guarda método 'Fiado', independiente del selector
        idMetodoPago:     esFiado ? 'fiado' : _metodoSelec!.idMetodoPago,
        metodoPagoNombre: esFiado ? 'Fiado' : _metodoSelec!.nombre,
        tipoVenta:        _tipoVenta.valor,
        idCliente:        _clienteSelec?.idCliente,
        clienteNombre:    _clienteSelec?.nombre ?? '',
        items:            _carrito.map((i) => i.toMap()).toList(),
        total:            total,
      );
      setState(() {
        _carrito.clear(); _clienteSelec = null; _tipoVenta = TipoVenta.contado;
        if (_metodos.isNotEmpty) _metodoSelec = _metodos.first;
      });
      if (mounted) Navigator.pop(context);
      _snack("Venta registrada correctamente", _kSuccess);
      _cargarDatos();
    } catch (e) { _snack("Error: $e", _kDanger); }
  }

  Future<void> _anularVenta(String idVenta) async {
    try {
      await _svc.anularVenta(idVenta);
      _snack("Venta anulada correctamente", _kSuccess);
      _cargarHistorial(); _cargarDatos();
    } catch (e) { _snack("Error: $e", _kDanger); }
  }

  void _agregar(ProductoVenta p) {
    setState(() {
      final idx = _carrito.indexWhere((i) => i.producto.id == p.id);
      if (idx >= 0) { if (_carrito[idx].cantidad < p.stock) _carrito[idx].cantidad++; else _snack("Sin más stock", _kWarning); }
      else _carrito.add(ItemCarrito(producto: p, cantidad: 1));
    });
  }

  void _quitar(ProductoVenta p) {
    setState(() {
      final idx = _carrito.indexWhere((i) => i.producto.id == p.id);
      if (idx >= 0) { if (_carrito[idx].cantidad > 1) _carrito[idx].cantidad--; else _carrito.removeAt(idx); }
    });
  }

  int _enCarrito(String id) { final idx = _carrito.indexWhere((i) => i.producto.id == id); return idx >= 0 ? _carrito[idx].cantidad : 0; }
  double get _totalCarrito => _carrito.fold(0, (s, i) => s + i.subtotal);
  int get _cantidadCarrito => _carrito.fold(0, (s, i) => s + i.cantidad);

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: Colors.white)),
    backgroundColor: color, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
  ));

  void _abrirCarrito() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => DraggableScrollableSheet(
          initialChildSize: 0.75, minChildSize: 0.4, maxChildSize: 0.95,
          builder: (_, sc) => Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
                const Icon(Icons.shopping_cart_rounded, color: _kPrimary, size: 22),
                const SizedBox(width: 10),
                const Text("Carrito", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary)),
                const Spacer(),
                if (_carrito.isNotEmpty) TextButton.icon(
                  onPressed: () { setState(() => _carrito.clear()); setSt(() {}); },
                  icon: const Icon(Icons.delete_sweep_rounded, size: 16), label: const Text("Limpiar"),
                  style: TextButton.styleFrom(foregroundColor: _kDanger),
                ),
              ])),
              const Divider(height: 24),
              Expanded(
                child: _carrito.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.shopping_cart_outlined, size: 56, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text("Carrito vacío", style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                ]))
                    : ListView(controller: sc, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
                  ..._carrito.map((item) => _itemCarrito(item, setSt)),
                  const SizedBox(height: 16),
                  const Text("Tipo de venta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 10),
                  Row(children: TipoVenta.values.map((t) {
                    final sel = _tipoVenta == t;
                    return Expanded(child: GestureDetector(
                      onTap: () { setSt(() { _tipoVenta = t; setState(() {}); if (t == TipoVenta.contado) _clienteSelec = null; }); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(right: t == TipoVenta.contado ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? _kPrimary : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? _kPrimary : Colors.grey[200]!),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(t == TipoVenta.contado ? Icons.payments_rounded : Icons.handshake_rounded,
                              color: sel ? Colors.white : Colors.grey[500], size: 18),
                          const SizedBox(width: 6),
                          Text(t.valor, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.grey[600])),
                        ]),
                      ),
                    ));
                  }).toList()),
                  const SizedBox(height: 16),
                  if (_tipoVenta == TipoVenta.contado) ...[
                    const Text("Método de pago", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: _metodos.map((m) {
                      final sel = _metodoSelec?.idMetodoPago == m.idMetodoPago;
                      return GestureDetector(
                        onTap: () { setSt(() { _metodoSelec = m; setState(() {}); }); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? _kAccent : Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? _kAccent : Colors.grey[200]!),
                          ),
                          child: Text(m.nombre, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.grey[600])),
                        ),
                      );
                    }).toList()),
                  ],
                  if (_tipoVenta == TipoVenta.fiado) ...[
                    const Text("Cliente *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: _clientes.isEmpty
                          ? const Padding(padding: EdgeInsets.all(16), child: Text("Sin clientes registrados", style: TextStyle(color: Colors.grey, fontSize: 13)))
                          : ListView.separated(
                        shrinkWrap: true, padding: EdgeInsets.zero,
                        itemCount: _clientes.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        itemBuilder: (_, i) {
                          final cl = _clientes[i];
                          final sel = _clienteSelec?.idCliente == cl.idCliente;
                          return GestureDetector(
                            onTap: () { setSt(() => _clienteSelec = cl); setState(() {}); },
                            child: Container(
                              color: sel ? _kAccent.withOpacity(0.08) : Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(children: [
                                CircleAvatar(radius: 14, backgroundColor: _kAccent.withOpacity(0.15),
                                    child: Text(cl.nombre[0].toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kAccent))),
                                const SizedBox(width: 10),
                                Expanded(child: Text(cl.nombre, style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.normal, color: const Color(0xFF2C3E50)))),
                                if (cl.saldoPendiente > 0)
                                  Text("\$${cl.saldoPendiente.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12, color: _kDanger, fontWeight: FontWeight.w600)),
                                if (sel) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.check_circle_rounded, color: _kAccent, size: 18)),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ]),
              ),
              if (_carrito.isNotEmpty) Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[100]!)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
                child: Column(children: [
                  Row(children: [
                    Text("$_cantidadCarrito productos", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    const Spacer(),
                    Text("Total  ", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    Text("\$${_totalCarrito.toStringAsFixed(0)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _kPrimary)),
                  ]),
                  const SizedBox(height: 14),
                  SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
                    onPressed: _registrarVenta,
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text("Confirmar · \$${_totalCarrito.toStringAsFixed(0)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(backgroundColor: _kSuccess, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  )),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _itemCarrito(ItemCarrito item, StateSetter setSt) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: const Color(0xFFF8FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.producto.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2C3E50)), overflow: TextOverflow.ellipsis),
        Text("\$${item.producto.precio.toStringAsFixed(0)} c/u", style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ])),
      Row(children: [
        _btnRedondo(Icons.remove_rounded, () { _quitar(item.producto); setSt(() {}); }, _kDanger),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text("${item.cantidad}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        _btnRedondo(Icons.add_rounded, () { _agregar(item.producto); setSt(() {}); }, _kSuccess),
      ]),
      const SizedBox(width: 12),
      Text("\$${item.subtotal.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _kAccent)),
    ]),
  );

  Widget _btnRedondo(IconData icon, VoidCallback onTap, Color color) => GestureDetector(
    onTap: onTap,
    child: Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 16, color: color)),
  );

  @override
  Widget build(BuildContext context) => Container(
    color: _kBg,
    child: Column(children: [
      Container(
        color: Colors.white, padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Ventas", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _kPrimary)),
              Text("Registra y gestiona las ventas del día", style: TextStyle(fontSize: 13, color: Colors.grey)),
            ]),
            const Spacer(),
            Stack(children: [
              ElevatedButton.icon(
                onPressed: _abrirCarrito,
                icon: const Icon(Icons.shopping_cart_rounded, size: 20), label: const Text("Carrito"),
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              ),
              if (_carrito.isNotEmpty) Positioned(right: 0, top: 0, child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: _kDanger, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text("${_carrito.length}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              )),
            ]),
          ]),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabCtrl, labelColor: _kPrimary, unselectedLabelColor: Colors.grey,
            indicatorColor: _kPrimary, indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [Tab(text: "Productos"), Tab(text: "Historial"), Tab(text: "Resumen")],
          ),
        ]),
      ),
      Expanded(child: TabBarView(controller: _tabCtrl, children: [_tabProductos(), _tabHistorial(), _tabResumen()])),
    ]),
  );

  Widget _tabProductos() {
    final filtrados = _productos.where((p) => p.nombre.toLowerCase().contains(_busqueda.toLowerCase())).toList();
    final porCat = <String, List<ProductoVenta>>{};
    for (final p in filtrados) porCat.putIfAbsent(p.categoriaNombre, () => []).add(p);
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: TextField(
        onChanged: (v) => setState(() => _busqueda = v),
        decoration: InputDecoration(
          hintText: "Buscar producto...", hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: _kAccent, size: 20),
          filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        ),
      )),
      Expanded(
        child: _cargando ? const Center(child: CircularProgressIndicator(color: _kAccent))
            : filtrados.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inventory_2_outlined, size: 52, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text("Sin productos con stock", style: TextStyle(color: Colors.grey[400])),
        ]))
            : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
            child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Column(
              children: porCat.entries.expand((entry) => [
                Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: _kPrimary.withOpacity(0.04),
                    child: Text(entry.key.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kPrimary, letterSpacing: 0.8))),
                const Divider(height: 1, color: Color(0xFFEEF0F2)),
                ...entry.value.map((p) => Column(children: [_filaProducto(p), const Divider(height: 1, indent: 60, color: Color(0xFFEEF0F2))])),
              ]).toList(),
            )),
          ),
        ]),
      ),
    ]);
  }

  Widget _filaProducto(ProductoVenta p) {
    final qty = _enCarrito(p.id);
    final sinStock = p.stock == 0;
    return Material(
      color: qty > 0 ? _kAccent.withOpacity(0.03) : Colors.white,
      child: InkWell(
        onTap: sinStock ? null : () { _agregar(p); setState(() {}); },
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11), child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: sinStock ? Colors.grey[100] : _kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.category_rounded, color: sinStock ? Colors.grey[400] : _kAccent, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.nombre, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: sinStock ? Colors.grey[400] : const Color(0xFF2C3E50)), overflow: TextOverflow.ellipsis),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: sinStock ? Colors.grey[100] : _kSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(sinStock ? "Sin stock" : "${p.stock} uds.", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sinStock ? Colors.grey[400] : _kSuccess))),
          ])),
          Text("\$${p.precio.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: sinStock ? Colors.grey[400] : _kPrimary)),
          const SizedBox(width: 12),
          if (sinStock) const SizedBox(width: 80)
          else if (qty == 0) SizedBox(width: 80, child: ElevatedButton(
            onPressed: () { _agregar(p); setState(() {}); },
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
            child: const Text("Agregar", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ))
          else SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              _btnRedondo(Icons.remove_rounded, () { _quitar(p); setState(() {}); }, _kDanger),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text("$qty", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _kPrimary))),
              _btnRedondo(Icons.add_rounded, () { _agregar(p); setState(() {}); }, _kSuccess),
            ])),
        ])),
      ),
    );
  }

  Widget _tabHistorial() => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Row(children: [
      const Text("Ventas de hoy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C3E50))),
      const Spacer(),
      TextButton.icon(onPressed: _cargarHistorial, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text("Actualizar"), style: TextButton.styleFrom(foregroundColor: _kAccent)),
    ])),
    Expanded(
      child: _historial.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.receipt_long_outlined, size: 52, color: Colors.grey[300]), const SizedBox(height: 12), Text("Sin ventas hoy", style: TextStyle(color: Colors.grey[400]))]))
          : ListView.separated(padding: const EdgeInsets.all(16), itemCount: _historial.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _filaHistorial(_historial[i])),
    ),
  ]);

  Widget _filaHistorial(Venta v) {
    final color = _colorMetodo(v.metodoPagoNombre);
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey[100]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(_iconoMetodo(v.metodoPagoNombre), color: color, size: 20)),
        title: Row(children: [
          Text("#${v.idVenta.substring(0, v.idVenta.length.clamp(0, 6))}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(v.metodoPagoNombre.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color))),
          const SizedBox(width: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: v.esFiado ? _kDanger.withOpacity(0.1) : _kSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(v.tipoVenta.valor.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: v.esFiado ? _kDanger : _kSuccess))),
        ]),
        subtitle: v.clienteNombre.isNotEmpty ? Text("Cliente: ${v.clienteNombre}", style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text("\$${v.total.toStringAsFixed(0)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
          if (!v.anulada) IconButton(icon: const Icon(Icons.cancel_outlined, color: _kDanger, size: 20), onPressed: () => _confirmarAnulacion(v)),
        ]),
      ),
    );
  }

  void _confirmarAnulacion(Venta v) => showDialog(context: context, builder: (_) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: const Row(children: [Icon(Icons.warning_amber_rounded, color: _kWarning), SizedBox(width: 8), Text("Anular venta")]),
    content: Text("¿Anular venta por \$${v.total.toStringAsFixed(0)}?\nSe devolverá el stock automáticamente."),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _kDanger, foregroundColor: Colors.white, elevation: 0),
          onPressed: () { Navigator.pop(context); _anularVenta(v.idVenta); }, child: const Text("Anular")),
    ],
  ));

  Widget _tabResumen() {
    final metodos  = (_resumen["ventas_por_metodo"] as List?) ?? [];
    final totalDia = (_resumen["total_dia"] as num?)?.toDouble() ?? 0;
    final now = DateTime.now();
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kPrimary, _kAccent], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.today_rounded, color: Colors.white70, size: 18), const SizedBox(width: 8), Text("${now.day}/${now.month}/${now.year}", style: const TextStyle(color: Colors.white70, fontSize: 13))]),
            const SizedBox(height: 12),
            Text("\$${totalDia.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            const Text("Total ventas del día", style: TextStyle(color: Colors.white60, fontSize: 13)),
          ])),
      const SizedBox(height: 20),
      if (metodos.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(children: [
          Icon(Icons.bar_chart_rounded, size: 52, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text("Sin ventas hoy", style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _cargarResumen, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text("Cargar"),
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
        ])))
      else ...[
        const Text("Por método de pago", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C3E50))),
        const SizedBox(height: 12),
        ...metodos.map((r) {
          final sub  = (r["subtotal"] as num?)?.toDouble() ?? 0;
          final pct  = totalDia > 0 ? sub / totalDia : 0.0;
          final color = _colorMetodo(r["metodo"]?.toString() ?? "");
          return Container(
            margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey[100]!)),
            child: Column(children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(_iconoMetodo(r["metodo"]?.toString() ?? ""), color: color, size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((r["metodo"] ?? "").toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF2C3E50))),
                  Text("${r["cantidad"]} ventas", style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ])),
                Text("\$${sub.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: pct.toDouble(), backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 6)),
              const SizedBox(height: 4),
              Align(alignment: Alignment.centerRight, child: Text("${(pct * 100).toStringAsFixed(1)}%", style: TextStyle(fontSize: 11, color: Colors.grey[400]))),
            ]),
          );
        }),
      ],
    ]));
  }

  Color _colorMetodo(String n) {
    switch (n.toLowerCase()) {
      case 'efectivo':  return _kSuccess;
      case 'nequi':     return const Color(0xFF8E44AD);
      case 'daviplata': return _kWarning;
      default:          return _kAccent;
    }
  }

  IconData _iconoMetodo(String n) {
    switch (n.toLowerCase()) {
      case 'efectivo':  return Icons.payments_rounded;
      case 'nequi':     return Icons.phone_android_rounded;
      case 'daviplata': return Icons.account_balance_wallet_rounded;
      default:          return Icons.receipt_rounded;
    }
  }
}