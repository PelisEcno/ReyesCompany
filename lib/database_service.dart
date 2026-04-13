import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'models.dart';

class DatabaseService {
  static final DatabaseService _i = DatabaseService._();
  factory DatabaseService() => _i;
  DatabaseService._();

  final FirebaseDatabase _db   = FirebaseDatabase.instance;
  final FirebaseAuth     _auth = FirebaseAuth.instance;

  // Referencias a la base de datos
  DatabaseReference get _usuarios    => _db.ref('usuarios');
  DatabaseReference get _sucursales  => _db.ref('sucursales');
  DatabaseReference get _productos   => _db.ref('productos');
  DatabaseReference get _inventario  => _db.ref('inventario');
  DatabaseReference get _ventas      => _db.ref('ventas');
  DatabaseReference get _clientes    => _db.ref('clientes');
  DatabaseReference get _abonos      => _db.ref('abonos');
  DatabaseReference get _categorias  => _db.ref('categorias');
  DatabaseReference get _metodosPago => _db.ref('metodos_pago');

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Formato simple para la fecha de hoy
  String _hoy() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  Map<String, dynamic> _map(dynamic v) => Map<String, dynamic>.from(v as Map);

  // Metodo para loguear usuarios
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final snap = await _usuarios.child(cred.user!.uid).get();
      if (!snap.exists) return null;
      final d = _map(snap.value);
      if (d['activo'] == false) throw Exception('Usuario desactivado');
      String sucNombre = '';
      final idSuc = d['id_sucursal'] as String?;
      if (idSuc != null) {
        final s = await _sucursales.child(idSuc).get();
        if (s.exists) sucNombre = _map(s.value)['nombre'] ?? '';
      }
      return {'id_usuario': cred.user!.uid, 'nombre': d['nombre'] ?? '', 'rol': d['rol'] ?? 'Empleado',
        'activo': d['activo'] ?? true, 'id_sucursal': idSuc, 'sucursal_nombre': sucNombre};
    } on FirebaseAuthException catch (e) {
      throw Exception(_msgAuth(e.code));
    }
  }

  Future<void> logout() => _auth.signOut();

  // Traer datos del usuario que ya esta logueado
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snap = await _usuarios.child(uid).get();
    if (!snap.exists) return null;
    final d = _map(snap.value);
    if (d['activo'] == false) throw Exception('Usuario desactivado');
    String sucNombre = '';
    final idSuc = d['id_sucursal'] as String?;
    if (idSuc != null) {
      final s = await _sucursales.child(idSuc).get();
      if (s.exists) sucNombre = _map(s.value)['nombre'] ?? '';
    }
    return {
      'id_usuario':      uid,
      'nombre':          d['nombre']  ?? '',
      'rol':             d['rol']     ?? 'Empleado',
      'activo':          d['activo']  ?? true,
      'id_sucursal':     idSuc,
      'sucursal_nombre': sucNombre,
    };
  }

  String _msgAuth(String c) {
    switch (c) {
      case 'user-not-found': case 'wrong-password': case 'invalid-credential': return 'Email o contraseña incorrectos';
      case 'user-disabled':   return 'Usuario desactivado';
      case 'too-many-requests': return 'Demasiados intentos. Espera un momento';
      default: return 'Error de autenticación';
    }
  }

  Future<List<Sucursal>> getSucursales() async {
    final snap = await _sucursales.get();
    if (!snap.exists) return [];
    return _map(snap.value).entries
        .where((e) => _map(e.value)['estado'] == true)
        .map((e) => Sucursal.fromMap(e.key, _map(e.value)))
        .toList()..sort((a,b) => a.nombre.compareTo(b.nombre));
  }

  Future<List<Categoria>> getCategorias() async {
    final snap = await _categorias.get();
    if (!snap.exists) return [];
    return _map(snap.value).entries
        .map((e) => Categoria.fromMap(e.key, _map(e.value)))
        .toList()..sort((a,b) => a.nombre.compareTo(b.nombre));
  }

  Future<void> crearCategoria(String nombre) =>
      _categorias.push().set({'nombre': nombre});

  Future<List<MetodoPago>> getMetodosPago() async {
    final snap = await _metodosPago.get();
    if (!snap.exists) return [];
    return _map(snap.value).entries
        .where((e) => _map(e.value)['activo'] == true)
        .map((e) => MetodoPago.fromMap(e.key, _map(e.value)))
        .toList()..sort((a,b) => a.nombre.compareTo(b.nombre));
  }

  // Traer los productos y filtrar por sucursal si se necesita
  Future<List<Producto>> getProductos({String? idSucursal}) async {
    final snapP = await _productos.orderByChild('nombre').get();
    if (!snapP.exists) return [];
    final mapP = _map(snapP.value);

    final snapI = await _inventario.get();
    final mapI  = snapI.exists ? _map(snapI.value) : <String, dynamic>{};

    final lista = <Producto>[];
    for (final e in mapP.entries) {
      final data = _map(e.value);
      int stock = 0, stockMin = 0;

      if (idSucursal != null) {
        final key = '${e.key}_$idSucursal';
        if (!mapI.containsKey(key)) continue;
        final inv = _map(mapI[key]);
        stock    = (inv['stock']        as num?)?.toInt() ?? 0;
        stockMin = (inv['stock_minimo'] as num?)?.toInt() ?? 0;
      } else {
        for (final inv in mapI.entries) {
          if ((inv.key as String).startsWith('${e.key}_')) {
            final d = _map(inv.value);
            final s = (d['stock'] as num?)?.toInt() ?? 0;
            if (s > stock) { stock = s; stockMin = (d['stock_minimo'] as num?)?.toInt() ?? 0; }
          }
        }
      }

      lista.add(Producto.fromMap(e.key, data, stockActual: stock, stockMinimo: stockMin));
    }

    lista.sort((a,b) => a.nombre.compareTo(b.nombre));
    return lista;
  }

  Future<List<Producto>> getProductosConStock({required String idSucursal}) async {
    final todos = await getProductos(idSucursal: idSucursal);
    return todos.where((p) => p.stockActual > 0).toList();
  }

  Future<void> crearProducto({
    required String nombre, required String descripcion,
    required String idCategoria, required String categoriaNombre,
    required double precioCompra, required double precioVenta,
    required int stockInicial, required int stockMinimo,
    required String idSucursal,
  }) async {
    final ref = _productos.push();
    await ref.set({
      'nombre': nombre, 'descripcion': descripcion,
      'id_categoria': idCategoria, 'categoria_nombre': categoriaNombre,
      'precio_compra': precioCompra.toDouble(), 'precio_venta': precioVenta.toDouble(),
      'created_at': ServerValue.timestamp, 'updated_at': ServerValue.timestamp,
    });
    await _inventario.child('${ref.key!}_$idSucursal').set({
      'id_producto': ref.key!, 'id_sucursal': idSucursal,
      'stock': stockInicial, 'stock_minimo': stockMinimo,
      'updated_at': ServerValue.timestamp,
    });
  }

  Future<void> editarProducto({
    required String idProducto, required String nombre, required String descripcion,
    required String idCategoria, required String categoriaNombre,
    required double precioCompra, required double precioVenta,
    required int stockActual, required int stockMinimo,
    required String idSucursal,
  }) async {
    await _productos.child(idProducto).update({
      'nombre': nombre, 'descripcion': descripcion,
      'id_categoria': idCategoria, 'categoria_nombre': categoriaNombre,
      'precio_compra': precioCompra.toDouble(), 'precio_venta': precioVenta.toDouble(),
      'updated_at': ServerValue.timestamp,
    });
    await _inventario.child('${idProducto}_$idSucursal').set({
      'id_producto': idProducto, 'id_sucursal': idSucursal,
      'stock': stockActual, 'stock_minimo': stockMinimo,
      'updated_at': ServerValue.timestamp,
    });
  }

  Future<void> eliminarProducto(String id) async {
    await _productos.child(id).remove();
    final snap = await _inventario.get();
    if (!snap.exists) return;
    for (final k in _map(snap.value).keys) {
      if ((k as String).startsWith('${id}_')) await _inventario.child(k).remove();
    }
  }

  // Guardar la venta y bajar el stock
  Future<String> registrarVenta({
    required String idUsuario, required String usuarioNombre,
    required String idSucursal, required String sucursalNombre,
    required String idMetodoPago, required String metodoPagoNombre,
    required String tipoVenta,
    String? idCliente, String clienteNombre = '',
    required List<Map<String, dynamic>> items, required double total,
  }) async {
    for (final item in items) {
      final invSnap = await _inventario.child('${item["id_producto"]}_$idSucursal').get();
      if (!invSnap.exists) throw Exception('Sin inventario: ${item["nombre_producto"]}');
      final s = (_map(invSnap.value)['stock'] as num?)?.toInt() ?? 0;
      if (s < (item['cantidad'] as int)) throw Exception('Stock insuficiente: ${item["nombre_producto"]} (disponible: $s)');
    }

    final ref = _ventas.push();
    final fechaStr = _hoy();

    await ref.set({
      'id_usuario': idUsuario, 'usuario_nombre': usuarioNombre,
      'id_sucursal': idSucursal, 'sucursal_nombre': sucursalNombre,
      'id_metodo_pago': idMetodoPago, 'metodo_pago_nombre': metodoPagoNombre,
      'tipo_venta': tipoVenta, 'id_cliente': idCliente, 'cliente_nombre': clienteNombre,
      'total': total.toDouble(), 'items': items,
      'fecha': fechaStr, 'timestamp': ServerValue.timestamp, 'anulada': false,
    });

    for (final item in items) {
      final invKey  = '${item["id_producto"]}_$idSucursal';
      final invSnap = await _inventario.child(invKey).get();
      final inv     = _map(invSnap.value);
      final nuevo   = ((inv['stock'] as num?)?.toInt() ?? 0) - (item['cantidad'] as int);
      await _inventario.child(invKey).update({'stock': nuevo < 0 ? 0 : nuevo});
    }

    if (tipoVenta == 'Fiado' && idCliente != null) {
      final cSnap = await _clientes.child(idCliente).get();
      final saldo = (_map(cSnap.value)['saldo_pendiente'] as num?)?.toDouble() ?? 0;
      await _clientes.child(idCliente).update({'saldo_pendiente': saldo + total});
    }

    return ref.key!;
  }

  Future<List<Venta>> getHistorialVentas({String? idSucursal, String? fecha}) async {
    final snap = await _ventas.orderByChild('fecha').equalTo(fecha ?? _hoy()).get();
    if (!snap.exists) return [];
    var lista = _map(snap.value).entries
        .map((e) => Venta.fromMap(e.key, _map(e.value)))
        .where((v) => !v.anulada)
        .toList();
    if (idSucursal != null) lista = lista.where((v) => v.idSucursal == idSucursal).toList();
    lista.sort((a,b) => b.timestamp.compareTo(a.timestamp));
    return lista;
  }

  Future<void> anularVenta(String idVenta) async {
    final snap = await _ventas.child(idVenta).get();
    if (!snap.exists) throw Exception('Venta no encontrada');
    final d = _map(snap.value);
    final idSuc = d['id_sucursal'] as String?;

    for (final item in (d['items'] as List? ?? [])) {
      final m = _map(item);
      if (idSuc != null) {
        final invKey  = '${m["id_producto"]}_$idSuc';
        final invSnap = await _inventario.child(invKey).get();
        if (invSnap.exists) {
          final s = (_map(invSnap.value)['stock'] as num?)?.toInt() ?? 0;
          await _inventario.child(invKey).update({'stock': s + (m['cantidad'] as int)});
        }
      }
    }

    final idCli = d['id_cliente'] as String?;
    final total = (d['total'] as num?)?.toDouble() ?? 0;
    if (d['tipo_venta'] == 'Fiado' && idCli != null) {
      final cSnap = await _clientes.child(idCli).get();
      final saldo = (_map(cSnap.value)['saldo_pendiente'] as num?)?.toDouble() ?? 0;
      await _clientes.child(idCli).update({'saldo_pendiente': (saldo - total).clamp(0, double.infinity)});
    }

    await _ventas.child(idVenta).update({'anulada': true});
  }

  Future<List<Cliente>> getClientes({String? idSucursal}) async {
    final snap = await _clientes.get();
    if (!snap.exists) return [];
    return _map(snap.value).entries
        .where((e) {
      if (idSucursal == null) return true;
      return _map(e.value)['id_sucursal'] == idSucursal;
    })
        .map((e) => Cliente.fromMap(e.key, _map(e.value)))
        .toList()..sort((a,b) => a.nombre.compareTo(b.nombre));
  }

  Future<void> crearCliente({
    required String nombre, required String idSucursal,
    String telefono = '', String direccion = '',
  }) => _clientes.push().set({
    'nombre': nombre, 'telefono': telefono, 'direccion': direccion,
    'id_sucursal': idSucursal,
    'saldo_pendiente': 0.0, 'created_at': ServerValue.timestamp,
  });

  Future<void> editarCliente({
    required String id, required String nombre,
    String telefono = '', String direccion = '',
  }) => _clientes.child(id).update({'nombre': nombre, 'telefono': telefono, 'direccion': direccion});

  Future<void> eliminarCliente(String id) async {
    final snap  = await _clientes.child(id).get();
    final saldo = (_map(snap.value)['saldo_pendiente'] as num?)?.toDouble() ?? 0;
    if (saldo > 0) throw Exception('No se puede eliminar un cliente con saldo pendiente (\$${saldo.toStringAsFixed(0)})');
    await _clientes.child(id).remove();
  }

  // Registrar pago de deuda del cliente
  Future<void> registrarAbono({
    required String idCliente, required String idUsuario,
    required String idSucursal,
    required double monto, String observacion = '',
  }) async {
    final snap  = await _clientes.child(idCliente).get();
    final saldo = (_map(snap.value)['saldo_pendiente'] as num?)?.toDouble() ?? 0;
    if (monto <= 0) throw Exception('El monto debe ser mayor a 0');
    if (monto > saldo) throw Exception('El abono (\$${monto.toStringAsFixed(0)}) supera el saldo (\$${saldo.toStringAsFixed(0)})');
    await _clientes.child(idCliente).update({'saldo_pendiente': (saldo - monto).clamp(0, double.infinity)});
    await _abonos.push().set({
      'id_cliente': idCliente, 'id_usuario': idUsuario,
      'id_sucursal': idSucursal,
      'monto': monto.toDouble(), 'observacion': observacion,
      'fecha': _hoy(), 'timestamp': ServerValue.timestamp,
    });
  }

  Future<List<Map<String, dynamic>>> getHistorialFiados(String idCliente) async {
    final snap = await _ventas.orderByChild('id_cliente').equalTo(idCliente).get();
    if (!snap.exists) return [];
    return _map(snap.value).entries
        .where((e) {
      final d = _map(e.value);
      return d['tipo_venta'] == 'Fiado' && d['anulada'] != true;
    })
        .map((e) {
      final d = _map(e.value);
      return {'id_venta': e.key, 'fecha': d['fecha'] ?? '', 'total': d['total'] ?? 0, 'sucursal_nombre': d['sucursal_nombre'] ?? ''};
    })
        .toList()..sort((a,b) => (b['fecha'] as String).compareTo(a['fecha'] as String));
  }

  Future<List<Map<String, dynamic>>> getHistorialAbonos(String idCliente) async {
    final snap = await _abonos.orderByChild('id_cliente').equalTo(idCliente).get();
    if (!snap.exists) return [];
    final snapU = await _usuarios.get();
    final mapU  = snapU.exists ? _map(snapU.value) : <String, dynamic>{};

    return _map(snap.value).entries.map((e) {
      final d         = _map(e.value);
      final idU       = d['id_usuario'] as String?;
      String uNombre  = '';
      if (idU != null && mapU.containsKey(idU)) uNombre = _map(mapU[idU])['nombre'] ?? '';
      return {'id_abono': e.key, 'monto': d['monto'] ?? 0, 'fecha': d['fecha'] ?? '',
        'observacion': d['observacion'] ?? '', 'usuario_nombre': uNombre};
    }).toList()..sort((a,b) => (b['fecha'] as String).compareTo(a['fecha'] as String));
  }

  Future<List<Usuario>> getUsuarios() async {
    final snapU = await _usuarios.get();
    if (!snapU.exists) return [];
    final snapS = await _sucursales.get();
    final mapS  = snapS.exists ? _map(snapS.value) : <String, dynamic>{};
    return _map(snapU.value).entries.map((e) {
      final d    = _map(e.value);
      final idS  = d['id_sucursal'] as String?;
      String sNombre = idS != null && mapS.containsKey(idS) ? _map(mapS[idS])['nombre'] ?? '' : '';
      return Usuario.fromMap(e.key, d, sucursalNombre: sNombre);
    }).toList()..sort((a,b) => a.nombre.compareTo(b.nombre));
  }

  Future<void> crearUsuario({
    required String nombre, required String email,
    required String password, required String rol, String? idSucursal,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await _usuarios.child(cred.user!.uid).set({
      'nombre': nombre, 'email': email, 'rol': rol,
      'activo': true, 'id_sucursal': idSucursal, 'created_at': ServerValue.timestamp,
    });
  }

  Future<void> editarUsuario({
    required String id, required String nombre, required String email,
    required String rol, String? idSucursal,
  }) => _usuarios.child(id).update({'nombre': nombre, 'email': email, 'rol': rol, 'id_sucursal': idSucursal});

  Future<void> toggleUsuario(String id, bool activo) => _usuarios.child(id).update({'activo': activo});

  Future<void> cambiarPassword(String email, String passwordActual, String passwordNuevo) async {
    final cred = EmailAuthProvider.credential(email: email, password: passwordActual);
    await _auth.currentUser!.reauthenticateWithCredential(cred);
    await _auth.currentUser!.updatePassword(passwordNuevo);
  }

  // Resumen del dia para el dashboard
  Future<Map<String, dynamic>> getResumenDia({String? idSucursal}) async {
    final hoy = _hoy();

    final snapV = await _ventas.orderByChild('fecha').equalTo(hoy).get();
    double totalVentasContado = 0;
    double totalVentasFiado   = 0;
    int cantVentas   = 0;
    int cantFiados   = 0;
    final Map<String, Map<String, dynamic>> porMetodo = {};
    final movimientos = <Map<String, dynamic>>[];

    if (snapV.exists) {
      for (final e in _map(snapV.value).entries) {
        final d = _map(e.value);
        if (d['anulada'] == true) continue;
        if (idSucursal != null && d['id_sucursal'] != idSucursal) continue;
        final t      = (d['total'] as num?)?.toDouble() ?? 0;
        final metodo = d['metodo_pago_nombre']?.toString() ?? 'Efectivo';
        final esFiado = d['tipo_venta']?.toString() == 'Fiado';

        if (esFiado) {
          totalVentasFiado += t;
          cantFiados++;
        } else {
          totalVentasContado += t;
          cantVentas++;
          porMetodo.putIfAbsent(metodo, () => {'metodo': metodo, 'cantidad': 0, 'subtotal': 0.0});
          porMetodo[metodo]!['cantidad'] = (porMetodo[metodo]!['cantidad'] as int) + 1;
          porMetodo[metodo]!['subtotal'] = (porMetodo[metodo]!['subtotal'] as double) + t;
        }

        movimientos.add({
          'tipo': 'venta', 'id': e.key, 'monto': t,
          'nombre_cliente': d['cliente_nombre'] ?? 'Contado',
          'metodo': metodo, 'usuario': d['usuario_nombre'] ?? '',
          'sucursal': d['sucursal_nombre'] ?? '', 'observacion': '',
          'es_fiado': esFiado,
          'timestamp': (d['timestamp'] as num?)?.toInt() ?? 0,
        });
      }
    }

    final snapA = await _abonos.orderByChild('fecha').equalTo(hoy).get();
    double totalAbonos = 0;
    int cantAbonos = 0;

    if (snapA.exists) {
      for (final e in _map(snapA.value).entries) {
        final d = _map(e.value);
        if (idSucursal != null && d['id_sucursal'] != idSucursal) continue;
        final m = (d['monto'] as num?)?.toDouble() ?? 0;
        totalAbonos += m;
        cantAbonos++;
        movimientos.add({
          'tipo': 'abono', 'id': e.key, 'monto': m,
          'nombre_cliente': '', 'metodo': 'Abono',
          'usuario': '', 'sucursal': '',
          'observacion': d['observacion'] ?? '',
          'timestamp': (d['timestamp'] as num?)?.toInt() ?? 0,
        });
      }
    }

    final snapI = await _inventario.get();
    final Set<String> bajos = {};
    if (snapI.exists) {
      for (final e in _map(snapI.value).entries) {
        final d   = _map(e.value);
        final idS = d['id_sucursal'] as String?;
        if (idSucursal != null && idS != idSucursal) continue;
        final s    = (d['stock']        as num?)?.toInt() ?? 0;
        final sMin = (d['stock_minimo'] as num?)?.toInt() ?? 0;
        if (s <= sMin) bajos.add(d['id_producto'] as String? ?? e.key);
      }
    }

    final snapC = await _clientes.get();
    int cConDeuda = 0; double totalDeuda = 0;
    if (snapC.exists) {
      for (final e in _map(snapC.value).entries) {
        final d = _map(e.value);
        if (idSucursal != null && d['id_sucursal'] != idSucursal) continue;
        final saldo = (d['saldo_pendiente'] as num?)?.toDouble() ?? 0;
        if (saldo > 0) { cConDeuda++; totalDeuda += saldo; }
      }
    }

    movimientos.sort((a,b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

    return {
      'total_ventas':        totalVentasContado,
      'cantidad_ventas':     cantVentas,
      'total_fiados_hoy':    totalVentasFiado,
      'cantidad_fiados_hoy': cantFiados,
      'ventas_por_metodo':   porMetodo.values.toList(),
      'total_abonos':        totalAbonos,
      'cantidad_abonos':     cantAbonos,
      'total_dia':           totalVentasContado + totalAbonos,
      'stock_bajo':          bajos.length,
      'clientes_con_deuda':  cConDeuda,
      'total_deuda':         totalDeuda,
      'movimientos':         movimientos,
    };
  }

  Future<Map<String, dynamic>> getResumenPeriodo({
    required String fechaInicio, required String fechaFin, String? idSucursal,
  }) async {
    final snapV = await _ventas.orderByChild('fecha').startAt(fechaInicio).endAt(fechaFin).get();
    double total = 0; int cantidad = 0;
    final Map<String, Map<String, dynamic>> porDia = {};
    if (snapV.exists) {
      for (final e in _map(snapV.value).entries) {
        final d = _map(e.value);
        if (d['anulada'] == true) continue;
        if (idSucursal != null && d['id_sucursal'] != idSucursal) continue;
        final t = (d['total'] as num?)?.toDouble() ?? 0;
        final f = d['fecha']?.toString() ?? '';
        total += t; cantidad++;
        porDia.putIfAbsent(f, () => {'fecha': f, 'total': 0.0, 'cantidad': 0});
        porDia[f]!['total']    = (porDia[f]!['total'] as double) + t;
        porDia[f]!['cantidad'] = (porDia[f]!['cantidad'] as int) + 1;
      }
    }
    final dias = porDia.values.toList()..sort((a,b) => (a['fecha'] as String).compareTo(b['fecha'] as String));
    return {'total': total, 'cantidad': cantidad, 'por_dia': dias};
  }
}
