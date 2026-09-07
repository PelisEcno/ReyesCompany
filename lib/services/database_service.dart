import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _i = DatabaseService._();
  factory DatabaseService() => _i;
  DatabaseService._();

  static const String _baseUrl = 'https://reyescompany.onrender.com';

  final FirebaseDatabase _db   = FirebaseDatabase.instance;
  final FirebaseAuth     _auth = FirebaseAuth.instance;

  // Referencias a la base de datos
  DatabaseReference get _usuarios    => _db.ref('usuarios');
  DatabaseReference get _sucursales  => _db.ref('sucursales');
  DatabaseReference get _inventario  => _db.ref('inventario');
  DatabaseReference get _ventas      => _db.ref('ventas');
  DatabaseReference get _clientes    => _db.ref('clientes');
  DatabaseReference get _abonos      => _db.ref('abonos');

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Formato simple para la fecha de hoy
  String _hoy() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  Map<String, dynamic> _map(dynamic v) => Map<String, dynamic>.from(v as Map);

  // Metodo para loguear usuarios contra el backend en Render
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/api/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final d = jsonDecode(response.body);
      final rol = d['rol'];
      return {
        'id_usuario': d['idUsuario'].toString(),
        'nombre': d['nombre'] ?? '',
        'rol': rol != null ? (rol['nombre'] ?? '') : '',
        'activo': d['activo'] ?? true,
        'id_sucursal': null,
        'sucursal_nombre': '',
      };
    } else if (response.statusCode == 401) {
      throw Exception('Email o contraseña incorrectos');
    } else if (response.statusCode == 403) {
      throw Exception('Usuario desactivado');
    } else {
      throw Exception('Error de autenticación');
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

  Future<List<Sucursal>> getSucursales() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/sucursales'));
    if (response.statusCode != 200) throw Exception('Error al cargar sucursales');
    final lista = jsonDecode(response.body) as List;
    return lista
        .where((d) => d['estado'] == true)
        .map((d) => Sucursal(
              id: d['idSucursal'].toString(),
              nombre: d['nombre'] ?? '',
              direccion: d['direccion'] ?? '',
              telefono: d['telefono'] ?? '',
              activa: d['estado'] ?? true,
            ))
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  Future<List<Categoria>> getCategorias() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/categorias'));
    if (response.statusCode != 200) throw Exception('Error al cargar categorias');
    final lista = jsonDecode(response.body) as List;
    return lista
        .map((d) => Categoria(id: d['idCategoria'].toString(), nombre: d['nombre'] ?? ''))
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  Future<void> crearCategoria(String nombre) async {
    await http.post(
      Uri.parse('$_baseUrl/api/categorias'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombre}),
    );
  }

  Future<List<MetodoPago>> getMetodosPago() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/metodos-pago'));
    if (response.statusCode != 200) throw Exception('Error al cargar metodos de pago');
    final lista = jsonDecode(response.body) as List;
    return lista
        .where((d) => d['activo'] == true)
        .map((d) => MetodoPago(id: d['idMetodoPago'].toString(), nombre: d['nombre'] ?? '', activo: d['activo'] ?? true))
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  // Traer los productos y filtrar por sucursal si se necesita
  Future<List<Producto>> getProductos({String? idSucursal}) async {
    final respProductos = await http.get(Uri.parse('$_baseUrl/api/productos'));
    final respInventario = await http.get(Uri.parse('$_baseUrl/api/inventario'));
    if (respProductos.statusCode != 200 || respInventario.statusCode != 200) {
      throw Exception('Error al cargar productos');
    }
    final productos = jsonDecode(respProductos.body) as List;
    final inventarios = jsonDecode(respInventario.body) as List;

    final lista = <Producto>[];
    for (final p in productos) {
      final idProducto = p['idProducto'].toString();
      int stock = 0, stockMin = 0;

      if (idSucursal != null) {
        final inv = inventarios.firstWhere(
          (i) => i['producto']['idProducto'].toString() == idProducto &&
                 i['sucursal']['idSucursal'].toString() == idSucursal,
          orElse: () => null,
        );
        if (inv == null) continue;
        stock = (inv['stock'] as num?)?.toInt() ?? 0;
        stockMin = (inv['stockMinimo'] as num?)?.toInt() ?? 0;
      } else {
        for (final inv in inventarios) {
          if (inv['producto']['idProducto'].toString() == idProducto) {
            stock += (inv['stock'] as num?)?.toInt() ?? 0;
            stockMin = (inv['stockMinimo'] as num?)?.toInt() ?? stockMin;
          }
        }
      }

      final cat = p['categoria'];
      lista.add(Producto(
        id: idProducto,
        nombre: p['nombre'] ?? '',
        descripcion: p['descripcion'] ?? '',
        idCategoria: cat != null ? cat['idCategoria'].toString() : '',
        categoriaNombre: cat != null ? (cat['nombre'] ?? '') : '',
        precioCompra: (p['precioCompra'] as num?)?.toDouble() ?? 0,
        precioVenta: (p['precioVenta'] as num?)?.toDouble() ?? 0,
        stockActual: stock,
        stockMinimo: stockMin,
      ));
    }

    lista.sort((a, b) => a.nombre.compareTo(b.nombre));
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
    final respProducto = await http.post(
      Uri.parse('$_baseUrl/api/productos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
        'precioCompra': precioCompra,
        'precioVenta': precioVenta,
        'categoria': {'idCategoria': int.parse(idCategoria)},
      }),
    );
    if (respProducto.statusCode != 200) throw Exception('No se pudo crear el producto');
    final producto = jsonDecode(respProducto.body);

    await http.post(
      Uri.parse('$_baseUrl/api/inventario'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'stock': stockInicial,
        'stockMinimo': stockMinimo,
        'producto': {'idProducto': producto['idProducto']},
        'sucursal': {'idSucursal': int.parse(idSucursal)},
      }),
    );
  }

  Future<void> editarProducto({
    required String idProducto, required String nombre, required String descripcion,
    required String idCategoria, required String categoriaNombre,
    required double precioCompra, required double precioVenta,
    required int stockActual, required int stockMinimo,
    required String idSucursal,
  }) async {
    await http.put(
      Uri.parse('$_baseUrl/api/productos/$idProducto'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
        'precioCompra': precioCompra,
        'precioVenta': precioVenta,
        'categoria': {'idCategoria': int.parse(idCategoria)},
      }),
    );

    final respInventario = await http.get(Uri.parse('$_baseUrl/api/inventario'));
    final inventarios = jsonDecode(respInventario.body) as List;
    final existente = inventarios.firstWhere(
      (i) => i['producto']['idProducto'].toString() == idProducto &&
             i['sucursal']['idSucursal'].toString() == idSucursal,
      orElse: () => null,
    );

    final cuerpo = jsonEncode({
      'stock': stockActual,
      'stockMinimo': stockMinimo,
      'producto': {'idProducto': int.parse(idProducto)},
      'sucursal': {'idSucursal': int.parse(idSucursal)},
    });

    if (existente != null) {
      await http.put(
        Uri.parse('$_baseUrl/api/inventario/${existente['idInventario']}'),
        headers: {'Content-Type': 'application/json'},
        body: cuerpo,
      );
    } else {
      await http.post(
        Uri.parse('$_baseUrl/api/inventario'),
        headers: {'Content-Type': 'application/json'},
        body: cuerpo,
      );
    }
  }

  Future<void> eliminarProducto(String id) async {
    final respInventario = await http.get(Uri.parse('$_baseUrl/api/inventario'));
    final inventarios = jsonDecode(respInventario.body) as List;
    for (final inv in inventarios) {
      if (inv['producto']['idProducto'].toString() == id) {
        await http.delete(Uri.parse('$_baseUrl/api/inventario/${inv['idInventario']}'));
      }
    }
    await http.delete(Uri.parse('$_baseUrl/api/productos/$id'));
  }

  // Guardar la venta y bajar el stock
  // Tu modelo real exige un cliente en toda venta, incluso de contado.
  // Si no se elige uno, usamos/creamos un cliente generico "Consumidor Final".
  Future<String> _obtenerOCrearClienteGenerico() async {
    final respClientes = await http.get(Uri.parse('$_baseUrl/api/clientes'));
    final clientes = jsonDecode(respClientes.body) as List;
    final existente = clientes.firstWhere((c) => c['nombre'] == 'Consumidor Final', orElse: () => null);
    if (existente != null) return existente['idCliente'].toString();

    final respNuevo = await http.post(
      Uri.parse('$_baseUrl/api/clientes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': 'Consumidor Final', 'apellido': '', 'telefono': '', 'direccion': ''}),
    );
    return jsonDecode(respNuevo.body)['idCliente'].toString();
  }

  Future<String> registrarVenta({
    required String idUsuario, required String usuarioNombre,
    required String idSucursal, required String sucursalNombre,
    required String idMetodoPago, required String metodoPagoNombre,
    required String tipoVenta,
    String? idCliente, String clienteNombre = '',
    required List<Map<String, dynamic>> items, required double total,
  }) async {
    final esFiado = tipoVenta == 'Fiado';
    final clienteFinal = idCliente ?? await _obtenerOCrearClienteGenerico();

    final respInventario = await http.get(Uri.parse('$_baseUrl/api/inventario'));
    final inventarios = jsonDecode(respInventario.body) as List;

    final itemsRequest = <Map<String, dynamic>>[];
    for (final item in items) {
      final idProducto = item['id_producto'] as String;
      final inv = inventarios.firstWhere(
        (i) => i['producto']['idProducto'].toString() == idProducto &&
               i['sucursal']['idSucursal'].toString() == idSucursal,
        orElse: () => null,
      );
      if (inv == null) throw Exception('Sin inventario: ${item["nombre_producto"]}');
      final stock = (inv['stock'] as num?)?.toInt() ?? 0;
      if (stock < (item['cantidad'] as int)) {
        throw Exception('Stock insuficiente: ${item["nombre_producto"]} (disponible: $stock)');
      }
      itemsRequest.add({
        'idInventario': inv['idInventario'],
        'cantidad': item['cantidad'],
        'precioUnitario': item['precio_unitario'],
      });
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/api/ventas/registrar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idUsuario': int.parse(idUsuario),
        'idSucursal': int.parse(idSucursal),
        'idCliente': int.parse(clienteFinal),
        'idMetodoPago': esFiado ? null : int.parse(idMetodoPago),
        'esFiado': esFiado,
        'items': itemsRequest,
      }),
    );

    if (response.statusCode != 200) throw Exception('No se pudo registrar la venta');
    final venta = jsonDecode(response.body);
    return venta['idVenta'].toString();
  }

  Future<List<Venta>> getHistorialVentas({String? idSucursal, String? fecha}) async {
    final hoy = fecha ?? _hoy();
    final respVentas = await http.get(Uri.parse('$_baseUrl/api/ventas'));
    final respPagos = await http.get(Uri.parse('$_baseUrl/api/pagos'));
    final respDeudas = await http.get(Uri.parse('$_baseUrl/api/deudas-cliente'));

    final ventas = jsonDecode(respVentas.body) as List;
    final pagos = respPagos.statusCode == 200 ? jsonDecode(respPagos.body) as List : [];
    final deudas = respDeudas.statusCode == 200 ? jsonDecode(respDeudas.body) as List : [];

    final lista = <Venta>[];
    for (final v in ventas) {
      if (v['fecha'] != hoy) continue;
      final idVenta = v['idVenta'].toString();
      if (idSucursal != null && v['sucursal']['idSucursal'].toString() != idSucursal) continue;

      final pago = pagos.firstWhere((p) => p['venta']['idVenta'].toString() == idVenta, orElse: () => null);
      final deuda = deudas.firstWhere((d) => d['venta']['idVenta'].toString() == idVenta, orElse: () => null);

      lista.add(Venta(
        id: idVenta,
        fecha: v['fecha'] ?? '',
        idMetodoPago: pago != null ? pago['metodoPago']['idMetodoPago'].toString() : '',
        metodoPagoNombre: pago != null ? (pago['metodoPago']['nombre'] ?? '') : 'Fiado',
        idUsuario: v['usuario']['idUsuario'].toString(),
        idCliente: v['cliente']['idCliente'].toString(),
        clienteNombre: v['cliente']['nombre'] ?? '',
        total: (v['total'] as num?)?.toDouble() ?? 0,
        tipoVenta: deuda != null ? TipoVenta.fiado : TipoVenta.contado,
        idSucursal: v['sucursal']['idSucursal'].toString(),
        anulada: false,
        timestamp: DateTime.parse(v['createdAt']).millisecondsSinceEpoch,
      ));
    }

    lista.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return lista;
  }

  // No existe columna "anulada" en tu modelo real: anular significa
  // deshacer de verdad el detalle, el pago o la deuda, y devolver el stock.
  Future<void> anularVenta(String idVenta) async {
    final respDetalles = await http.get(Uri.parse('$_baseUrl/api/detalle-venta'));
    final detalles = jsonDecode(respDetalles.body) as List;
    final propios = detalles.where((d) => d['venta']['idVenta'].toString() == idVenta).toList();

    for (final d in propios) {
      final inv = d['inventario'];
      final stockActual = (inv['stock'] as num).toInt();
      final cantidad = (d['cantidad'] as num).toInt();
      await http.put(
        Uri.parse('$_baseUrl/api/inventario/${inv['idInventario']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'stock': stockActual + cantidad,
          'stockMinimo': inv['stockMinimo'],
          'producto': {'idProducto': inv['producto']['idProducto']},
          'sucursal': {'idSucursal': inv['sucursal']['idSucursal']},
        }),
      );
      await http.delete(Uri.parse('$_baseUrl/api/detalle-venta/${d['idDetalleVenta']}'));
    }

    final respPagos = await http.get(Uri.parse('$_baseUrl/api/pagos'));
    final pagos = jsonDecode(respPagos.body) as List;
    final pago = pagos.firstWhere((p) => p['venta']['idVenta'].toString() == idVenta, orElse: () => null);
    if (pago != null) await http.delete(Uri.parse('$_baseUrl/api/pagos/${pago['idPago']}'));

    final respDeudas = await http.get(Uri.parse('$_baseUrl/api/deudas-cliente'));
    final deudas = jsonDecode(respDeudas.body) as List;
    final deuda = deudas.firstWhere((d) => d['venta']['idVenta'].toString() == idVenta, orElse: () => null);
    if (deuda != null) await http.delete(Uri.parse('$_baseUrl/api/deudas-cliente/${deuda['idDeudaCliente']}'));

    await http.delete(Uri.parse('$_baseUrl/api/ventas/$idVenta'));
  }

  // El cliente ya no tiene sucursal fija ni saldo guardado directo en tu modelo real:
  // el saldo pendiente se calcula sumando las deudas (deuda_cliente) y restando los abonos.
  Future<List<Cliente>> getClientes({String? idSucursal}) async {
    final respClientes = await http.get(Uri.parse('$_baseUrl/api/clientes'));
    if (respClientes.statusCode != 200) throw Exception('Error al cargar clientes');
    final respDeudas = await http.get(Uri.parse('$_baseUrl/api/deudas-cliente'));
    final respAbonos = await http.get(Uri.parse('$_baseUrl/api/abonos'));

    final clientes = jsonDecode(respClientes.body) as List;
    final deudas = respDeudas.statusCode == 200 ? jsonDecode(respDeudas.body) as List : [];
    final abonos = respAbonos.statusCode == 200 ? jsonDecode(respAbonos.body) as List : [];

    final lista = <Cliente>[];
    for (final c in clientes) {
      final idCliente = c['idCliente'].toString();

      final deudasCliente = deudas.where((d) => d['cliente']['idCliente'].toString() == idCliente).toList();
      double totalDeuda = 0;
      for (final d in deudasCliente) {
        totalDeuda += (d['venta']['total'] as num?)?.toDouble() ?? 0;
      }

      final idsDeuda = deudasCliente.map((d) => d['idDeudaCliente'].toString()).toSet();
      double totalAbonado = 0;
      for (final a in abonos) {
        if (idsDeuda.contains(a['deudaCliente']['idDeudaCliente'].toString())) {
          totalAbonado += (a['monto'] as num?)?.toDouble() ?? 0;
        }
      }

      lista.add(Cliente(
        id: idCliente,
        nombre: c['nombre'] ?? '',
        telefono: c['telefono'] ?? '',
        direccion: c['direccion'] ?? '',
        saldoPendiente: (totalDeuda - totalAbonado).clamp(0, double.infinity),
      ));
    }

    lista.sort((a, b) => a.nombre.compareTo(b.nombre));
    return lista;
  }

  Future<void> crearCliente({
    required String nombre, required String idSucursal,
    String telefono = '', String direccion = '',
  }) async {
    await http.post(
      Uri.parse('$_baseUrl/api/clientes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombre, 'apellido': '', 'telefono': telefono, 'direccion': direccion}),
    );
  }

  Future<void> editarCliente({
    required String id, required String nombre,
    String telefono = '', String direccion = '',
  }) async {
    await http.put(
      Uri.parse('$_baseUrl/api/clientes/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombre, 'apellido': '', 'telefono': telefono, 'direccion': direccion}),
    );
  }

  Future<void> eliminarCliente(String id) async {
    final clientes = await getClientes();
    final cliente = clientes.firstWhere((c) => c.idCliente == id, orElse: () => Cliente(id: id, nombre: ''));
    if (cliente.saldoPendiente > 0) {
      throw Exception('No se puede eliminar un cliente con saldo pendiente (\$${cliente.saldoPendiente.toStringAsFixed(0)})');
    }
    await http.delete(Uri.parse('$_baseUrl/api/clientes/$id'));
  }

  // Tu modelo real no guarda un saldo fijo: cada abono se aplica contra
  // las deudas (deuda_cliente) mas antiguas del cliente hasta completar el monto.
  Future<void> registrarAbono({
    required String idCliente, required String idUsuario,
    required String idSucursal,
    required double monto, String observacion = '',
  }) async {
    if (monto <= 0) throw Exception('El monto debe ser mayor a 0');

    final respDeudas = await http.get(Uri.parse('$_baseUrl/api/deudas-cliente'));
    final respAbonos = await http.get(Uri.parse('$_baseUrl/api/abonos'));
    final deudas = jsonDecode(respDeudas.body) as List;
    final abonos = jsonDecode(respAbonos.body) as List;

    final deudasCliente = deudas.where((d) => d['cliente']['idCliente'].toString() == idCliente).toList()
      ..sort((a, b) => (a['fechaDeuda'] as String).compareTo(b['fechaDeuda'] as String));

    double saldoTotal = 0;
    final pendientes = <Map<String, dynamic>>[];
    for (final d in deudasCliente) {
      final totalDeuda = (d['venta']['total'] as num?)?.toDouble() ?? 0;
      double abonado = 0;
      for (final a in abonos) {
        if (a['deudaCliente']['idDeudaCliente'].toString() == d['idDeudaCliente'].toString()) {
          abonado += (a['monto'] as num?)?.toDouble() ?? 0;
        }
      }
      final pendiente = totalDeuda - abonado;
      saldoTotal += pendiente;
      if (pendiente > 0) pendientes.add({'idDeudaCliente': d['idDeudaCliente'], 'pendiente': pendiente});
    }

    if (monto > saldoTotal) {
      throw Exception('El abono (\$${monto.toStringAsFixed(0)}) supera el saldo (\$${saldoTotal.toStringAsFixed(0)})');
    }

    double restante = monto;
    for (final p in pendientes) {
      if (restante <= 0) break;
      final pendiente = p['pendiente'] as double;
      final aplicar = restante < pendiente ? restante : pendiente;
      await http.post(
        Uri.parse('$_baseUrl/api/abonos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'monto': aplicar,
          'fecha': _hoy(),
          'deudaCliente': {'idDeudaCliente': p['idDeudaCliente']},
        }),
      );
      restante -= aplicar;
    }
  }

  Future<List<Map<String, dynamic>>> getHistorialFiados(String idCliente) async {
    final respDeudas = await http.get(Uri.parse('$_baseUrl/api/deudas-cliente'));
    final deudas = jsonDecode(respDeudas.body) as List;
    final propias = deudas.where((d) => d['cliente']['idCliente'].toString() == idCliente).toList();

    final lista = propias.map((d) => {
      'id_venta': d['venta']['idVenta'].toString(),
      'fecha': d['venta']['fecha'] ?? '',
      'total': d['venta']['total'] ?? 0,
      'sucursal_nombre': d['venta']['sucursal'] != null ? (d['venta']['sucursal']['nombre'] ?? '') : '',
    }).toList();

    lista.sort((a, b) => (b['fecha'] as String).compareTo(a['fecha'] as String));
    return lista;
  }

  Future<List<Map<String, dynamic>>> getHistorialAbonos(String idCliente) async {
    final respDeudas = await http.get(Uri.parse('$_baseUrl/api/deudas-cliente'));
    final respAbonos = await http.get(Uri.parse('$_baseUrl/api/abonos'));
    final deudas = jsonDecode(respDeudas.body) as List;
    final abonos = jsonDecode(respAbonos.body) as List;

    final idsDeuda = deudas
        .where((d) => d['cliente']['idCliente'].toString() == idCliente)
        .map((d) => d['idDeudaCliente'].toString())
        .toSet();

    final propios = abonos.where((a) => idsDeuda.contains(a['deudaCliente']['idDeudaCliente'].toString())).toList();

    final lista = propios.map((a) => {
      'id_abono': a['idAbono'].toString(),
      'monto': a['monto'] ?? 0,
      'fecha': a['fecha'] ?? '',
      'observacion': '',
      'usuario_nombre': '',
    }).toList();

    lista.sort((a, b) => (b['fecha'] as String).compareTo(a['fecha'] as String));
    return lista;
  }

  // Ya no existe sucursal fija por usuario en tu modelo real, el rol ahora es una tabla aparte
  Future<List<Usuario>> getUsuarios() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/usuarios'));
    if (response.statusCode != 200) throw Exception('Error al cargar usuarios');
    final lista = jsonDecode(response.body) as List;
    return lista.map((d) {
      final rol = d['rol'];
      return Usuario(
        id: d['idUsuario'].toString(),
        nombre: d['nombre'] ?? '',
        email: d['email'] ?? '',
        rol: rol != null ? (rol['nombre'] ?? '') : '',
        activo: d['activo'] ?? true,
        idSucursal: null,
        sucursalNombre: '',
      );
    }).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  Future<int> _obtenerOCrearRol(String nombreRol) async {
    final respRoles = await http.get(Uri.parse('$_baseUrl/api/roles'));
    final roles = jsonDecode(respRoles.body) as List;
    final existente = roles.firstWhere((r) => r['nombre'] == nombreRol, orElse: () => null);
    if (existente != null) return existente['idRol'] as int;

    final respNuevo = await http.post(
      Uri.parse('$_baseUrl/api/roles'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombreRol}),
    );
    return jsonDecode(respNuevo.body)['idRol'] as int;
  }

  Future<void> crearUsuario({
    required String nombre, required String email,
    required String password, required String rol, String? idSucursal,
  }) async {
    final idRol = await _obtenerOCrearRol(rol);
    await http.post(
      Uri.parse('$_baseUrl/api/usuarios'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'passwordHash': password,
        'activo': true,
        'fechaNacimiento': '2000-01-01T00:00:00',
        'fechaVencimientoClave': '2099-01-01T00:00:00',
        'tratamientoDatos': true,
        'rol': {'idRol': idRol},
      }),
    );
  }

  Future<void> editarUsuario({
    required String id, required String nombre, required String email,
    required String rol, String? idSucursal,
  }) async {
    final respActual = await http.get(Uri.parse('$_baseUrl/api/usuarios/$id'));
    final actual = jsonDecode(respActual.body);
    final idRol = await _obtenerOCrearRol(rol);

    await http.put(
      Uri.parse('$_baseUrl/api/usuarios/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'activo': actual['activo'],
        'fechaNacimiento': actual['fechaNacimiento'],
        'fechaVencimientoClave': actual['fechaVencimientoClave'],
        'tratamientoDatos': actual['tratamientoDatos'],
        'rol': {'idRol': idRol},
      }),
    );
  }

  Future<void> toggleUsuario(String id, bool activo) async {
    final respActual = await http.get(Uri.parse('$_baseUrl/api/usuarios/$id'));
    final actual = jsonDecode(respActual.body);

    await http.put(
      Uri.parse('$_baseUrl/api/usuarios/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': actual['nombre'],
        'email': actual['email'],
        'activo': activo,
        'fechaNacimiento': actual['fechaNacimiento'],
        'fechaVencimientoClave': actual['fechaVencimientoClave'],
        'tratamientoDatos': actual['tratamientoDatos'],
        'rol': {'idRol': actual['rol']['idRol']},
      }),
    );
  }

  Future<void> cambiarPassword(String email, String passwordActual, String passwordNuevo) async {
    final respUsuarios = await http.get(Uri.parse('$_baseUrl/api/usuarios'));
    final usuarios = jsonDecode(respUsuarios.body) as List;
    final usuario = usuarios.firstWhere((u) => u['email'] == email, orElse: () => null);
    if (usuario == null) throw Exception('Usuario no encontrado');

    await http.put(
      Uri.parse('$_baseUrl/api/usuarios/${usuario['idUsuario']}/password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': passwordNuevo}),
    );
  }

  // Resumen del dia para el dashboard
  Future<Map<String, dynamic>> getResumenDia({String? idSucursal}) async {
    final hoy = _hoy();
    final ventasHoy = await getHistorialVentas(idSucursal: idSucursal, fecha: hoy);

    double totalVentasContado = 0;
    double totalVentasFiado   = 0;
    int cantVentas = 0;
    int cantFiados = 0;
    final Map<String, Map<String, dynamic>> porMetodo = {};
    final movimientos = <Map<String, dynamic>>[];

    for (final v in ventasHoy) {
      if (v.esFiado) {
        totalVentasFiado += v.total;
        cantFiados++;
      } else {
        totalVentasContado += v.total;
        cantVentas++;
        porMetodo.putIfAbsent(v.metodoPagoNombre, () => {'metodo': v.metodoPagoNombre, 'cantidad': 0, 'subtotal': 0.0});
        porMetodo[v.metodoPagoNombre]!['cantidad'] = (porMetodo[v.metodoPagoNombre]!['cantidad'] as int) + 1;
        porMetodo[v.metodoPagoNombre]!['subtotal'] = (porMetodo[v.metodoPagoNombre]!['subtotal'] as double) + v.total;
      }
      movimientos.add({
        'tipo': 'venta', 'id': v.idVenta, 'monto': v.total,
        'nombre_cliente': v.clienteNombre, 'metodo': v.metodoPagoNombre,
        'usuario': '', 'sucursal': '', 'observacion': '',
        'es_fiado': v.esFiado, 'timestamp': v.timestamp,
      });
    }

    final respAbonos = await http.get(Uri.parse('$_baseUrl/api/abonos'));
    final abonos = respAbonos.statusCode == 200 ? jsonDecode(respAbonos.body) as List : [];
    double totalAbonos = 0;
    int cantAbonos = 0;
    for (final a in abonos) {
      if (a['fecha'] != hoy) continue;
      totalAbonos += (a['monto'] as num?)?.toDouble() ?? 0;
      cantAbonos++;
      movimientos.add({
        'tipo': 'abono', 'id': a['idAbono'].toString(), 'monto': (a['monto'] as num?)?.toDouble() ?? 0,
        'nombre_cliente': '', 'metodo': 'Abono', 'usuario': '', 'sucursal': '',
        'observacion': '', 'timestamp': 0,
      });
    }

    final respInventario = await http.get(Uri.parse('$_baseUrl/api/inventario'));
    final inventarios = respInventario.statusCode == 200 ? jsonDecode(respInventario.body) as List : [];
    int stockBajo = 0;
    for (final inv in inventarios) {
      if (idSucursal != null && inv['sucursal']['idSucursal'].toString() != idSucursal) continue;
      final stock = (inv['stock'] as num?)?.toInt() ?? 0;
      final stockMin = (inv['stockMinimo'] as num?)?.toInt() ?? 0;
      if (stock <= stockMin) stockBajo++;
    }

    final clientes = await getClientes();
    int clientesConDeuda = 0;
    double totalDeuda = 0;
    for (final c in clientes) {
      if (c.saldoPendiente > 0) { clientesConDeuda++; totalDeuda += c.saldoPendiente; }
    }

    movimientos.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

    return {
      'total_ventas':        totalVentasContado,
      'cantidad_ventas':     cantVentas,
      'total_fiados_hoy':    totalVentasFiado,
      'cantidad_fiados_hoy': cantFiados,
      'ventas_por_metodo':   porMetodo.values.toList(),
      'total_abonos':        totalAbonos,
      'cantidad_abonos':     cantAbonos,
      'total_dia':           totalVentasContado + totalAbonos,
      'stock_bajo':          stockBajo,
      'clientes_con_deuda':  clientesConDeuda,
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
  // ═══════════════════════════════════════════════════════════════════════════
  // ── Helper interno ───────────────────────────────────────────────────────
  String _dateToStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── CU03: Resumen de una fecha específica ─────────────────────────────────
  Future<Map<String, dynamic>> getResumenFecha({
    required DateTime fecha,
    String? idSucursal,
  }) async {
    final fechaStr = _dateToStr(fecha);

    // ── Ventas ──────────────────────────────────────────────────────────────
    final snapV = await _ventas.orderByChild('fecha').equalTo(fechaStr).get();
    double totalVentasContado = 0;
    double totalVentasFiado   = 0;
    int    cantVentas = 0;
    int    cantFiados = 0;
    final Map<String, Map<String, dynamic>> porMetodo   = {};
    final Map<String, Map<String, dynamic>> porProducto = {};

    if (snapV.exists) {
      for (final e in _map(snapV.value).entries) {
        final d = _map(e.value);
        if (d['anulada'] == true) continue;
        if (idSucursal != null && d['id_sucursal'] != idSucursal) continue;

        final t       = (d['total'] as num?)?.toDouble() ?? 0;
        final metodo  = d['metodo_pago_nombre']?.toString() ?? 'Efectivo';
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

        // Productos vendidos (para la tabla del resumen)
        for (final item in (d['items'] as List? ?? [])) {
          final it     = _map(item);
          final idProd = it['id_producto']?.toString() ?? '';
          final nombre = it['nombre_producto']?.toString() ?? 'Producto';
          final cant   = (it['cantidad'] as num?)?.toInt() ?? 1;
          final sub    = (it['subtotal'] as num?)?.toDouble()
              ?? ((it['precio_unitario'] as num?)?.toDouble() ?? 0) * cant;
          porProducto.putIfAbsent(idProd, () => {'nombre': nombre, 'cantidad': 0, 'total': 0.0});
          porProducto[idProd]!['cantidad'] = (porProducto[idProd]!['cantidad'] as int) + cant;
          porProducto[idProd]!['total']    = (porProducto[idProd]!['total'] as double) + sub;
        }
      }
    }

    // ── Abonos ──────────────────────────────────────────────────────────────
    final snapA = await _abonos.orderByChild('fecha').equalTo(fechaStr).get();
    double totalAbonos = 0;
    int    cantAbonos  = 0;

    if (snapA.exists) {
      for (final e in _map(snapA.value).entries) {
        final d = _map(e.value);
        if (idSucursal != null && d['id_sucursal'] != idSucursal) continue;
        totalAbonos += (d['monto'] as num?)?.toDouble() ?? 0;
        cantAbonos++;
      }
    }

    final productosLista = porProducto.values.toList()
      ..sort((a, b) => (b['cantidad'] as int).compareTo(a['cantidad'] as int));

    return {
      'total_ventas':       totalVentasContado,
      'cantidad_ventas':    cantVentas,
      'total_fiados':       totalVentasFiado,
      'cantidad_fiados':    cantFiados,
      'total_abonos':       totalAbonos,
      'cantidad_abonos':    cantAbonos,
      'total_dia':          totalVentasContado + totalAbonos,
      'ventas_por_metodo':  porMetodo.values.toList(),
      'productos_vendidos': productosLista,
    };
  }

  // ── CU07: Historial con filtros avanzados (solo Admin) ────────────────────
  Future<List<Map<String, dynamic>>> getHistorialVentasFiltrado({
    String? idSucursal,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? tipo,      // 'venta' | 'abono' | 'fiado' | null = todos
    String? metodo,    // 'Efectivo' | 'Nequi' … | null = todos
    String? busqueda,  // filtra por nombre de cliente o producto
    int limite  = 30,
    int offset  = 0,
  }) async {
    final desde = fechaDesde != null ? _dateToStr(fechaDesde) : '2000-01-01';
    final hasta = fechaHasta != null ? _dateToStr(fechaHasta) : _hoy();

    final resultado = <Map<String, dynamic>>[];

    // ── 1. Ventas / Fiados ─────────────────────────────────────────────────
    if (tipo == null || tipo == 'venta' || tipo == 'fiado') {
      final snapV = await _ventas
          .orderByChild('fecha')
          .startAt(desde)
          .endAt(hasta)
          .get();

      if (snapV.exists) {
        for (final e in _map(snapV.value).entries) {
          final d = _map(e.value);
          if (d['anulada'] == true) continue;
          if (idSucursal != null && d['id_sucursal'] != idSucursal) continue;

          final esFiado  = d['tipo_venta']?.toString() == 'Fiado';
          final tipoReal = esFiado ? 'fiado' : 'venta';

          // Filtro tipo exacto
          if (tipo == 'venta' && esFiado)  continue;
          if (tipo == 'fiado' && !esFiado) continue;

          // Filtro método
          final metodoPago = d['metodo_pago_nombre']?.toString() ?? '';
          if (metodo != null &&
              metodo.toLowerCase() != metodoPago.toLowerCase()) continue;

          // Filtro búsqueda: cliente o cualquier producto del pedido
          if (busqueda != null && busqueda.isNotEmpty) {
            final q       = busqueda.toLowerCase();
            final cliente = (d['cliente_nombre'] ?? '').toString().toLowerCase();
            final enProd  = (d['items'] as List? ?? []).any((it) {
              final m = _map(it);
              return (m['nombre_producto'] ?? '').toString().toLowerCase().contains(q);
            });
            if (!cliente.contains(q) && !enProd) continue;
          }

          final productos = (d['items'] as List? ?? []).map((it) {
            final m = _map(it);
            final c = (m['cantidad'] as num?)?.toInt() ?? 1;
            final p = (m['precio_unitario'] as num?)?.toDouble() ?? 0;
            return <String, dynamic>{
              'nombre':   m['nombre_producto'] ?? '',
              'cantidad': c,
              'subtotal': (m['subtotal'] as num?)?.toDouble() ?? (p * c),
            };
          }).toList();

          resultado.add({
            'id':        e.key,
            'fecha':     d['fecha'] ?? desde,
            'timestamp': (d['timestamp'] as num?)?.toInt() ?? 0,
            'monto':     (d['total'] as num?)?.toDouble() ?? 0,
            'metodo':    metodoPago,
            'cliente':   d['cliente_nombre']  ?? 'Contado',
            'usuario':   d['usuario_nombre']  ?? '',
            'sucursal':  d['sucursal_nombre'] ?? '',
            'tipo':      tipoReal,
            'productos': productos,
          });
        }
      }
    }

    // ── 2. Abonos ──────────────────────────────────────────────────────────
    if (tipo == null || tipo == 'abono') {
      final snapA = await _abonos
          .orderByChild('fecha')
          .startAt(desde)
          .endAt(hasta)
          .get();

      if (snapA.exists) {
        final snapU = await _usuarios.get();
        final mapU  = snapU.exists ? _map(snapU.value) : <String, dynamic>{};
        final snapC = await _clientes.get();
        final mapC  = snapC.exists ? _map(snapC.value) : <String, dynamic>{};

        for (final e in _map(snapA.value).entries) {
          final d = _map(e.value);
          if (idSucursal != null && d['id_sucursal'] != idSucursal) continue;

          // Abonos no tienen método de pago → saltar filtro de método
          if (metodo != null) continue;

          final idU     = d['id_usuario'] as String?;
          final idC     = d['id_cliente'] as String?;
          final uNombre = idU != null && mapU.containsKey(idU)
              ? (_map(mapU[idU])['nombre'] ?? '').toString() : '';
          final cNombre = idC != null && mapC.containsKey(idC)
              ? (_map(mapC[idC])['nombre'] ?? '').toString() : '';

          if (busqueda != null && busqueda.isNotEmpty) {
            if (!cNombre.toLowerCase().contains(busqueda.toLowerCase())) continue;
          }

          resultado.add({
            'id':        e.key,
            'fecha':     d['fecha'] ?? desde,
            'timestamp': (d['timestamp'] as num?)?.toInt() ?? 0,
            'monto':     (d['monto'] as num?)?.toDouble() ?? 0,
            'metodo':    'Abono',
            'cliente':   cNombre,
            'usuario':   uNombre,
            'sucursal':  d['sucursal_nombre'] ?? '',
            'tipo':      'abono',
            'productos': <Map<String, dynamic>>[],
          });
        }
      }
    }

    // Ordenar por timestamp desc y paginar
    resultado.sort((a, b) =>
        (b['timestamp'] as int).compareTo(a['timestamp'] as int));

    if (offset >= resultado.length) return [];
    return resultado.sublist(offset, (offset + limite).clamp(0, resultado.length));
  }
}