import 'package:flutter/material.dart';
import 'database_service.dart';
import 'models.dart';

const kPrimary = Color(0xFF1A5276);
const kAccent  = Color(0xFF2E86C1);
const kSuccess = Color(0xFF1ABC9C);
const kDanger  = Color(0xFFE74C3C);
const kBg      = Color(0xFFF0F4F8);

class ModuloInventario extends StatefulWidget {
  final String? idSucursal;
  final bool esAdminGlobal;
  const ModuloInventario({super.key, this.idSucursal, this.esAdminGlobal = false});
  @override
  State<ModuloInventario> createState() => _ModuloInventarioState();
}

class _ModuloInventarioState extends State<ModuloInventario> {
  final _svc = DatabaseService();
  List<Producto>  _productos  = [];
  List<Producto>  _filtrados  = [];
  List<Categoria> _categorias = [];
  List<Sucursal>  _sucursales = [];
  bool   _cargando  = true;
  String _busqueda  = "";
  String _catFiltro = "";

  // La sucursal activa viene del widget (dashboard selector)
  String? get _sucursalActiva => widget.idSucursal;

  @override
  void initState() { super.initState(); _cargarDatos(); }

  @override
  void didUpdateWidget(ModuloInventario old) {
    super.didUpdateWidget(old);
    // El key en dashboard ya recrea el widget, pero por seguridad también recargamos aquí
    if (old.idSucursal != widget.idSucursal) _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final results = await Future.wait([
        _svc.getProductos(idSucursal: _sucursalActiva),
        _svc.getCategorias(),
        _svc.getSucursales(),
      ]);
      setState(() {
        _productos  = results[0] as List<Producto>;
        _categorias = results[1] as List<Categoria>;
        _sucursales = results[2] as List<Sucursal>;
        _aplicarFiltro();
      });
    } catch (e) { _snack("Error al cargar: $e", kDanger); }
    finally { if (mounted) setState(() => _cargando = false); }
  }

  void _aplicarFiltro() {
    setState(() {
      _filtrados = _productos.where((p) {
        final okBusq = p.nombre.toLowerCase().contains(_busqueda.toLowerCase());
        final okCat  = _catFiltro.isEmpty || p.idCategoria == _catFiltro;
        return okBusq && okCat;
      }).toList();
    });
  }

  Future<void> _guardar(Map<String, dynamic> datos, {String? idEditar}) async {
    try {
      final idSuc = datos["id_sucursal"] as String?;
      if (idSuc == null || idSuc.isEmpty) { _snack("Debes seleccionar una sucursal", kDanger); return; }
      final cat = _categorias.firstWhere((c) => c.idCategoria == datos["id_categoria"],
          orElse: () => Categoria(id: '', nombre: ''));

      if (idEditar == null) {
        await _svc.crearProducto(
          nombre: datos["nombre"], descripcion: datos["descripcion"],
          idCategoria: datos["id_categoria"], categoriaNombre: cat.nombre,
          precioCompra: datos["precio_compra"], precioVenta: datos["precio_venta"],
          stockInicial: datos["stock_actual"], stockMinimo: datos["stock_minimo"],
          idSucursal: idSuc,
        );
        _snack("Producto creado en ${_nombreSucursal(idSuc)}", kSuccess);
      } else {
        await _svc.editarProducto(
          idProducto: idEditar, nombre: datos["nombre"], descripcion: datos["descripcion"],
          idCategoria: datos["id_categoria"], categoriaNombre: cat.nombre,
          precioCompra: datos["precio_compra"], precioVenta: datos["precio_venta"],
          stockActual: datos["stock_actual"], stockMinimo: datos["stock_minimo"],
          idSucursal: idSuc,
        );
        _snack("Producto actualizado", kSuccess);
      }
      _cargarDatos();
    } catch (e) { _snack("Error: $e", kDanger); }
  }

  Future<void> _eliminar(String id) async {
    try { await _svc.eliminarProducto(id); _snack("Producto eliminado", kSuccess); _cargarDatos(); }
    catch (e) { _snack("Error: $e", kDanger); }
  }

  String _nombreSucursal(String? id) {
    if (id == null) return 'Todas';
    return _sucursales.firstWhere((s) => s.idSucursal == id,
        orElse: () => Sucursal(id: id, nombre: id)).nombre;
  }

  String _etiquetaSucursal() => _nombreSucursal(_sucursalActiva);

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _abrirFormulario({Producto? p}) {
    // Al editar, preseleccionar la sucursal activa; si es "todas", pedir que elija
    String? sucSel = _sucursalActiva ?? (_sucursales.isNotEmpty ? _sucursales.first.idSucursal : null);
    final nombreC   = TextEditingController(text: p?.nombre ?? "");
    final descC     = TextEditingController(text: p?.descripcion ?? "");
    final pCompraC  = TextEditingController(text: p != null ? p.precioCompra.toStringAsFixed(0) : "");
    final pVentaC   = TextEditingController(text: p != null ? p.precioVenta.toStringAsFixed(0) : "");
    final stockC    = TextEditingController(text: p?.stockActual.toString() ?? "0");
    final stockMinC = TextEditingController(text: p?.stockMinimo.toString() ?? "5");
    String catSel   = p?.idCategoria ?? (_categorias.isNotEmpty ? _categorias.first.idCategoria : "");
    final formKey   = GlobalKey<FormState>();

    showDialog(context: context, barrierDismissible: false,
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(padding: const EdgeInsets.all(28),
            child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Row(children: [
                Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(p == null ? Icons.add_box_rounded : Icons.edit_rounded, color: kPrimary, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Text(p == null ? "Nuevo producto" : "Editar producto",
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kPrimary))),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: Colors.grey)),
              ]),
              const SizedBox(height: 16), const Divider(height: 1), const SizedBox(height: 20),

              // Nombre + Categoría
              Row(children: [
                Expanded(child: _field(nombreC, "Nombre *", obligatorio: true)),
                const SizedBox(width: 12),
                Expanded(child: DropdownButtonFormField<String>(
                  value: catSel.isEmpty ? null : catSel,
                  decoration: _deco("Categoría *"),
                  validator: (v) => (v == null || v.isEmpty) ? "Obligatorio" : null,
                  items: _categorias.map((c) => DropdownMenuItem(value: c.idCategoria, child: Text(c.nombre, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setSt(() => catSel = v ?? ""),
                )),
              ]),
              const SizedBox(height: 12),
              _field(descC, "Descripción"),
              const SizedBox(height: 12),

              // Precios
              Row(children: [
                Expanded(child: _field(pCompraC, "P. compra *", obligatorio: true, esNum: true, prefijo: "\$")),
                const SizedBox(width: 12),
                Expanded(child: _field(pVentaC, "P. venta *", obligatorio: true, esNum: true, prefijo: "\$")),
              ]),
              const SizedBox(height: 12),

              // Stock
              Row(children: [
                Expanded(child: _field(stockC, "Stock *", obligatorio: true, esNum: true)),
                const SizedBox(width: 12),
                Expanded(child: _field(stockMinC, "Stock mínimo", esNum: true)),
              ]),
              const SizedBox(height: 12),

              // Sucursal — siempre visible, obligatorio
              DropdownButtonFormField<String>(
                value: sucSel,
                decoration: _deco("Sucursal del stock *"),
                validator: (v) => (v == null || v.isEmpty) ? "Selecciona una sucursal" : null,
                items: _sucursales.map((s) => DropdownMenuItem(
                  value: s.idSucursal,
                  child: Row(children: [
                    const Icon(Icons.store_rounded, size: 15, color: kAccent), const SizedBox(width: 8),
                    Text(s.nombre, style: const TextStyle(fontSize: 14)),
                  ]),
                )).toList(),
                onChanged: (v) => setSt(() => sucSel = v),
              ),

              const SizedBox(height: 24), const Divider(height: 1), const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx);
                    _guardar({
                      "nombre":        nombreC.text.trim(),
                      "descripcion":   descC.text.trim(),
                      "id_categoria":  catSel,
                      "precio_compra": double.tryParse(pCompraC.text) ?? 0,
                      "precio_venta":  double.tryParse(pVentaC.text)  ?? 0,
                      "stock_actual":  int.tryParse(stockC.text)      ?? 0,
                      "stock_minimo":  int.tryParse(stockMinC.text)   ?? 5,
                      "id_sucursal":   sucSel,
                    }, idEditar: p?.idProducto);
                  },
                  icon: Icon(p == null ? Icons.add_rounded : Icons.save_rounded, size: 18),
                  label: Text(p == null ? "Crear" : "Guardar"),
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                ),
              ]),
            ])),
          ),
        ),
      )),
    );
  }

  void _confirmarEliminar(Producto p) => showDialog(context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [Icon(Icons.warning_amber_rounded, color: kDanger), SizedBox(width: 8), Text("Eliminar producto")]),
      content: RichText(text: TextSpan(style: const TextStyle(color: Colors.black87, fontSize: 14), children: [
        const TextSpan(text: "¿Eliminar "),
        TextSpan(text: p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(text: "?\nSe elimina de todas las sucursales. Esta acción no se puede deshacer."),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kDanger, foregroundColor: Colors.white, elevation: 0),
            onPressed: () { Navigator.pop(context); _eliminar(p.idProducto); }, child: const Text("Eliminar")),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final stockBajo = _filtrados.where((p) => p.estaEnStockMinimo()).length;
    return Container(
      color: kBg, padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Inventario", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimary)),
            Text(_etiquetaSucursal(), style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
          const Spacer(),
          if (stockBajo > 0) ...[
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: kDanger.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: kDanger.withOpacity(0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.warning_amber_rounded, color: kDanger, size: 15), const SizedBox(width: 5),
                  Text("$stockBajo stock bajo", style: const TextStyle(color: kDanger, fontSize: 12, fontWeight: FontWeight.w600)),
                ])),
            const SizedBox(width: 10),
          ],
          ElevatedButton.icon(onPressed: _abrirFormulario,
              icon: const Icon(Icons.add_rounded, size: 18), label: const Text("Nuevo producto"),
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0)),
        ]),
        const SizedBox(height: 20),

        // Métricas
        Row(children: [
          _metrica("Total", "${_filtrados.length}", Icons.inventory_2_rounded, kAccent),
          const SizedBox(width: 12),
          _metrica("Stock bajo", "$stockBajo", Icons.warning_amber_rounded, kDanger),
          const SizedBox(width: 12),
          _metrica("Categorías", "${_categorias.length}", Icons.category_rounded, kSuccess),
        ]),
        const SizedBox(height: 16),

        // Búsqueda y filtros
        Row(children: [
          Expanded(child: SizedBox(height: 44, child: TextField(
            onChanged: (v) { _busqueda = v; _aplicarFiltro(); },
            decoration: InputDecoration(
              hintText: "Buscar producto...", hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: kAccent, size: 20),
              filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            ),
          ))),
          const SizedBox(width: 10),
          Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: _catFiltro.isEmpty ? "" : _catFiltro,
                style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 13),
                items: [
                  const DropdownMenuItem(value: "", child: Text("Todas")),
                  ..._categorias.map((c) => DropdownMenuItem(value: c.idCategoria, child: Text(c.nombre))),
                ],
                onChanged: (v) { setState(() => _catFiltro = v ?? ""); _aplicarFiltro(); },
              ))),
          const SizedBox(width: 8),
          SizedBox(height: 44, width: 44, child: OutlinedButton(
            onPressed: _cargarDatos,
            style: OutlinedButton.styleFrom(padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.grey[200]!), backgroundColor: Colors.white),
            child: const Icon(Icons.refresh_rounded, color: kAccent, size: 20),
          )),
        ]),
        const SizedBox(height: 16),

        // Tabla
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator(color: kAccent))
              : _filtrados.isEmpty
              ? _estadoVacio()
              : LayoutBuilder(builder: (ctx, cons) => Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
            child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Column(children: [
              if (cons.maxWidth > 650) ...[
                Container(color: const Color(0xFFF8FAFB), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: _cabeceraTabla()),
                const Divider(height: 1, color: Color(0xFFEEF0F2)),
              ],
              Expanded(child: ListView.separated(
                itemCount: _filtrados.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEF0F2)),
                itemBuilder: (_, i) => cons.maxWidth > 650 ? _filaWeb(_filtrados[i]) : _filaMovil(_filtrados[i]),
              )),
            ])),
          )),
        ),
      ]),
    );
  }

  Widget _cabeceraTabla() {
    const s = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.8);
    return const Row(children: [
      Expanded(flex: 4, child: Text("PRODUCTO",  style: s)),
      Expanded(flex: 2, child: Text("CATEGORÍA", style: s)),
      Expanded(flex: 2, child: Text("P. COMPRA", style: s, textAlign: TextAlign.right)),
      Expanded(flex: 2, child: Text("P. VENTA",  style: s, textAlign: TextAlign.right)),
      Expanded(flex: 2, child: Text("GANANCIA",  style: s, textAlign: TextAlign.right)),
      Expanded(flex: 1, child: Text("STOCK",     style: s, textAlign: TextAlign.center)),
      SizedBox(width: 72),
    ]);
  }

  Widget _filaWeb(Producto p) => Container(
    color: p.estaEnStockMinimo() ? kDanger.withOpacity(0.03) : Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
    child: Row(children: [
      Expanded(flex: 4, child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(_iconoCat(p.categoriaNombre), color: kAccent, size: 17)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2C3E50)), overflow: TextOverflow.ellipsis),
          if (p.descripcion.isNotEmpty) Text(p.descripcion, style: TextStyle(fontSize: 11, color: Colors.grey[400]), overflow: TextOverflow.ellipsis),
        ])),
      ])),
      Expanded(flex: 2, child: Text(p.categoriaNombre, style: TextStyle(fontSize: 13, color: Colors.grey[500]), overflow: TextOverflow.ellipsis)),
      Expanded(flex: 2, child: Text("\$${p.precioCompra.toStringAsFixed(0)}", style: TextStyle(fontSize: 13, color: Colors.grey[500]), textAlign: TextAlign.right)),
      Expanded(flex: 2, child: Text("\$${p.precioVenta.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kAccent), textAlign: TextAlign.right)),
      Expanded(flex: 2, child: Text("\$${p.ganancia.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kSuccess), textAlign: TextAlign.right)),
      Expanded(flex: 1, child: Center(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: p.estaEnStockMinimo() ? kDanger.withOpacity(0.1) : kSuccess.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20)),
        child: Text("${p.stockActual}", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
            color: p.estaEnStockMinimo() ? kDanger : kSuccess), textAlign: TextAlign.center),
      ))),
      SizedBox(width: 72, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        _iconBtn(Icons.edit_rounded,   kAccent,  () => _abrirFormulario(p: p)),
        _iconBtn(Icons.delete_rounded, kDanger,  () => _confirmarEliminar(p)),
      ])),
    ]),
  );

  Widget _filaMovil(Producto p) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(_iconoCat(p.categoriaNombre), color: kAccent, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2C3E50)), overflow: TextOverflow.ellipsis),
        Text("\$${p.precioVenta.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12, color: kAccent, fontWeight: FontWeight.w600)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: p.estaEnStockMinimo() ? kDanger.withOpacity(0.1) : kSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text("${p.stockActual}", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: p.estaEnStockMinimo() ? kDanger : kSuccess))),
        const SizedBox(height: 6),
        Row(children: [
          _iconBtn(Icons.edit_rounded,   kAccent, () => _abrirFormulario(p: p), size: 17),
          _iconBtn(Icons.delete_rounded, kDanger, () => _confirmarEliminar(p),  size: 17),
        ]),
      ]),
    ]),
  );

  Widget _estadoVacio() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: kAccent.withOpacity(0.08), shape: BoxShape.circle),
        child: const Icon(Icons.inventory_2_outlined, size: 52, color: kAccent)),
    const SizedBox(height: 16),
    Text(_sucursalActiva != null ? "Sin productos en ${_etiquetaSucursal()}" : "Sin productos",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
    const SizedBox(height: 8),
    if (_sucursalActiva != null)
      Text("Selecciona 'Todas las sucursales' para ver el catálogo completo",
          style: TextStyle(fontSize: 12, color: Colors.grey[500]), textAlign: TextAlign.center),
    const SizedBox(height: 20),
    ElevatedButton.icon(onPressed: _abrirFormulario, icon: const Icon(Icons.add_rounded, size: 18), label: const Text("Nuevo producto"),
        style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0)),
  ]));

  Widget _metrica(String label, String valor, IconData icono, Color color) => Expanded(
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icono, color: color, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[400]), overflow: TextOverflow.ellipsis),
          ])),
        ])),
  );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap, {double size = 18}) =>
      InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
          child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, color: color, size: size)));

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

  InputDecoration _deco(String label) => InputDecoration(
    labelText: label, labelStyle: const TextStyle(fontSize: 13), filled: true, fillColor: const Color(0xFFF4F6F8),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kAccent, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kDanger, width: 1)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
  );

  Widget _field(TextEditingController ctrl, String label,
      {bool obligatorio = false, bool esNum = false, String? prefijo}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: esNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: const TextStyle(fontSize: 14),
        decoration: _deco(label).copyWith(prefixText: prefijo),
        validator: obligatorio ? (v) => (v == null || v.trim().isEmpty) ? "Obligatorio" : null : null,
      );
}