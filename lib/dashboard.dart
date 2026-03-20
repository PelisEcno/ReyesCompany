import 'package:flutter/material.dart';
import 'database_service.dart';
import 'modulo_inventario.dart';
import 'modulo_ventas.dart';
import 'modulo_clientes.dart';
import 'modulo_usuarios.dart';

const _cPrimary  = Color(0xFF1A3A5C);
const _cSidebar  = Color(0xFF162E40);
const _cAccent   = Color(0xFF2563EB);
const _cGreen    = Color(0xFF059669);
const _cOrange   = Color(0xFFD97706);
const _cRed      = Color(0xFFDC2626);
const _cBg       = Color(0xFFF1F5F9);
const _cWhite    = Color(0xFFFFFFFF);
const _cBorder   = Color(0xFFE2E8F0);
const _cText     = Color(0xFF0F172A);
const _cSubtext  = Color(0xFF64748B);
const _cSideText = Color(0xFFCBD5E1);
const _cSideSub  = Color(0xFF64748B);

class UsuarioSesion {
  final String idUsuario;
  final String nombre;
  final String rol;
  final String? idSucursal;
  final String sucursalNombre;
  const UsuarioSesion({required this.idUsuario, required this.nombre, required this.rol, this.idSucursal, this.sucursalNombre = ''});
  bool get esAdminGlobal => idSucursal == null;
}

class DashboardScreen extends StatefulWidget {
  final UsuarioSesion usuario;
  const DashboardScreen({super.key, required this.usuario});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _moduloActivo = 0;
  late String? _sucursalSeleccionada;

  // Nav filtrado por rol: empleado solo ve Inicio, Ventas y Clientes
  List<_NavItem> get _nav {
    final esAdmin = widget.usuario.rol == 'Administrador';
    return [
      const _NavItem(Icons.grid_view_rounded,       'Inicio'),
      const _NavItem(Icons.point_of_sale_rounded,   'Ventas'),
      if (esAdmin) const _NavItem(Icons.inventory_2_rounded, 'Inventario'),
      const _NavItem(Icons.people_alt_rounded,      'Clientes'),
      if (esAdmin) const _NavItem(Icons.manage_accounts_rounded, 'Usuarios'),
    ];
  }

  // Índice real del módulo según rol (el índice en nav cambia si se ocultan items)
  int _indexParaModulo(int moduloReal) {
    final esAdmin = widget.usuario.rol == 'Administrador';
    if (esAdmin) return moduloReal; // Admin: índices 0,1,2,3,4
    // Empleado: Inicio=0, Ventas=1, Clientes=2 (Inventario y Usuarios no existen)
    if (moduloReal == 0) return 0;
    if (moduloReal == 1) return 1;
    if (moduloReal == 3) return 2;
    return 0;
  }

  int _moduloRealDesdeIndex(int navIndex) {
    final esAdmin = widget.usuario.rol == 'Administrador';
    if (esAdmin) return navIndex;
    // Empleado: navIndex 0→inicio, 1→ventas, 2→clientes
    switch (navIndex) {
      case 0: return 0;
      case 1: return 1;
      case 2: return 3;
      default: return 0;
    }
  }

  @override
  void initState() { super.initState(); _sucursalSeleccionada = widget.usuario.idSucursal; }

