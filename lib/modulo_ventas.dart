import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'example.dart' show kBaseUrl;
import 'models.dart';

const kPrimary = Color(0xFF1A5276);
const kAccent  = Color(0xFF2E86C1);
const kSuccess = Color(0xFF1ABC9C);
const kDanger  = Color(0xFFE74C3C);
const kWarning = Color(0xFFE67E22);
const kBg      = Color(0xFFF0F4F8);

class ProductoVenta {
  final int id;
  final String nombre;
  final double precio;
  int stock;
  final String categoriaNombre;
  final int idCategoria;

  ProductoVenta({required this.id, required this.nombre, required this.precio, required this.stock, required this.categoriaNombre, required this.idCategoria});

  factory ProductoVenta.fromJson(Map<String, dynamic> j) => ProductoVenta(
    id: int.tryParse(j["id_producto"].toString()) ?? 0,
    nombre: j["nombre"] ?? "",
    precio: double.tryParse(j["precio_venta"].toString()) ?? 0,
    stock: int.tryParse(j["stock_actual"].toString()) ?? 0,
    categoriaNombre: j["categoria_nombre"] ?? "",
    idCategoria: int.tryParse(j["id_categoria"].toString()) ?? 0,
  );
}

class ItemCarrito {
  final ProductoVenta producto;
  int cantidad;
  ItemCarrito({required this.producto, required this.cantidad});
  double get subtotal => producto.precio * cantidad;
  Map<String, dynamic> toJson() => {"id_producto": producto.id, "cantidad": cantidad, "precio_unitario": producto.precio, "subtotal": subtotal};
}

class ModuloVentas extends StatefulWidget {
  final int idUsuario;
  const ModuloVentas({super.key, required this.idUsuario});
  @override
  State<ModuloVentas> createState() => _ModuloVentasState();
}

