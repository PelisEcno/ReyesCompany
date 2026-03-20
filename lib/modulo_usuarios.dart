import 'package:flutter/material.dart';
import 'database_service.dart';
import 'models.dart';

const _primary = Color(0xFF1A5276);
const _accent  = Color(0xFF2E86C1);
const _success = Color(0xFF1ABC9C);
const _danger  = Color(0xFFE74C3C);
const _warning = Color(0xFFE67E22);
const _bg      = Color(0xFFF0F4F8);

class ModuloUsuarios extends StatefulWidget {
  final String idUsuarioActual;
  final bool esAdminGlobal;
  const ModuloUsuarios({super.key, required this.idUsuarioActual, this.esAdminGlobal = false});
  @override
  State<ModuloUsuarios> createState() => _ModuloUsuariosState();
}

class _ModuloUsuariosState extends State<ModuloUsuarios> {
  final _svc = DatabaseService();
  List<Usuario>  _usuarios   = [];
  List<Usuario>  _filtrados  = [];
  List<Sucursal> _sucursales = [];
  bool   _cargando = true;
  String _busqueda = "";
  final List<String> _roles = ["Administrador", "Empleado"];

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final results = await Future.wait([_svc.getUsuarios(), _svc.getSucursales()]);
      setState(() {
        _usuarios   = results[0] as List<Usuario>;
        _sucursales = results[1] as List<Sucursal>;
        _aplicarFiltro();
      });
    } catch (e) { _snack("Error: $e", _danger); }
    finally { setState(() => _cargando = false); }
  }

  void _aplicarFiltro() => setState(() =>
  _filtrados = _usuarios.where((u) => u.nombre.toLowerCase().contains(_busqueda.toLowerCase())).toList());

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: Colors.white)),
    backgroundColor: color, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
  ));

  void _abrirFormulario({Usuario? u}) {
    final nombreC = TextEditingController(text: u?.nombre ?? "");
    final emailC  = TextEditingController(text: u?.email ?? "");
    final passC   = TextEditingController();
    String rolSel       = u?.rol ?? "Empleado";
    String? sucursalSel = u?.idSucursal;
    bool verPass        = false;
    final formKey       = GlobalKey<FormState>();

    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(u == null ? Icons.person_add_rounded : Icons.edit_rounded, color: _primary, size: 20)),
                const SizedBox(width: 12),
                Text(u == null ? "Nuevo usuario" : "Editar usuario", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _primary)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: Colors.grey)),
              ]),
              const SizedBox(height: 16), const Divider(height: 1), const SizedBox(height: 20),
              _field(nombreC, "Nombre completo *", Icons.person_rounded, obligatorio: true),
              const SizedBox(height: 12),
              _field(emailC, "Email *", Icons.email_rounded, obligatorio: true),
              const SizedBox(height: 12),
              const Text("Rol", style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              Row(children: _roles.map((r) {
                final sel = rolSel == r;
                return Expanded(child: GestureDetector(
                  onTap: () => setSt(() => rolSel = r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: r == _roles.first ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: sel ? _primary : Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? _primary : Colors.grey[200]!)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(r == "Administrador" ? Icons.admin_panel_settings_rounded : Icons.badge_rounded, color: sel ? Colors.white : Colors.grey[500], size: 16),
                      const SizedBox(width: 6),
                      Text(r, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.grey[600])),
                    ]),
                  ),
                ));
              }).toList()),
              const SizedBox(height: 12),
              const Text("Sucursal asignada", style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
                child: DropdownButtonHideUnderline(child: DropdownButton<String?>(
                  value: sucursalSel, isExpanded: true, padding: const EdgeInsets.symmetric(horizontal: 12),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Row(children: [
                      Icon(Icons.store_mall_directory_rounded, size: 16, color: Colors.grey), SizedBox(width: 8),
                      Text("Sin sucursal (Admin global)", style: TextStyle(fontSize: 13)),
                    ])),
                    ..._sucursales.map((s) => DropdownMenuItem<String?>(value: s.idSucursal, child: Row(children: [
                      const Icon(Icons.store_rounded, size: 16, color: _accent), const SizedBox(width: 8),
                      Text(s.nombre, style: const TextStyle(fontSize: 13)),
                    ]))),
                  ],
                  onChanged: (v) => setSt(() => sucursalSel = v),
                )),
              ),
              if (u == null) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: passC, obscureText: !verPass, style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: "Contraseña *", labelStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_rounded, color: _accent, size: 20),
                    suffixIcon: GestureDetector(onTap: () => setSt(() => verPass = !verPass),
                        child: Icon(verPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey, size: 20)),
                    filled: true, fillColor: const Color(0xFFF4F6F8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? "Mínimo 6 caracteres" : null,
                ),
              ],
              const SizedBox(height: 24), const Divider(height: 1), const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx);
                    try {
                      if (u == null) {
                        await _svc.crearUsuario(nombre: nombreC.text.trim(), email: emailC.text.trim(), password: passC.text, rol: rolSel, idSucursal: sucursalSel);
                        _snack("Usuario creado correctamente", _success);
                      } else {
                        await _svc.editarUsuario(id: u.idUsuario, nombre: nombreC.text.trim(), email: emailC.text.trim(), rol: rolSel, idSucursal: sucursalSel);
                        _snack("Usuario actualizado", _success);
                      }
                      _cargar();
                    } catch (e) { _snack("Error: $e", _danger); }
                  },
                  icon: Icon(u == null ? Icons.add_rounded : Icons.save_rounded, size: 18),
                  label: Text(u == null ? "Crear" : "Guardar"),
                  style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                ),
              ]),
            ])),
          )),
        ),
      ),
    );
  }

  void _abrirCambioPassword(Usuario u) {
    final actualC = TextEditingController();
    final nuevaC  = TextEditingController();
    bool verActual = false, verNueva = false;
    final formKey  = GlobalKey<FormState>();
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _warning.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.lock_reset_rounded, color: _warning, size: 20)),
                const SizedBox(width: 12),
                const Text("Cambiar contraseña", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _primary)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: Colors.grey)),
              ]),
              const SizedBox(height: 8),
              Text(u.nombre, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const SizedBox(height: 20), const Divider(height: 1), const SizedBox(height: 20),
              _passField(actualC, "Contraseña actual *", verActual, () => setSt(() => verActual = !verActual)),
              const SizedBox(height: 12),
              _passField(nuevaC, "Nueva contraseña *", verNueva, () => setSt(() => verNueva = !verNueva), minLen: 6),
              const SizedBox(height: 24), const Divider(height: 1), const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx);
                    try {
                      await _svc.cambiarPassword(u.email, actualC.text, nuevaC.text);
                      _snack("Contraseña actualizada", _success);
                    } catch (e) { _snack("Error: $e", _danger); }
                  },
                  icon: const Icon(Icons.save_rounded, size: 18), label: const Text("Actualizar"),
                  style: ElevatedButton.styleFrom(backgroundColor: _warning, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                ),
              ]),
            ])),
          )),
        ),
      ),
    );
  }

  void _confirmarToggle(Usuario u) {
    final activar = !u.activo;
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Icon(activar ? Icons.check_circle_rounded : Icons.block_rounded, color: activar ? _success : _danger),
        const SizedBox(width: 8),
        Text(activar ? "Activar usuario" : "Desactivar usuario"),
      ]),
      content: RichText(text: TextSpan(style: const TextStyle(color: Colors.black87, fontSize: 14), children: [
        TextSpan(text: activar ? "¿Activar a " : "¿Desactivar a "),
        TextSpan(text: u.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: activar ? "? Podrá acceder al sistema." : "? No podrá iniciar sesión."),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: activar ? _success : _danger, foregroundColor: Colors.white, elevation: 0),
          onPressed: () async {
            Navigator.pop(context);
            try {
              await _svc.toggleUsuario(u.idUsuario, activar);
              _snack(activar ? "Usuario activado" : "Usuario desactivado", activar ? _success : _danger);
              _cargar();
            } catch (e) { _snack("Error: $e", _danger); }
          },
          child: Text(activar ? "Activar" : "Desactivar"),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final activos = _usuarios.where((u) => u.activo).length;
    final admins  = _usuarios.where((u) => u.rol == "Administrador").length;
    return Container(
      color: _bg, padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Usuarios", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _primary)),
            Text("Control de acceso y roles", style: TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
          const Spacer(),
          ElevatedButton.icon(onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.person_add_rounded, size: 18), label: const Text("Nuevo usuario"),
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0)),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          _metrica("Total", "${_usuarios.length}", Icons.people_alt_rounded, _accent),
          const SizedBox(width: 12),
          _metrica("Activos", "$activos", Icons.check_circle_rounded, _success),
          const SizedBox(width: 12),
          _metrica("Administradores", "$admins", Icons.admin_panel_settings_rounded, _warning),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: SizedBox(height: 44, child: TextField(
            onChanged: (v) { _busqueda = v; _aplicarFiltro(); },
            decoration: InputDecoration(
              hintText: "Buscar usuario...", hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: _accent, size: 20),
              filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            ),
          ))),
          const SizedBox(width: 8),
          SizedBox(height: 44, width: 44, child: OutlinedButton(
            onPressed: _cargar,
            style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: Colors.grey[200]!), backgroundColor: Colors.white),
            child: const Icon(Icons.refresh_rounded, color: _accent, size: 20),
          )),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: _cargando ? const Center(child: CircularProgressIndicator(color: _accent))
              : _filtrados.isEmpty ? _estadoVacio()
              : Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
            child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Column(children: [
              Container(color: const Color(0xFFF8FAFB), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: const Row(children: [
                    Expanded(flex: 3, child: Text("USUARIO",  style: _sHeader)),
                    Expanded(flex: 2, child: Text("ROL",      style: _sHeader, textAlign: TextAlign.center)),
                    Expanded(flex: 3, child: Text("SUCURSAL", style: _sHeader)),
                    Expanded(flex: 1, child: Text("ESTADO",   style: _sHeader, textAlign: TextAlign.center)),
                    SizedBox(width: 110),
                  ])),
              const Divider(height: 1, color: Color(0xFFEEF0F2)),
              Expanded(child: ListView.separated(
                itemCount: _filtrados.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEF0F2)),
                itemBuilder: (_, i) => _filaUsuario(_filtrados[i]),
              )),
            ])),
          ),
        ),
      ]),
    );
  }

  Widget _filaUsuario(Usuario u) {
    final esMio   = u.idUsuario == widget.idUsuarioActual;
    final esAdmin = u.rol == "Administrador";
    final esMovil = MediaQuery.of(context).size.width < 700;

    final rolBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: esAdmin ? _warning.withOpacity(0.1) : _accent.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(esAdmin ? Icons.admin_panel_settings_rounded : Icons.badge_rounded, size: 12, color: esAdmin ? _warning : _accent),
        const SizedBox(width: 4),
        Text(u.rol, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: esAdmin ? _warning : _accent)),
      ]),
    );

    final sucursalWidget = u.esAdminGlobal
        ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
        child: const Text("Global", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)))
        : Text(u.sucursalNombre.isNotEmpty ? u.sucursalNombre : u.idSucursal ?? "—", style: TextStyle(fontSize: 13, color: Colors.grey[500]), overflow: TextOverflow.ellipsis);

    final estadoBadge = GestureDetector(
      onTap: esMio ? null : () => _confirmarToggle(u),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: u.activo ? _success.withOpacity(0.1) : _danger.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(u.activo ? "Activo" : "Inactivo", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: u.activo ? _success : _danger))),
    );

    final acciones = Row(mainAxisSize: MainAxisSize.min, children: [
      _iconBtn(Icons.edit_rounded, _accent, () => _abrirFormulario(u: u)),
      _iconBtn(Icons.lock_reset_rounded, _warning, () => _abrirCambioPassword(u)),
      if (!esMio) _iconBtn(u.activo ? Icons.block_rounded : Icons.check_circle_outline_rounded,
          u.activo ? _danger : _success, () => _confirmarToggle(u)),
    ]);

    if (esMovil) {
      return Container(
        color: !u.activo ? _danger.withOpacity(0.02) : esMio ? _accent.withOpacity(0.02) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          _avatar(u), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2C3E50)), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [rolBadge, const SizedBox(width: 6), estadoBadge]),
          ])),
          acciones,
        ]),
      );
    }

    return Container(
      color: !u.activo ? _danger.withOpacity(0.02) : esMio ? _accent.withOpacity(0.02) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          _avatar(u), const SizedBox(width: 10),
          Expanded(child: Row(children: [
            Expanded(child: Text(u.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2C3E50)), overflow: TextOverflow.ellipsis)),
            if (esMio) Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(6)),
                child: const Text("Tú", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))),
          ])),
        ])),
        Expanded(flex: 2, child: Center(child: rolBadge)),
        Expanded(flex: 3, child: sucursalWidget),
        Expanded(flex: 1, child: Center(child: estadoBadge)),
        SizedBox(width: 110, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          _iconBtn(Icons.edit_rounded, _accent, () => _abrirFormulario(u: u)),
          _iconBtn(Icons.lock_reset_rounded, _warning, () => _abrirCambioPassword(u)),
          if (!esMio) _iconBtn(u.activo ? Icons.block_rounded : Icons.check_circle_outline_rounded,
              u.activo ? _danger : _success, () => _confirmarToggle(u)),
        ])),
      ]),
    );
  }

  Widget _avatar(Usuario u) {
    final color = u.rol == "Administrador" ? _warning : _accent;
    return CircleAvatar(radius: 18, backgroundColor: color.withOpacity(0.15),
        child: Text(u.nombre.isNotEmpty ? u.nombre[0].toUpperCase() : 'U', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)));
  }

  Widget _estadoVacio() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: _accent.withOpacity(0.08), shape: BoxShape.circle),
        child: const Icon(Icons.manage_accounts_outlined, size: 52, color: _accent)),
    const SizedBox(height: 16),
    const Text("Sin usuarios", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
    const SizedBox(height: 20),
    ElevatedButton.icon(onPressed: () => _abrirFormulario(), icon: const Icon(Icons.person_add_rounded, size: 18), label: const Text("Crear usuario"),
        style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0)),
  ]));

  Widget _metrica(String label, String valor, IconData icono, Color color) => Expanded(
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[100]!),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icono, color: color, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[400]), overflow: TextOverflow.ellipsis),
          ])),
        ])),
  );

  Widget _iconBtn(IconData icon, Color color, VoidCallback? onTap) => GestureDetector(
    onTap: onTap, child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, color: onTap == null ? Colors.grey[300] : color, size: 18)),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icono, {bool obligatorio = false}) => TextFormField(
    controller: ctrl, style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 13), prefixIcon: Icon(icono, color: _accent, size: 20),
        filled: true, fillColor: const Color(0xFFF4F6F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13)),
    validator: obligatorio ? (v) => (v == null || v.trim().isEmpty) ? "Obligatorio" : null : null,
  );

  Widget _passField(TextEditingController ctrl, String label, bool ver, VoidCallback toggle, {int minLen = 1}) => TextFormField(
    controller: ctrl, obscureText: !ver, style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: const Icon(Icons.lock_rounded, color: _accent, size: 20),
        suffixIcon: GestureDetector(onTap: toggle, child: Icon(ver ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey, size: 20)),
        filled: true, fillColor: const Color(0xFFF4F6F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13)),
    validator: (v) => (v == null || v.length < minLen) ? "Mínimo $minLen caracteres" : null,
  );

  static const _sHeader = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.8);
}