  @override
  Widget build(BuildContext context) {
    final esMovil = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      backgroundColor: _cBg,
      drawer: esMovil ? Drawer(backgroundColor: _cSidebar, child: _sidebar()) : null,
      appBar: esMovil ? _appBarMovil() : null,
      body: Row(children: [
        if (!esMovil) SizedBox(width: 230, child: _sidebar()),
        Expanded(child: Column(children: [
          if (!esMovil) _topBar(),
          Expanded(child: _contenido()),
        ])),
      ]),
    );
  }

  String get _labelModuloActivo {
    switch (_moduloActivo) {
      case 0: return 'Inicio';
      case 1: return 'Ventas';
      case 2: return 'Inventario';
      case 3: return 'Clientes';
      case 4: return 'Usuarios';
      default: return 'Inicio';
    }
  }

  PreferredSizeWidget _appBarMovil() => AppBar(
    backgroundColor: _cSidebar, foregroundColor: Colors.white, elevation: 0,
    title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_labelModuloActivo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      Text(_etiquetaSucursal(), style: const TextStyle(fontSize: 11, color: _cSideSub)),
    ]),
    actions: [Padding(padding: const EdgeInsets.only(right: 12), child: _avatar(16))],
  );

  Widget _sidebar() => Container(
    color: _cSidebar,
    child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(18, 26, 18, 18), child: Row(children: [
        Container(width: 38, height: 38,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ReyesCompany', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          Text(_etiquetaSucursal(), style: const TextStyle(color: _cSideSub, fontSize: 10), overflow: TextOverflow.ellipsis),
        ])),
      ])),
      Divider(color: Colors.white.withOpacity(0.08), height: 1),
      const SizedBox(height: 10),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _nav.length,
        itemBuilder: (_, i) {
          final moduloReal = _moduloRealDesdeIndex(i);
          final activo     = _moduloActivo == moduloReal;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 3),
            decoration: BoxDecoration(
              color: activo ? Colors.white.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: activo ? Colors.white.withOpacity(0.15) : Colors.transparent),
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              leading: Icon(_nav[i].icono, color: activo ? Colors.white : _cSideSub, size: 18),
              title: Text(_nav[i].label, style: TextStyle(color: activo ? Colors.white : _cSideText, fontWeight: activo ? FontWeight.w600 : FontWeight.normal, fontSize: 13)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onTap: () {
                setState(() => _moduloActivo = moduloReal);
                if (MediaQuery.of(context).size.width < 768) Navigator.pop(context);
              },
            ),
          );
        },
      )),
      Divider(color: Colors.white.withOpacity(0.08), height: 1),
      Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        _avatar(17), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.usuario.nombre.isNotEmpty ? widget.usuario.nombre : 'Usuario',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          Text(widget.usuario.rol, style: const TextStyle(color: _cSideSub, fontSize: 10)),
        ])),
        IconButton(icon: Icon(Icons.logout_rounded, color: Colors.white.withOpacity(0.4), size: 18),
            onPressed: () async { await DatabaseService().logout(); Navigator.pushReplacementNamed(context, '/login'); }),
      ])),
    ]),
  );

  Widget _topBar() => Container(
    height: 58, padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: const BoxDecoration(color: _cWhite, border: Border(bottom: BorderSide(color: _cBorder))),
    child: Row(children: [
      Text(_labelModuloActivo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _cText)),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: widget.usuario.esAdminGlobal ? _selectorSucursal : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: _cGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: _cGreen.withOpacity(0.2))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: _cGreen, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(_etiquetaSucursal(), style: const TextStyle(fontSize: 11, color: _cGreen, fontWeight: FontWeight.w600)),
            if (widget.usuario.esAdminGlobal) ...[const SizedBox(width: 3), const Icon(Icons.expand_more_rounded, size: 14, color: _cGreen)],
          ]),
        ),
      ),
      const Spacer(),
      Text(_fechaHoyLabel(), style: const TextStyle(color: _cSubtext, fontSize: 12)),
      const SizedBox(width: 16),
      _avatar(17), const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(widget.usuario.nombre.isNotEmpty ? widget.usuario.nombre : 'Usuario', style: const TextStyle(color: _cText, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(widget.usuario.rol, style: const TextStyle(color: _cSubtext, fontSize: 10)),
      ]),
    ]),
  );

  void _selectorSucursal() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: _cWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Seleccionar vista', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _cText)),
          const SizedBox(height: 16),
          _opcionSucursal(null, 'Todas las sucursales', Icons.store_mall_directory_rounded),
          const SizedBox(height: 8),
          _opcionSucursal('sucursal_1', 'Sucursal Principal', Icons.store_rounded),
          const SizedBox(height: 8),
          _opcionSucursal('sucursal_2', 'Sucursal 2', Icons.store_rounded),
        ]),
      ),
    );
  }

  Widget _opcionSucursal(String? id, String nombre, IconData icono) {
    final sel = _sucursalSeleccionada == id;
    return GestureDetector(
      onTap: () { setState(() => _sucursalSeleccionada = id); Navigator.pop(context); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: sel ? _cAccent.withOpacity(0.06) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? _cAccent.withOpacity(0.3) : _cBorder),
        ),
        child: Row(children: [
          Icon(icono, color: sel ? _cAccent : _cSubtext, size: 18), const SizedBox(width: 12),
          Text(nombre, style: TextStyle(color: sel ? _cText : _cSubtext, fontWeight: sel ? FontWeight.w600 : FontWeight.normal, fontSize: 14)),
          const Spacer(),
          if (sel) const Icon(Icons.check_circle_rounded, color: _cAccent, size: 16),
        ]),
      ),
    );
  }

  Widget _contenido() {
    // Usuario con sucursal asignada → SIEMPRE su sucursal, no puede cambiar
    // Admin global → usa el selector (_sucursalSeleccionada puede ser null = todas)
    final String? sucFiltro = widget.usuario.esAdminGlobal
        ? _sucursalSeleccionada
        : widget.usuario.idSucursal;
    final sucKey = sucFiltro ?? 'todas';

    switch (_moduloActivo) {
      case 0: return ModuloInicio(
          key: ValueKey('inicio_$sucKey'),
          idSucursal: sucFiltro,
          sucursalNombre: _etiquetaSucursal(),
          idUsuario: widget.usuario.idUsuario);
      case 1: return ModuloVentas(
          key: ValueKey('ventas_$sucKey'),
          idUsuario: widget.usuario.idUsuario,
          idSucursal: sucFiltro ?? 'sucursal_1');
      case 2: return ModuloInventario(
          key: ValueKey('inventario_$sucKey'),
          idSucursal: sucFiltro,
          esAdminGlobal: widget.usuario.esAdminGlobal);
      case 3: return ModuloClientes(
          key: ValueKey('clientes_$sucKey'),
          idUsuario: widget.usuario.idUsuario,
          idSucursal: sucFiltro ?? 'sucursal_1');
      case 4: return ModuloUsuarios(
          key: ValueKey('usuarios_$sucKey'),
          idUsuarioActual: widget.usuario.idUsuario,
          esAdminGlobal: widget.usuario.esAdminGlobal);
      default: return ModuloInicio(
          key: ValueKey('inicio_$sucKey'),
          idSucursal: sucFiltro,
          sucursalNombre: _etiquetaSucursal(),
          idUsuario: widget.usuario.idUsuario);
    }
  }

  Widget _avatar(double radius) {
    final inicial = widget.usuario.nombre.isNotEmpty ? widget.usuario.nombre[0].toUpperCase() : 'U';
    return CircleAvatar(radius: radius, backgroundColor: _cAccent,
        child: Text(inicial, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: radius * 0.75)));
  }

  String _etiquetaSucursal() {
    if (!widget.usuario.esAdminGlobal) return widget.usuario.sucursalNombre;
    if (_sucursalSeleccionada == null) return 'Todas las sucursales';
    if (_sucursalSeleccionada == 'sucursal_1') return 'Sucursal Principal';
    if (_sucursalSeleccionada == 'sucursal_2') return 'Sucursal 2';
    return _sucursalSeleccionada!;
  }

  String _fechaHoyLabel() {
    final n = DateTime.now();
    const d = ['','Lun','Mar','Mié','Jue','Vie','Sáb','Dom'];
    const m = ['','Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${d[n.weekday]} ${n.day} ${m[n.month]} ${n.year}';
  }
}