class _ModuloVentasState extends State<ModuloVentas> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<ProductoVenta> _productos   = [];
  List<Cliente>       _clientes    = [];
  List<MetodoPago>    _metodos     = [];
  List<Venta>         _historial   = [];
  List<ItemCarrito>   _carrito     = [];
  bool _cargando = true;
  String _busqueda = "";
  MetodoPago? _metodoSelec;
  TipoVenta _tipoVenta = TipoVenta.contado;
  Cliente? _clienteSelec;
  Map<String, dynamic> _resumen = {};

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
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  // Traemos productos, clientes y metodos de pago para vender
  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final rP = await http.post(Uri.parse("$kBaseUrl/ventas.php"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"accion": "productos"})).timeout(const Duration(seconds: 10));
      final rC = await http.post(Uri.parse("$kBaseUrl/ventas.php"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"accion": "clientes"})).timeout(const Duration(seconds: 10));
      final rM = await http.post(Uri.parse("$kBaseUrl/ventas.php"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"accion": "metodos_pago"})).timeout(const Duration(seconds: 10));
      final dp = jsonDecode(rP.body); final dc = jsonDecode(rC.body); final dm = jsonDecode(rM.body);
      setState(() {
        if (dp["success"] == true) _productos = (dp["productos"] as List).map((e) => ProductoVenta.fromJson(e)).toList();
        if (dc["success"] == true) _clientes  = (dc["clientes"]  as List).map((e) => Cliente.fromJson(e)).toList();
        if (dm["success"] == true) {
          _metodos = (dm["metodos"] as List).map((e) => MetodoPago.fromJson(e)).toList();
          if (_metodos.isNotEmpty) _metodoSelec = _metodos.first;
        }
      });
    } catch (e) { _snack("Error al cargar: $e", kDanger); }
    finally { setState(() => _cargando = false); }
  }

  // Obtenemos las ultimas ventas realizadas
  Future<void> _cargarHistorial() async {
    try {
      final res = await http.post(Uri.parse("$kBaseUrl/ventas.php"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"accion": "historial"})).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data["success"] == true) setState(() => _historial = (data["ventas"] as List).map((e) => Venta.fromJson(e)).toList());
    } catch (e) { _snack("Error: $e", kDanger); }
  }

  // Ver los totales vendidos por metodo de pago
  Future<void> _cargarResumen() async {
    try {
      final res = await http.post(Uri.parse("$kBaseUrl/ventas.php"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"accion": "resumen"})).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data["success"] == true) setState(() => _resumen = data);
    } catch (e) { _snack("Error: $e", kDanger); }
  }

  // Mandamos la venta final al servidor para descontar stock
  Future<void> _registrarVenta() async {
    if (_carrito.isEmpty) { _snack("Agrega productos al carrito", kWarning); return; }
    if (_metodoSelec == null) { _snack("Selecciona un método de pago", kWarning); return; }
    if (_tipoVenta == TipoVenta.fiado && _clienteSelec == null) { _snack("Selecciona un cliente para venta fiada", kWarning); return; }

    final total = _carrito.fold<double>(0, (s, i) => s + i.subtotal);
    try {
      final res = await http.post(Uri.parse("$kBaseUrl/ventas.php"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "accion": "registrar",
            "id_usuario": widget.idUsuario,
            "id_metodo_pago": _metodoSelec!.idMetodoPago,
            "tipo_venta": _tipoVenta.valor,
            "id_cliente": _clienteSelec?.idCliente,
            "items": _carrito.map((i) => i.toJson()).toList(),
            "total": total,
          })).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        setState(() { _carrito.clear(); _clienteSelec = null; _tipoVenta = TipoVenta.contado; if (_metodos.isNotEmpty) _metodoSelec = _metodos.first; });
        if (mounted) Navigator.pop(context);
        _snack("Venta registrada correctamente", kSuccess);
        _cargarDatos();
      } else { _snack(data["message"], kDanger); }
    } catch (e) { _snack("Error: $e", kDanger); }
  }

  // Cancela una venta y devuelve los productos al stock
  Future<void> _anularVenta(int idVenta) async {
    try {
      final res = await http.post(Uri.parse("$kBaseUrl/ventas.php"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"accion": "anular", "id_venta": idVenta})).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      _snack(data["message"], data["success"] == true ? kSuccess : kDanger);
      if (data["success"] == true) { _cargarHistorial(); _cargarDatos(); }
    } catch (e) { _snack("Error: $e", kDanger); }
  }

  // Agregamos una unidad del producto al carrito
  void _agregar(ProductoVenta p) {
    setState(() {
      final idx = _carrito.indexWhere((i) => i.producto.id == p.id);
      if (idx >= 0) { if (_carrito[idx].cantidad < p.stock) _carrito[idx].cantidad++; else _snack("Sin más stock", kWarning); }
      else _carrito.add(ItemCarrito(producto: p, cantidad: 1));
    });
  }

  // Quitamos una unidad o el producto completo del carrito
  void _quitar(ProductoVenta p) {
    setState(() {
      final idx = _carrito.indexWhere((i) => i.producto.id == p.id);
      if (idx >= 0) { if (_carrito[idx].cantidad > 1) _carrito[idx].cantidad--; else _carrito.removeAt(idx); }
    });
  }

  int _enCarrito(int id) { final idx = _carrito.indexWhere((i) => i.producto.id == id); return idx >= 0 ? _carrito[idx].cantidad : 0; }
  double get _totalCarrito => _carrito.fold(0, (s, i) => s + i.subtotal);
  int get _cantidadCarrito => _carrito.fold(0, (s, i) => s + i.cantidad);

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: Colors.white)),
    backgroundColor: color, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
  ));

  // Ventana flotante para ver lo que vamos a vender
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
                const Icon(Icons.shopping_cart_rounded, color: kPrimary, size: 22),
                const SizedBox(width: 10),
                const Text("Carrito", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimary)),
                const Spacer(),
                if (_carrito.isNotEmpty) TextButton.icon(
                  onPressed: () { setState(() => _carrito.clear()); setSt(() {}); },
                  icon: const Icon(Icons.delete_sweep_rounded, size: 16), label: const Text("Limpiar"),
                  style: TextButton.styleFrom(foregroundColor: kDanger),
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
                          color: sel ? kPrimary : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? kPrimary : Colors.grey[200]!),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(t == TipoVenta.contado ? Icons.payments_rounded : Icons.handshake_rounded, color: sel ? Colors.white : Colors.grey[500], size: 18),
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
                            color: sel ? kAccent : Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? kAccent : Colors.grey[200]!),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: _clientes.isEmpty
                          ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("Sin clientes registrados", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      )
                          : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _clientes.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        itemBuilder: (_, i) {
                          final cl = _clientes[i];
                          final seleccionado = _clienteSelec?.idCliente == cl.idCliente;
                          return GestureDetector(
                            onTap: () { setSt(() => _clienteSelec = cl); setState(() {}); },
                            child: Container(
                              color: seleccionado ? kAccent.withOpacity(0.08) : Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(children: [
                                CircleAvatar(radius: 14, backgroundColor: kAccent.withOpacity(0.15),
                                    child: Text(cl.nombre[0].toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kAccent))),
                                const SizedBox(width: 10),
                                Expanded(child: Text(cl.nombre, style: TextStyle(fontSize: 14, fontWeight: seleccionado ? FontWeight.w600 : FontWeight.normal, color: const Color(0xFF2C3E50)))),
                                if (cl.saldoPendiente > 0)
                                  Text("\$${cl.saldoPendiente.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12, color: kDanger, fontWeight: FontWeight.w600)),
                                if (seleccionado)
                                  const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.check_circle_rounded, color: kAccent, size: 18)),
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
                    Text("\$${_totalCarrito.toStringAsFixed(0)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimary)),
                  ]),
                  const SizedBox(height: 14),
                  SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
                    onPressed: _registrarVenta,
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text("Confirmar · \$${_totalCarrito.toStringAsFixed(0)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(backgroundColor: kSuccess, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
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
        _btnRedondo(Icons.remove_rounded, () { _quitar(item.producto); setSt(() {}); }, kDanger),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text("${item.cantidad}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        _btnRedondo(Icons.add_rounded, () { _agregar(item.producto); setSt(() {}); }, kSuccess),
      ]),
      const SizedBox(width: 12),
      Text("\$${item.subtotal.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kAccent)),
    ]),
  );

  Widget _btnRedondo(IconData icon, VoidCallback onTap, Color color) => GestureDetector(
    onTap: onTap,
    child: Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 16, color: color)),
  );

  @override
  Widget build(BuildContext context) => Container(
    color: kBg,
    child: Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Ventas", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimary)),
              Text("Registra y gestiona las ventas del día", style: TextStyle(fontSize: 13, color: Colors.grey)),
            ]),
            const Spacer(),
            Stack(children: [
              ElevatedButton.icon(
                onPressed: _abrirCarrito,
                icon: const Icon(Icons.shopping_cart_rounded, size: 20), label: const Text("Carrito"),
                style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              ),
              if (_carrito.isNotEmpty) Positioned(right: 0, top: 0, child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: kDanger, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text("${_carrito.length}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              )),
            ]),
          ]),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabCtrl, labelColor: kPrimary, unselectedLabelColor: Colors.grey,
            indicatorColor: kPrimary, indicatorWeight: 3,
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
    for (final p in filtrados) { porCat.putIfAbsent(p.categoriaNombre, () => []).add(p); }

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: TextField(
        onChanged: (v) => setState(() => _busqueda = v),
        decoration: InputDecoration(
          hintText: "Buscar producto...", hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: kAccent, size: 20),
          filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        ),
      )),
      if (filtrados.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(alignment: Alignment.centerLeft, child: Text("${filtrados.length} productos", style: TextStyle(fontSize: 12, color: Colors.grey[400])))),
      Expanded(
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: kAccent))
            : filtrados.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inventory_2_outlined, size: 52, color: Colors.grey[300]), const SizedBox(height: 12), Text("Sin productos", style: TextStyle(color: Colors.grey[400]))]))
            : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
            child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Column(
              children: porCat.entries.expand((entry) => [
                Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: kPrimary.withOpacity(0.04),
                  child: Row(children: [
                    Icon(_iconoCat(entry.key), color: kPrimary, size: 13),
                    const SizedBox(width: 6),
                    Text(entry.key.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kPrimary, letterSpacing: 0.8)),
                    const SizedBox(width: 8),
                    Text("${entry.value.length}", style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ]),
                ),
                const Divider(height: 1, color: Color(0xFFEEF0F2)),
                ...entry.value.map((p) => Column(children: [
                  _filaProducto(p),
                  const Divider(height: 1, indent: 60, color: Color(0xFFEEF0F2)),
                ])),
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
      color: qty > 0 ? kAccent.withOpacity(0.03) : Colors.white,
      child: InkWell(
        onTap: sinStock ? null : () { _agregar(p); setState(() {}); },
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11), child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: sinStock ? Colors.grey[100] : kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(_iconoCat(p.categoriaNombre), color: sinStock ? Colors.grey[400] : kAccent, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.nombre, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: sinStock ? Colors.grey[400] : const Color(0xFF2C3E50)), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: sinStock ? Colors.grey[100] : kSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(sinStock ? "Sin stock" : "${p.stock} uds.", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sinStock ? Colors.grey[400] : kSuccess))),
          ])),
          Text("\$${p.precio.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: sinStock ? Colors.grey[400] : kPrimary)),
          const SizedBox(width: 12),
          if (sinStock) const SizedBox(width: 80)
          else if (qty == 0) SizedBox(width: 80, child: ElevatedButton(
            onPressed: () { _agregar(p); setState(() {}); },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0, textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            child: const Text("Agregar"),
          ))
          else SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              _btnRedondo(Icons.remove_rounded, () { _quitar(p); setState(() {}); }, kDanger),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text("$qty", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kPrimary))),
              _btnRedondo(Icons.add_rounded, () { _agregar(p); setState(() {}); }, kSuccess),
            ])),
        ])),
      ),
    );
  }

  Widget _tabHistorial() => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Row(children: [
      const Text("Ventas de hoy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C3E50))),
      const Spacer(),
      TextButton.icon(onPressed: _cargarHistorial, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text("Actualizar"), style: TextButton.styleFrom(foregroundColor: kAccent)),
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
          Text("#${v.idVenta}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(v.metodoPagoNombre.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color))),
          const SizedBox(width: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: v.esFiado ? kDanger.withOpacity(0.1) : kSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(v.tipoVenta.valor.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: v.esFiado ? kDanger : kSuccess))),
        ]),
        subtitle: Padding(padding: const EdgeInsets.only(top: 4),
            child: Text(v.clienteNombre.isNotEmpty ? "Cliente: ${v.clienteNombre}" : "Usuario: ${v.metodoPagoNombre}", style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text("\$${v.total.toStringAsFixed(0)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimary)),
          IconButton(icon: const Icon(Icons.cancel_outlined, color: kDanger, size: 20), onPressed: () => _confirmarAnulacion(v)),
        ]),
      ),
    );
  }

  void _confirmarAnulacion(Venta v) => showDialog(context: context, builder: (_) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: const Row(children: [Icon(Icons.warning_amber_rounded, color: kWarning), SizedBox(width: 8), Text("Anular venta")]),
    content: Text("¿Anular venta #${v.idVenta} por \$${v.total.toStringAsFixed(0)}?\nSe devolverá el stock automáticamente."),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kDanger, foregroundColor: Colors.white, elevation: 0),
          onPressed: () { Navigator.pop(context); _anularVenta(v.idVenta); }, child: const Text("Anular")),
    ],
  ));

  Widget _tabResumen() {
    final resumen = _resumen["resumen"] as List? ?? [];
    final totalDia = double.tryParse(_resumen["total_dia"]?.toString() ?? "0") ?? 0;
    final now = DateTime.now();
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [kPrimary, kAccent], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.today_rounded, color: Colors.white70, size: 18), const SizedBox(width: 8), Text("${now.day}/${now.month}/${now.year}", style: const TextStyle(color: Colors.white70, fontSize: 13))]),
            const SizedBox(height: 12),
            Text("\$${totalDia.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            const Text("Total ventas del día", style: TextStyle(color: Colors.white60, fontSize: 13)),
          ])),
      const SizedBox(height: 20),
      if (resumen.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(children: [
          Icon(Icons.bar_chart_rounded, size: 52, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text("Sin ventas hoy", style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _cargarResumen, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text("Cargar"),
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
        ])))
      else ...[
        const Text("Por método de pago", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C3E50))),
        const SizedBox(height: 12),
        ...resumen.map((r) {
          final sub = double.tryParse(r["subtotal"].toString()) ?? 0;
          final pct = totalDia > 0 ? sub / totalDia : 0.0;
          final color = _colorMetodo(r["metodo_pago"]);
          return Container(
            margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey[100]!)),
            child: Column(children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(_iconoMetodo(r["metodo_pago"]), color: color, size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r["metodo_pago"].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF2C3E50))),
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

  Color _colorMetodo(String nombre) {
    switch (nombre.toLowerCase()) {
      case "efectivo":  return kSuccess;
      case "nequi":     return const Color(0xFF8E44AD);
      case "daviplata": return kWarning;
      default:          return kAccent;
    }
  }

  IconData _iconoMetodo(String nombre) {
    switch (nombre.toLowerCase()) {
      case "efectivo":  return Icons.payments_rounded;
      case "nequi":     return Icons.phone_android_rounded;
      case "daviplata": return Icons.account_balance_wallet_rounded;
      default:          return Icons.receipt_rounded;
    }
  }

  IconData _iconoCat(String cat) {
    switch (cat.toLowerCase()) {
      case "bebidas":   return Icons.local_drink_rounded;
      case "alimentos": return Icons.fastfood_rounded;
      case "aseo":      return Icons.cleaning_services_rounded;
      case "licores":   return Icons.wine_bar_rounded;
      case "snacks":    return Icons.cookie_rounded;
      default:          return Icons.category_rounded;
    }
  }
}