import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'example.dart' show kBaseUrl;
import 'models.dart';

const _primary = Color(0xFF1A5276);
const _accent  = Color(0xFF2E86C1);
const _success = Color(0xFF1ABC9C);
const _danger  = Color(0xFFE74C3C);
const _warning = Color(0xFFE67E22);
const _bg      = Color(0xFFF0F4F8);

class ModuloClientes extends StatefulWidget {
  const ModuloClientes({super.key});
  @override
  State<ModuloClientes> createState() => _ModuloClientesState();
}

class _ModuloClientesState extends State<ModuloClientes> {
  List<Cliente> _clientes  = [];
  List<Cliente> _filtrados = [];
  bool   _cargando = true;
  String _busqueda = "";

  @override
  void initState() { super.initState(); _cargarClientes(); }

  // Pedimos la lista de clientes al servidor
  Future<void> _cargarClientes() async {
    setState(() => _cargando = true);
    try {
      final res = await http.post(Uri.parse("$kBaseUrl/clientes.php"),
          headers: {"Content-Type": "application/json"}, body: jsonEncode({"accion": "listar"})).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        setState(() {
          _clientes  = (data["clientes"] as List).map((e) => Cliente.fromJson(e)).toList();
          _aplicarFiltro();
        });
      }
    } catch (e) { _snack("Error: $e", _danger); }
    finally { setState(() => _cargando = false); }
  }

  // Guardamos un cliente nuevo o actualizamos sus datos
  Future<void> _guardar(Map<String, dynamic> datos, {int? idEditar}) async {
    datos["accion"] = idEditar == null ? "crear" : "editar";
    if (idEditar != null) datos["id_cliente"] = idEditar;
    try {
      final res = await http.post(Uri.parse("$kBaseUrl/clientes.php"),
          headers: {"Content-Type": "application/json"}, body: jsonEncode(datos)).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      _snack(data["message"], data["success"] == true ? _success : _danger);
      if (data["success"] == true) _cargarClientes();
    } catch (e) { _snack("Error: $e", _danger); }
  }

  // Eliminamos un cliente de la base de datos
  Future<void> _eliminar(int id) async {
    try {
      final res = await http.post(Uri.parse("$kBaseUrl/clientes.php"),
          headers: {"Content-Type": "application/json"}, body: jsonEncode({"accion": "eliminar", "id_cliente": id})).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      _snack(data["message"], data["success"] == true ? _success : _danger);
      if (data["success"] == true) _cargarClientes();
    } catch (e) { _snack("Error: $e", _danger); }
  }

  // Registramos un abono a la deuda del cliente
  Future<void> _abonar(Cliente c, double monto) async {
    try {
      final res = await http.post(Uri.parse("$kBaseUrl/clientes.php"),
          headers: {"Content-Type": "application/json"}, body: jsonEncode({"accion": "abonar", "id_cliente": c.idCliente, "monto": monto})).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      _snack(data["message"], data["success"] == true ? _success : _danger);
      if (data["success"] == true) _cargarClientes();
    } catch (e) { _snack("Error: $e", _danger); }
  }

  // Traemos el historial de lo que debe el cliente
  Future<List<Map<String, dynamic>>> _cargarFiados(int idCliente) async {
    try {
      final res = await http.post(Uri.parse("$kBaseUrl/clientes.php"),
          headers: {"Content-Type": "application/json"}, body: jsonEncode({"accion": "historial_fiados", "id_cliente": idCliente})).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data["success"] == true) return List<Map<String, dynamic>>.from(data["fiados"]);
    } catch (_) {}
    return [];
  }

  // Buscamos clientes en la lista por nombre
  void _aplicarFiltro() {
    setState(() {
      _filtrados = _clientes.where((c) => c.nombre.toLowerCase().contains(_busqueda.toLowerCase())).toList();
    });
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: Colors.white)),
    backgroundColor: color, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
  ));

  void _abrirFormulario({Cliente? c}) {
    final nombreC    = TextEditingController(text: c?.nombre ?? "");
    final telefonoC  = TextEditingController(text: c?.telefono ?? "");
    final direccionC = TextEditingController(text: c?.direccion ?? "");
    final formKey    = GlobalKey<FormState>();

    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(c == null ? Icons.person_add_rounded : Icons.edit_rounded, color: _primary, size: 20)),
                  const SizedBox(width: 12),
                  Text(c == null ? "Nuevo cliente" : "Editar cliente",
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _primary)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.grey)),
                ]),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 20),
                _field(nombreC, "Nombre completo *", Icons.person_rounded, obligatorio: true),
                const SizedBox(height: 12),
                _field(telefonoC, "Teléfono", Icons.phone_rounded, esNum: true),
                const SizedBox(height: 12),
                _field(direccionC, "Dirección", Icons.location_on_rounded),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(context);
                      _guardar({"nombre": nombreC.text.trim(), "telefono": telefonoC.text.trim(), "direccion": direccionC.text.trim()}, idEditar: c?.idCliente);
                    },
                    icon: Icon(c == null ? Icons.add_rounded : Icons.save_rounded, size: 18),
                    label: Text(c == null ? "Registrar" : "Guardar"),
                    style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // Panel para ver los datos y deudas del cliente
  void _abrirDetalle(Cliente c) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65, minChildSize: 0.4, maxChildSize: 0.92,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),

            Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(children: [
              CircleAvatar(radius: 28, backgroundColor: _accent.withOpacity(0.15),
                  child: Text(c.nombre[0].toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _accent))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                if (c.telefono.isNotEmpty) Row(children: [
                  const Icon(Icons.phone_rounded, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(c.telefono, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ]),
                if (c.direccion.isNotEmpty) Row(children: [
                  const Icon(Icons.location_on_rounded, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(c.direccion, style: TextStyle(fontSize: 13, color: Colors.grey[500]), overflow: TextOverflow.ellipsis)),
                ]),
              ])),
            ])),

            const SizedBox(height: 20),

            Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: c.saldoPendiente > 0 ? [_danger, const Color(0xFFC0392B)] : [_success, const Color(0xFF16A085)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Saldo pendiente", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text("\$${c.saldoPendiente.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ]),
                const Spacer(),
                if (c.saldoPendiente > 0)
                  ElevatedButton.icon(
                    onPressed: () { Navigator.pop(context); _abrirAbono(c); },
                    icon: const Icon(Icons.payments_rounded, size: 18),
                    label: const Text("Abonar"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _danger,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                  )
                else
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 32),
              ]),
            )),

            const SizedBox(height: 20),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Align(alignment: Alignment.centerLeft,
                child: Text("Historial de fiados", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C3E50))))),
            const SizedBox(height: 12),

            Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _cargarFiados(c.idCliente),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _accent));
                final fiados = snap.data ?? [];
                if (fiados.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text("Sin fiados registrados", style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ]));
                return ListView.separated(
                  controller: sc,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: fiados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final f = fiados[i];
                    final total = double.tryParse(f["total"].toString()) ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                      child: Row(children: [
                        Container(width: 36, height: 36, decoration: BoxDecoration(color: _danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.handshake_rounded, color: _danger, size: 18)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text("Venta #${f["id_venta"]}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2C3E50))),
                          Text(f["fecha"].toString(), style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                        ])),
                        Text("\$${total.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _danger)),
                      ]),
                    );
                  },
                );
              },
            )),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  // Panel para registrar cuanto pagó el cliente
  void _abrirAbono(Cliente c) {
    final montoC = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 4),
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.payments_rounded, color: _success, size: 20)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Registrar abono", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _primary)),
                Text(c.nombre, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ]),
            ]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: _danger.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: _danger.withOpacity(0.2))),
              child: Row(children: [
                const Icon(Icons.account_balance_wallet_rounded, color: _danger, size: 18),
                const SizedBox(width: 10),
                Text("Saldo pendiente: \$${c.saldoPendiente.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w600, color: _danger, fontSize: 14)),
              ]),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: montoC,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: "Monto del abono *",
                prefixText: "\$",
                filled: true, fillColor: const Color(0xFFF4F6F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _success, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return "Ingresa un monto";
                final monto = double.tryParse(v);
                if (monto == null || monto <= 0) return "Monto inválido";
                if (monto > c.saldoPendiente) return "Supera el saldo pendiente";
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(children: [
              _botonMonto("25%", (c.saldoPendiente * 0.25), montoC),
              const SizedBox(width: 8),
              _botonMonto("50%", (c.saldoPendiente * 0.50), montoC),
              const SizedBox(width: 8),
              _botonMonto("75%", (c.saldoPendiente * 0.75), montoC),
              const SizedBox(width: 8),
              _botonMonto("Todo", c.saldoPendiente, montoC),
            ]),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final monto = double.tryParse(montoC.text) ?? 0;
                Navigator.pop(context);
                _abonar(c, monto);
              },
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text("Confirmar abono", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: _success, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
            )),
          ])),
        ),
      ),
    );
  }

  Widget _botonMonto(String label, double monto, TextEditingController ctrl) => Expanded(
    child: GestureDetector(
      onTap: () => ctrl.text = monto.toStringAsFixed(0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: _success.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: _success.withOpacity(0.2))),
        child: Column(children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _success)),
          Text("\$${monto.toStringAsFixed(0)}", style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ]),
      ),
    ),
  );

  void _confirmarEliminar(Cliente c) => showDialog(
    context: context, builder: (_) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: const Row(children: [Icon(Icons.warning_amber_rounded, color: _danger), SizedBox(width: 8), Text("Eliminar cliente")]),
    content: RichText(text: TextSpan(style: const TextStyle(color: Colors.black87, fontSize: 14), children: [
      const TextSpan(text: "¿Eliminar a "),
      TextSpan(text: c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
      const TextSpan(text: "? Esta acción no se puede deshacer."),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: _danger, foregroundColor: Colors.white, elevation: 0),
        onPressed: () { Navigator.pop(context); _eliminar(c.idCliente); },
        child: const Text("Eliminar"),
      ),
    ],
  ),
  );

  @override
  Widget build(BuildContext context) {
    final conDeuda   = _clientes.where((c) => c.saldoPendiente > 0).length;
    final totalDeuda = _clientes.fold<double>(0, (s, c) => s + c.saldoPendiente);

    return Container(
      color: _bg,
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Clientes", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _primary)),
            Text("Gestión de clientes y fiados", style: TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _abrirFormulario(),
            icon: const Icon(Icons.person_add_rounded, size: 18), label: const Text("Nuevo cliente"),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
          ),
        ]),

        const SizedBox(height: 20),

        Row(children: [
          _metrica("Total clientes", "${_clientes.length}", Icons.people_alt_rounded, _accent),
          const SizedBox(width: 12),
          _metrica("Con deuda", "$conDeuda", Icons.warning_amber_rounded, _danger),
          const SizedBox(width: 12),
          _metrica("Total fiado", "\$${totalDeuda.toStringAsFixed(0)}", Icons.account_balance_wallet_rounded, _warning),
        ]),

        const SizedBox(height: 16),

        Row(children: [
          Expanded(child: SizedBox(height: 44, child: TextField(
            onChanged: (v) { _busqueda = v; _aplicarFiltro(); },
            decoration: InputDecoration(
              hintText: "Buscar cliente...", hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: _accent, size: 20),
              filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            ),
          ))),
          const SizedBox(width: 8),
          SizedBox(height: 44, width: 44, child: OutlinedButton(
            onPressed: _cargarClientes,
            style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: Colors.grey[200]!), backgroundColor: Colors.white),
            child: const Icon(Icons.refresh_rounded, color: _accent, size: 20),
          )),
        ]),

        const SizedBox(height: 16),

        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator(color: _accent))
              : _filtrados.isEmpty
              ? _estadoVacio()
              : Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(children: [
                Container(color: const Color(0xFFF8FAFB), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: const Row(children: [
                      Expanded(flex: 3, child: Text("CLIENTE",  style: _estiloHeader)),
                      Expanded(flex: 2, child: Text("TELÉFONO", style: _estiloHeader)),
                      Expanded(flex: 3, child: Text("DIRECCIÓN",style: _estiloHeader)),
                      Expanded(flex: 2, child: Text("SALDO",    style: _estiloHeader, textAlign: TextAlign.right)),
                      SizedBox(width: 100),
                    ])),
                const Divider(height: 1, color: Color(0xFFEEF0F2)),
                Expanded(child: ListView.separated(
                  itemCount: _filtrados.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEF0F2)),
                  itemBuilder: (_, i) => _filaCliente(_filtrados[i]),
                )),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _filaCliente(Cliente c) {
    final tieneDeuda = c.saldoPendiente > 0;
    final esMovil = MediaQuery.of(context).size.width < 700;

    final saldoBadge = tieneDeuda
        ? Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: _danger.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Text("\$${c.saldoPendiente.toStringAsFixed(0)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _danger)))
        : Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: _success.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: const Text("Al día", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _success)));

    final acciones = Row(mainAxisSize: MainAxisSize.min, children: [
      _iconBtn(Icons.payments_rounded, _success, tieneDeuda ? () => _abrirAbono(c) : null, size: 17),
      _iconBtn(Icons.edit_rounded, _accent, () => _abrirFormulario(c: c), size: 17),
      _iconBtn(Icons.delete_rounded, _danger, () => _confirmarEliminar(c), size: 17),
    ]);

    return GestureDetector(
      onTap: () => _abrirDetalle(c),
      child: Container(
        color: tieneDeuda ? _danger.withOpacity(0.02) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: esMovil
            ? Row(children: [
          CircleAvatar(radius: 20, backgroundColor: _accent.withOpacity(0.12),
              child: Text(c.nombre[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: _accent, fontSize: 16))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2C3E50)), overflow: TextOverflow.ellipsis),
            if (c.telefono.isNotEmpty) Text(c.telefono, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ])),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [saldoBadge, const SizedBox(height: 4), acciones]),
        ])
            : Row(children: [
          Expanded(flex: 3, child: Row(children: [
            CircleAvatar(radius: 18, backgroundColor: _accent.withOpacity(0.12),
                child: Text(c.nombre[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: _accent))),
            const SizedBox(width: 10),
            Expanded(child: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2C3E50)), overflow: TextOverflow.ellipsis)),
          ])),
          Expanded(flex: 2, child: Text(c.telefono.isNotEmpty ? c.telefono : "—", style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
          Expanded(flex: 3, child: Text(c.direccion.isNotEmpty ? c.direccion : "—", style: TextStyle(fontSize: 13, color: Colors.grey[500]), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: saldoBadge)),
          SizedBox(width: 100, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _iconBtn(Icons.payments_rounded, _success, tieneDeuda ? () => _abrirAbono(c) : null),
            _iconBtn(Icons.edit_rounded, _accent, () => _abrirFormulario(c: c)),
            _iconBtn(Icons.delete_rounded, _danger, () => _confirmarEliminar(c)),
          ])),
        ]),
      ),
    );
  }

  Widget _estadoVacio() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: _accent.withOpacity(0.08), shape: BoxShape.circle),
        child: const Icon(Icons.people_alt_outlined, size: 52, color: _accent)),
    const SizedBox(height: 16),
    const Text("Sin clientes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
    const SizedBox(height: 6),
    Text("Registra el primer cliente para comenzar", style: TextStyle(fontSize: 13, color: Colors.grey[400])),
    const SizedBox(height: 20),
    ElevatedButton.icon(
      onPressed: () => _abrirFormulario(),
      icon: const Icon(Icons.person_add_rounded, size: 18), label: const Text("Registrar cliente"),
      style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
    ),
  ]));

  Widget _metrica(String label, String valor, IconData icono, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[100]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icono, color: color, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[400]), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    ),
  );

  Widget _iconBtn(IconData icon, Color color, VoidCallback? onTap, {double size = 18}) => GestureDetector(
    onTap: onTap,
    child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, color: onTap == null ? Colors.grey[300] : color, size: size)),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icono, {bool obligatorio = false, bool esNum = false}) => TextFormField(
    controller: ctrl,
    keyboardType: esNum ? TextInputType.phone : TextInputType.text,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(
      labelText: label, labelStyle: const TextStyle(fontSize: 13),
      prefixIcon: Icon(icono, color: _accent, size: 20),
      filled: true, fillColor: const Color(0xFFF4F6F8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    ),
    validator: obligatorio ? (v) => (v == null || v.trim().isEmpty) ? "Obligatorio" : null : null,
  );

  static const _estiloHeader = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.8);
}