class _NavItem { final IconData icono; final String label; const _NavItem(this.icono, this.label); }

class ModuloInicio extends StatefulWidget {
  final String? idSucursal;
  final String sucursalNombre;
  final String idUsuario;
  const ModuloInicio({super.key, this.idSucursal, this.sucursalNombre = '', required this.idUsuario});
  @override
  State<ModuloInicio> createState() => _ModuloInicioState();
}

class _ModuloInicioState extends State<ModuloInicio> {
  final _svc = DatabaseService();
  bool _cargando = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() { super.initState(); _cargar(); }

  @override
  void didUpdateWidget(ModuloInicio old) {
    super.didUpdateWidget(old);
    if (old.idSucursal != widget.idSucursal) _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final d = await _svc.getResumenDia(idSucursal: widget.idSucursal);
      setState(() => _data = d);
    } catch (_) {}
    finally { if (mounted) setState(() => _cargando = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: _cAccent));

    final totalVentas   = _num("total_ventas");    // Solo contado
    final totalAbonos   = _num("total_abonos");    // Cobros de deudas
    final totalDia      = _num("total_dia");       // Contado + Abonos
    final totalFiados   = _num("total_fiados_hoy");// Deuda generada hoy
    final cantVentas    = _int("cantidad_ventas");
    final cantAbonos    = _int("cantidad_abonos");
    final cantFiados    = _int("cantidad_fiados_hoy");
    final stockBajo     = _int("stock_bajo");
    final clienteDeuda  = _int("clientes_con_deuda");
    final totalDeuda    = _num("total_deuda");
    final metodos       = (_data["ventas_por_metodo"] as List?) ?? [];
    final movimientos   = (_data["movimientos"] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _cargar, color: _cAccent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Resumen del día', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _cText)),
              Text(_fechaHoyLabel(), style: const TextStyle(fontSize: 12, color: _cSubtext)),
            ]),
            const Spacer(),
            if (widget.sucursalNombre.isNotEmpty)
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _cGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: _cGreen.withOpacity(0.2))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: _cGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(widget.sucursalNombre, style: const TextStyle(fontSize: 11, color: _cGreen, fontWeight: FontWeight.w600)),
                  ])),
            const SizedBox(width: 8),
            GestureDetector(onTap: _cargar, child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _cWhite, borderRadius: BorderRadius.circular(10), border: Border.all(color: _cBorder)),
              child: const Icon(Icons.refresh_rounded, color: _cSubtext, size: 16),
            )),
          ]),
          const SizedBox(height: 22),

          LayoutBuilder(builder: (_, c) {
            if (c.maxWidth > 680) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 5, child: _cardHero(totalDia, totalVentas, totalAbonos, cantVentas, cantAbonos)),
                const SizedBox(width: 14),
                Expanded(flex: 3, child: Column(children: [
                  _cardCartera(clienteDeuda, totalDeuda),
                  if (cantFiados > 0) ...[
                    const SizedBox(height: 14),
                    _cardFiadosHoy(totalFiados, cantFiados),
                  ],
                ])),
              ]);
            }
            return Column(children: [
              _cardHero(totalDia, totalVentas, totalAbonos, cantVentas, cantAbonos),
              const SizedBox(height: 14),
              _cardCartera(clienteDeuda, totalDeuda),
              if (cantFiados > 0) ...[
                const SizedBox(height: 14),
                _cardFiadosHoy(totalFiados, cantFiados),
              ],
            ]);
          }),
          const SizedBox(height: 14),

          Row(children: [
            _metrica('\$${_fmt(totalVentas)}', 'Ventas contado', '$cantVentas transac.', Icons.trending_up_rounded, _cAccent),
            const SizedBox(width: 12),
            _metrica('\$${_fmt(totalAbonos)}', 'Abonos cobrados', '$cantAbonos pagos', Icons.payments_rounded, _cGreen),
            const SizedBox(width: 12),
            _metrica('$stockBajo', 'Stock bajo', 'productos', Icons.warning_amber_rounded, stockBajo > 0 ? _cRed : _cSubtext),
          ]),
          const SizedBox(height: 22),

          if (metodos.isNotEmpty) ...[
            _labelSeccion('Desglose por método de pago (contado)'),
            const SizedBox(height: 10),
            _cardMetodos(metodos, totalVentas),
            const SizedBox(height: 22),
          ],

          Row(children: [
            _labelSeccion('Movimientos del día'),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _cAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                child: Text('${movimientos.length} registro${movimientos.length != 1 ? "s" : ""}',
                    style: const TextStyle(fontSize: 11, color: _cAccent, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 10),
          movimientos.isEmpty ? _vacioMovimientos() : _tablaMovimientos(movimientos),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _cardHero(double totalDia, double ventas, double abonos, int cantV, int cantA) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF1E40AF), Color(0xFF1D4ED8), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: _cAccent.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Total del día', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.circle, size: 7, color: Color(0xFF4ADE80)), SizedBox(width: 5),
              Text('En vivo', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            ])),
      ]),
      const SizedBox(height: 10),
      Text('\$${_fmt(totalDia)}', style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.5)),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: _chipHero(Icons.point_of_sale_rounded, 'Ventas', '\$${_fmt(ventas)}', '$cantV operac.')),
        const SizedBox(width: 10),
        Expanded(child: _chipHero(Icons.payments_rounded, 'Cobros', '\$${_fmt(abonos)}', '$cantA abonos')),
      ]),
    ]),
  );

  Widget _chipHero(IconData icono, String label, String valor, String sub) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Icon(icono, color: Colors.white70, size: 16), const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(valor, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        Text(sub, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ])),
    ]),
  );

  Widget _cardCartera(int clientes, double deuda) {
    final hayDeuda = clientes > 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _cWhite, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: hayDeuda ? _cOrange.withOpacity(0.3) : _cBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (hayDeuda ? _cOrange : _cGreen).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.account_balance_wallet_rounded, color: hayDeuda ? _cOrange : _cGreen, size: 18)),
          const SizedBox(width: 10),
          const Text('Cartera fiados', style: TextStyle(color: _cSubtext, fontSize: 13)),
        ]),
        const SizedBox(height: 14),
        Text('\$${_fmt(deuda)}', style: TextStyle(color: hayDeuda ? _cOrange : _cGreen, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.people_alt_rounded, size: 13, color: hayDeuda ? _cOrange : _cSubtext), const SizedBox(width: 5),
          Text('$clientes cliente${clientes != 1 ? "s" : ""} con deuda', style: TextStyle(color: hayDeuda ? _cOrange : _cSubtext, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _cardFiadosHoy(double total, int cantidad) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _cWhite, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _cRed.withOpacity(0.25)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _cRed.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.handshake_rounded, color: _cRed, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Fiados hoy', style: TextStyle(color: _cSubtext, fontSize: 12)),
        Text('\$${_fmt(total)}', style: const TextStyle(color: _cRed, fontSize: 20, fontWeight: FontWeight.w800)),
        Text('$cantidad venta${cantidad != 1 ? "s" : ""} a crédito · no es dinero recibido',
            style: const TextStyle(color: _cSubtext, fontSize: 10)),
      ])),
    ]),
  );

  Widget _metrica(String valor, String label, String sub, IconData icono, Color color) => Expanded(
    child: Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _cWhite, borderRadius: BorderRadius.circular(14), border: Border.all(color: _cBorder),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)), child: Icon(icono, color: color, size: 15)),
          const SizedBox(height: 10),
          Text(valor, style: const TextStyle(color: _cText, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: _cText, fontSize: 11, fontWeight: FontWeight.w500)),
          Text(sub, style: const TextStyle(color: _cSubtext, fontSize: 10)),
        ])),
  );

  Widget _cardMetodos(List metodos, double totalVentas) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: _cWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: _cBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]),
    child: Column(children: List.generate(metodos.length, (i) {
      final m     = metodos[i];
      final sub   = (m["subtotal"] as num?)?.toDouble() ?? 0;
      final pct   = totalVentas > 0 ? sub / totalVentas : 0.0;
      final color = _colorMetodo(m["metodo"]?.toString() ?? "");
      final cant  = (m["cantidad"] as num?)?.toInt() ?? 0;
      return Padding(
        padding: EdgeInsets.only(bottom: i < metodos.length - 1 ? 16 : 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(_iconoMetodo(m["metodo"]?.toString() ?? ""), color: color, size: 14)),
            const SizedBox(width: 10),
            Expanded(child: Text(m["metodo"]?.toString() ?? "", style: const TextStyle(color: _cText, fontWeight: FontWeight.w600, fontSize: 13))),
            Text('$cant venta${cant != 1 ? "s" : ""}', style: const TextStyle(color: _cSubtext, fontSize: 11)),
            const SizedBox(width: 12),
            Text('\$${_fmt(sub)}', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct.toDouble(), minHeight: 5, backgroundColor: color.withOpacity(0.08), valueColor: AlwaysStoppedAnimation<Color>(color)))),
            const SizedBox(width: 10),
            Text('${(pct * 100).toStringAsFixed(0)}%', style: const TextStyle(color: _cSubtext, fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
          if (i < metodos.length - 1) ...[const SizedBox(height: 16), const Divider(color: _cBorder, height: 1)],
        ]),
      );
    })),
  );

  Widget _tablaMovimientos(List movimientos) => Container(
    decoration: BoxDecoration(color: _cWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: _cBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]),
    child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Column(
      children: List.generate(movimientos.length, (i) {
        final m       = movimientos[i];
        final esVenta = m["tipo"] == "venta";
        final monto   = (m["monto"] as num?)?.toDouble() ?? 0;
        final color   = esVenta ? _cAccent : _cGreen;
        final icono   = esVenta ? Icons.point_of_sale_rounded : Icons.payments_rounded;
        final titulo  = esVenta ? "Venta #${(m["id"] as String?)?.substring(0, 6) ?? ""}" : "Abono";
        final metodo  = m["metodo"]?.toString() ?? "";
        final cliente = m["nombre_cliente"]?.toString() ?? "";
        final usuario = m["usuario"]?.toString() ?? "";
        final sucursal = m["sucursal"]?.toString() ?? "";
        final obs     = m["observacion"]?.toString() ?? "";
        final partes  = <String>[];
        if (cliente.isNotEmpty && cliente != 'Contado') partes.add(cliente);
        if (metodo.isNotEmpty && metodo != 'Abono') partes.add(metodo);
        if (usuario.isNotEmpty) partes.add(usuario);
        if (sucursal.isNotEmpty) partes.add(sucursal);
        if (obs.isNotEmpty) partes.add(obs);

        return Column(children: [
          Container(
            color: i.isOdd ? const Color(0xFFFAFBFF) : _cWhite,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Icon(icono, color: color, size: 16)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(titulo, style: const TextStyle(color: _cText, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(width: 7),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                      child: Text(esVenta ? (metodo.isNotEmpty ? metodo : 'Venta') : 'Abono', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.2))),
                ]),
                if (partes.isNotEmpty) Text(partes.join(' · '), style: const TextStyle(color: _cSubtext, fontSize: 11), overflow: TextOverflow.ellipsis),
              ])),
              Text('\$${_fmt(monto)}', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
          ),
          if (i < movimientos.length - 1) const Divider(height: 1, color: _cBorder),
        ]);
      }),
    )),
  );

  Widget _vacioMovimientos() => Container(
    width: double.infinity, padding: const EdgeInsets.all(36),
    decoration: BoxDecoration(color: _cWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: _cBorder)),
    child: Column(children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle), child: const Icon(Icons.receipt_long_outlined, size: 30, color: _cSubtext)),
      const SizedBox(height: 12),
      const Text('Sin movimientos hoy', style: TextStyle(color: _cText, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      const Text('Las ventas y abonos del día aparecerán aquí', style: TextStyle(color: _cSubtext, fontSize: 12)),
    ]),
  );

  Widget _labelSeccion(String t) => Text(t, style: const TextStyle(color: _cText, fontSize: 14, fontWeight: FontWeight.w700));

  Color _colorMetodo(String n) {
    switch (n.toLowerCase()) {
      case 'efectivo': return _cGreen;
      case 'nequi': return const Color(0xFF7C3AED);
      case 'daviplata': return _cOrange;
      case 'fiado': return _cRed;
      default: return _cAccent;
    }
  }

  IconData _iconoMetodo(String n) {
    switch (n.toLowerCase()) {
      case 'efectivo': return Icons.payments_rounded;
      case 'nequi': return Icons.phone_android_rounded;
      case 'daviplata': return Icons.account_balance_wallet_rounded;
      case 'fiado': return Icons.handshake_rounded;
      default: return Icons.credit_card_rounded;
    }
  }

  double _num(String k) => ((_data[k]) as num?)?.toDouble() ?? 0;
  int    _int(String k) => ((_data[k]) as num?)?.toInt()    ?? 0;
  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}K';
    return v.toStringAsFixed(0);
  }

  String _fechaHoyLabel() {
    final n = DateTime.now();
    const d = ['','Lun','Mar','Mié','Jue','Vie','Sáb','Dom'];
    const m = ['','Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${d[n.weekday]} ${n.day} ${m[n.month]} ${n.year}';
  }
}