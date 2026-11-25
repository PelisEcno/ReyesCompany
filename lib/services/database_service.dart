import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _i = DatabaseService._();
  factory DatabaseService() => _i;
  DatabaseService._();

  static const String _baseUrl = 'https://reyescompany.onrender.com';

  final http.Client _client = http.Client();

  String _hoy() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  String _dateToStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List _lista(http.Response respuesta) =>
      respuesta.statusCode == 200 ? jsonDecode(respuesta.body) as List : [];

  String _mensajeError(http.Response respuesta, String porDefecto) {
    try {
      final mensaje = jsonDecode(respuesta.body)['message'];
      if (mensaje != null && mensaje.toString().isNotEmpty) return mensaje.toString();
    } catch (_) {}
    return porDefecto;
  }

  // Metodo para loguear usuarios contra el backend en Render
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/api/auth/login');
    final response = await _client.post(
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

  Future<List<Sucursal>> getSucursales() async {
    final response = await _client.get(Uri.parse('$_baseUrl/api/sucursales'));
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
    final response = await _client.get(Uri.parse('$_baseUrl/api/categorias'));
    if (response.statusCode != 200) throw Exception('Error al cargar categorias');
    final lista = jsonDecode(response.body) as List;
    return lista
        .map((d) => Categoria(id: d['idCategoria'].toString(), nombre: d['nombre'] ?? ''))
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  Future<void> crearCategoria(String nombre) async {
    await _client.post(
      Uri.parse('$_baseUrl/api/categorias'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombre}),
    );
  }

  Future<List<MetodoPago>> getMetodosPago() async {
    final response = await _client.get(Uri.parse('$_baseUrl/api/metodos-pago'));
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
    final respuestas = await Future.wait([
      _client.get(Uri.parse('$_baseUrl/api/productos')),
      _client.get(Uri.parse('$_baseUrl/api/inventario')),
    ]);
    final respProductos = respuestas[0];
    final respInventario = respuestas[1];
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
    final respExistentes = await _client.get(Uri.parse('$_baseUrl/api/productos'));
    final yaExiste = _lista(respExistentes).any(
      (p) => (p['nombre'] ?? '').toString().trim().toLowerCase() == nombre.trim().toLowerCase(),
    );
    if (yaExiste) throw Exception('Ya existe un producto con el nombre "$nombre"');

    final respProducto = await _client.post(
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

    await _client.post(
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
    await _client.put(
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

    final respInventario = await _client.get(Uri.parse('$_baseUrl/api/inventario'));
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
      await _client.put(
        Uri.parse('$_baseUrl/api/inventario/${existente['idInventario']}'),
        headers: {'Content-Type': 'application/json'},
        body: cuerpo,
      );
    } else {
      await _client.post(
        Uri.parse('$_baseUrl/api/inventario'),
        headers: {'Content-Type': 'application/json'},
        body: cuerpo,
      );
    }
  }

  Future<void> eliminarProducto(String id) async {
    final respInventario = await _client.get(Uri.parse('$_baseUrl/api/inventario'));
    final inventarios = jsonDecode(respInventario.body) as List;
    for (final inv in inventarios) {
      if (inv['producto']['idProducto'].toString() == id) {
        await _client.delete(Uri.parse('$_baseUrl/api/inventario/${inv['idInventario']}'));
      }
    }
    await _client.delete(Uri.parse('$_baseUrl/api/productos/$id'));
  }

  // Guardar la venta y bajar el stock
  // Tu modelo real exige un cliente en toda venta, incluso de contado.
  // Si no se elige uno, usamos/creamos un cliente generico "Consumidor Final".
  Future<String> _obtenerOCrearClienteGenerico() async {
    final respClientes = await _client.get(Uri.parse('$_baseUrl/api/clientes'));
    final clientes = jsonDecode(respClientes.body) as List;
    final existente = clientes.firstWhere((c) => c['nombre'] == 'Consumidor Final', orElse: () => null);
    if (existente != null) return existente['idCliente'].toString();

    final respNuevo = await _client.post(
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

    final respInventario = await _client.get(Uri.parse('$_baseUrl/api/inventario'));
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

    final response = await _client.post(
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

    if (response.statusCode != 200) throw Exception(_mensajeError(response, 'No se pudo registrar la venta'));
    final venta = jsonDecode(response.body);
    return venta['idVenta'].toString();
  }

  Future<List<Venta>> getHistorialVentas({String? idSucursal, String? fecha}) async {
    final hoy = fecha ?? _hoy();
    final respuestas = await Future.wait([
      _client.get(Uri.parse('$_baseUrl/api/ventas')),
      _client.get(Uri.parse('$_baseUrl/api/pagos')),
      _client.get(Uri.parse('$_baseUrl/api/deudas-cliente')),
    ]);
    final respVentas = respuestas[0];
    final respPagos = respuestas[1];
    final respDeudas = respuestas[2];

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

  Future<void> anularVenta(String idVenta) async {
    final response = await _client.post(Uri.parse('$_baseUrl/api/ventas/$idVenta/anular'));
    if (response.statusCode != 200) throw Exception(_mensajeError(response, 'No se pudo anular la venta'));
  }

  // El cliente ya no tiene sucursal fija ni saldo guardado directo en tu modelo real:
  // el saldo pendiente se calcula sumando las deudas (deuda_cliente) y restando los abonos.
  Future<List<Cliente>> getClientes({String? idSucursal}) async {
    final respuestas = await Future.wait([
      _client.get(Uri.parse('$_baseUrl/api/clientes')),
      _client.get(Uri.parse('$_baseUrl/api/deudas-cliente')),
      _client.get(Uri.parse('$_baseUrl/api/abonos')),
    ]);
    final respClientes = respuestas[0];
    final respDeudas = respuestas[1];
    final respAbonos = respuestas[2];
    if (respClientes.statusCode != 200) throw Exception('Error al cargar clientes');

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
    await _client.post(
      Uri.parse('$_baseUrl/api/clientes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombre, 'apellido': '', 'telefono': telefono, 'direccion': direccion}),
    );
  }

  Future<void> editarCliente({
    required String id, required String nombre,
    String telefono = '', String direccion = '',
  }) async {
    await _client.put(
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
    await _client.delete(Uri.parse('$_baseUrl/api/clientes/$id'));
  }

  // Tu modelo real no guarda un saldo fijo: cada abono se aplica contra
  // las deudas (deuda_cliente) mas antiguas del cliente hasta completar el monto.
  Future<void> registrarAbono({
    required String idCliente, required String idUsuario,
    required String idSucursal,
    required double monto, String observacion = '',
  }) async {
    if (monto <= 0) throw Exception('El monto debe ser mayor a 0');

    final respuestas = await Future.wait([
      _client.get(Uri.parse('$_baseUrl/api/deudas-cliente')),
      _client.get(Uri.parse('$_baseUrl/api/abonos')),
    ]);
    final deudas = jsonDecode(respuestas[0].body) as List;
    final abonos = jsonDecode(respuestas[1].body) as List;

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
      await _client.post(
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
    final respDeudas = await _client.get(Uri.parse('$_baseUrl/api/deudas-cliente'));
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
    final respuestas = await Future.wait([
      _client.get(Uri.parse('$_baseUrl/api/deudas-cliente')),
      _client.get(Uri.parse('$_baseUrl/api/abonos')),
    ]);
    final deudas = jsonDecode(respuestas[0].body) as List;
    final abonos = jsonDecode(respuestas[1].body) as List;

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
    final response = await _client.get(Uri.parse('$_baseUrl/api/usuarios'));
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
    final respRoles = await _client.get(Uri.parse('$_baseUrl/api/roles'));
    final roles = jsonDecode(respRoles.body) as List;
    final existente = roles.firstWhere((r) => r['nombre'] == nombreRol, orElse: () => null);
    if (existente != null) return existente['idRol'] as int;

    final respNuevo = await _client.post(
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
    await _client.post(
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
    final respActual = await _client.get(Uri.parse('$_baseUrl/api/usuarios/$id'));
    final actual = jsonDecode(respActual.body);
    final idRol = await _obtenerOCrearRol(rol);

    await _client.put(
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
    final respActual = await _client.get(Uri.parse('$_baseUrl/api/usuarios/$id'));
    final actual = jsonDecode(respActual.body);

    await _client.put(
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
    final respUsuarios = await _client.get(Uri.parse('$_baseUrl/api/usuarios'));
    final usuarios = jsonDecode(respUsuarios.body) as List;
    final usuario = usuarios.firstWhere((u) => u['email'] == email, orElse: () => null);
    if (usuario == null) throw Exception('Usuario no encontrado');

    await _client.put(
      Uri.parse('$_baseUrl/api/usuarios/${usuario['idUsuario']}/password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': passwordNuevo}),
    );
  }

  // Resumen del dia para el dashboard
  Future<Map<String, dynamic>> getResumenDia({String? idSucursal}) async {
    final hoy = _hoy();

    final resultados = await Future.wait<dynamic>([
      getHistorialVentas(idSucursal: idSucursal, fecha: hoy),
      _client.get(Uri.parse('$_baseUrl/api/abonos')),
      _client.get(Uri.parse('$_baseUrl/api/inventario')),
      getClientes(),
    ]);
    final ventasHoy = resultados[0] as List<Venta>;
    final respAbonos = resultados[1] as http.Response;
    final respInventario = resultados[2] as http.Response;
    final clientes = resultados[3] as List<Cliente>;

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

    final inventarios = respInventario.statusCode == 200 ? jsonDecode(respInventario.body) as List : [];
    int stockBajo = 0;
    for (final inv in inventarios) {
      if (idSucursal != null && inv['sucursal']['idSucursal'].toString() != idSucursal) continue;
      final stock = (inv['stock'] as num?)?.toInt() ?? 0;
      final stockMin = (inv['stockMinimo'] as num?)?.toInt() ?? 0;
      if (stock <= stockMin) stockBajo++;
    }

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

  Future<Map<String, dynamic>> getResumenFecha({required DateTime fecha, String? idSucursal}) =>
      getResumenRango(desde: fecha, hasta: fecha, idSucursal: idSucursal);

  Future<Map<String, dynamic>> getResumenRango({
    required DateTime desde, required DateTime hasta, String? idSucursal,
  }) async {
    final fechaDesde = _dateToStr(desde);
    final fechaHasta = _dateToStr(hasta);

    final respuestas = await Future.wait([
      _client.get(Uri.parse('$_baseUrl/api/ventas')),
      _client.get(Uri.parse('$_baseUrl/api/pagos')),
      _client.get(Uri.parse('$_baseUrl/api/deudas-cliente')),
      _client.get(Uri.parse('$_baseUrl/api/detalle-venta')),
      _client.get(Uri.parse('$_baseUrl/api/abonos')),
    ]);
    final ventas = _lista(respuestas[0]);
    final pagos = _lista(respuestas[1]);
    final deudas = _lista(respuestas[2]);
    final detalles = _lista(respuestas[3]);
    final abonos = _lista(respuestas[4]);

    final pagoPorVenta = <String, dynamic>{};
    for (final p in pagos) {
      pagoPorVenta[p['venta']['idVenta'].toString()] = p;
    }
    final ventasFiadas = <String>{};
    for (final d in deudas) {
      ventasFiadas.add(d['venta']['idVenta'].toString());
    }

    double totalContado = 0;
    double totalFiado = 0;
    int cantVentas = 0;
    int cantFiados = 0;
    final porMetodo = <String, Map<String, dynamic>>{};
    final porDia = <String, Map<String, dynamic>>{};
    final idsVentas = <String>{};

    for (final v in ventas) {
      final fecha = v['fecha'].toString();
      if (fecha.compareTo(fechaDesde) < 0 || fecha.compareTo(fechaHasta) > 0) continue;
      if (idSucursal != null && v['sucursal']['idSucursal'].toString() != idSucursal) continue;

      final idVenta = v['idVenta'].toString();
      final total = (v['total'] as num?)?.toDouble() ?? 0;
      idsVentas.add(idVenta);

      porDia.putIfAbsent(fecha, () => {'fecha': fecha, 'total': 0.0, 'cantidad': 0});
      porDia[fecha]!['total'] = (porDia[fecha]!['total'] as double) + total;
      porDia[fecha]!['cantidad'] = (porDia[fecha]!['cantidad'] as int) + 1;

      if (ventasFiadas.contains(idVenta)) {
        totalFiado += total;
        cantFiados++;
      } else {
        totalContado += total;
        cantVentas++;
        final pago = pagoPorVenta[idVenta];
        final metodo = pago != null ? (pago['metodoPago']['nombre'] ?? 'Efectivo').toString() : 'Efectivo';
        porMetodo.putIfAbsent(metodo, () => {'metodo': metodo, 'cantidad': 0, 'subtotal': 0.0});
        porMetodo[metodo]!['cantidad'] = (porMetodo[metodo]!['cantidad'] as int) + 1;
        porMetodo[metodo]!['subtotal'] = (porMetodo[metodo]!['subtotal'] as double) + total;
      }
    }

    final porProducto = <String, Map<String, dynamic>>{};
    for (final d in detalles) {
      if (!idsVentas.contains(d['venta']['idVenta'].toString())) continue;
      final producto = d['inventario']['producto'];
      final idProducto = producto['idProducto'].toString();
      final cantidad = (d['cantidad'] as num?)?.toInt() ?? 0;
      final precio = (d['precioUnitario'] as num?)?.toDouble() ?? 0;
      porProducto.putIfAbsent(idProducto, () => {'nombre': producto['nombre'] ?? 'Producto', 'cantidad': 0, 'total': 0.0});
      porProducto[idProducto]!['cantidad'] = (porProducto[idProducto]!['cantidad'] as int) + cantidad;
      porProducto[idProducto]!['total'] = (porProducto[idProducto]!['total'] as double) + precio * cantidad;
    }

    double totalAbonos = 0;
    int cantAbonos = 0;
    for (final a in abonos) {
      final fecha = a['fecha'].toString();
      if (fecha.compareTo(fechaDesde) < 0 || fecha.compareTo(fechaHasta) > 0) continue;
      final sucursalAbono = a['deudaCliente']['venta']['sucursal']['idSucursal'].toString();
      if (idSucursal != null && sucursalAbono != idSucursal) continue;
      totalAbonos += (a['monto'] as num?)?.toDouble() ?? 0;
      cantAbonos++;
    }

    final productosLista = porProducto.values.toList()
      ..sort((a, b) => (b['cantidad'] as int).compareTo(a['cantidad'] as int));
    final dias = porDia.values.toList()
      ..sort((a, b) => (a['fecha'] as String).compareTo(b['fecha'] as String));

    return {
      'total_ventas':       totalContado,
      'cantidad_ventas':    cantVentas,
      'total_fiados':       totalFiado,
      'cantidad_fiados':    cantFiados,
      'total_abonos':       totalAbonos,
      'cantidad_abonos':    cantAbonos,
      'total_dia':          totalContado + totalAbonos,
      'ventas_por_metodo':  porMetodo.values.toList(),
      'productos_vendidos': productosLista,
      'por_dia':            dias,
    };
  }

  Future<List<Map<String, dynamic>>> getHistorialVentasFiltrado({
    String? idSucursal,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? tipo,
    String? metodo,
    String? busqueda,
    int limite = 30,
    int offset = 0,
  }) async {
    final desde = fechaDesde != null ? _dateToStr(fechaDesde) : '2000-01-01';
    final hasta = fechaHasta != null ? _dateToStr(fechaHasta) : _hoy();

    final respuestas = await Future.wait([
      _client.get(Uri.parse('$_baseUrl/api/ventas')),
      _client.get(Uri.parse('$_baseUrl/api/pagos')),
      _client.get(Uri.parse('$_baseUrl/api/deudas-cliente')),
      _client.get(Uri.parse('$_baseUrl/api/detalle-venta')),
      _client.get(Uri.parse('$_baseUrl/api/abonos')),
    ]);
    final ventas = _lista(respuestas[0]);
    final pagos = _lista(respuestas[1]);
    final deudas = _lista(respuestas[2]);
    final detalles = _lista(respuestas[3]);
    final abonos = _lista(respuestas[4]);

    final pagoPorVenta = <String, dynamic>{};
    for (final p in pagos) {
      pagoPorVenta[p['venta']['idVenta'].toString()] = p;
    }
    final ventasFiadas = <String>{};
    for (final d in deudas) {
      ventasFiadas.add(d['venta']['idVenta'].toString());
    }
    final productosPorVenta = <String, List<Map<String, dynamic>>>{};
    for (final d in detalles) {
      final idVenta = d['venta']['idVenta'].toString();
      final cantidad = (d['cantidad'] as num?)?.toInt() ?? 0;
      final precio = (d['precioUnitario'] as num?)?.toDouble() ?? 0;
      productosPorVenta.putIfAbsent(idVenta, () => []);
      productosPorVenta[idVenta]!.add({
        'nombre': d['inventario']['producto']['nombre'] ?? '',
        'cantidad': cantidad,
        'subtotal': precio * cantidad,
      });
    }

    final resultado = <Map<String, dynamic>>[];
    final texto = (busqueda ?? '').toLowerCase();

    if (tipo == null || tipo == 'venta' || tipo == 'fiado') {
      for (final v in ventas) {
        final fecha = v['fecha'].toString();
        if (fecha.compareTo(desde) < 0 || fecha.compareTo(hasta) > 0) continue;
        if (idSucursal != null && v['sucursal']['idSucursal'].toString() != idSucursal) continue;

        final idVenta = v['idVenta'].toString();
        final esFiado = ventasFiadas.contains(idVenta);
        if (tipo == 'venta' && esFiado) continue;
        if (tipo == 'fiado' && !esFiado) continue;

        final pago = pagoPorVenta[idVenta];
        final metodoPago = esFiado ? 'Fiado' : (pago != null ? (pago['metodoPago']['nombre'] ?? '').toString() : 'Efectivo');
        if (metodo != null && metodo.toLowerCase() != metodoPago.toLowerCase()) continue;

        final cliente = '${v['cliente']['nombre'] ?? ''} ${v['cliente']['apellido'] ?? ''}'.trim();
        final productos = productosPorVenta[idVenta] ?? <Map<String, dynamic>>[];

        if (texto.isNotEmpty) {
          final enCliente = cliente.toLowerCase().contains(texto);
          final enProducto = productos.any((p) => p['nombre'].toString().toLowerCase().contains(texto));
          if (!enCliente && !enProducto) continue;
        }

        resultado.add({
          'id':        idVenta,
          'fecha':     fecha,
          'timestamp': DateTime.parse(v['createdAt']).millisecondsSinceEpoch,
          'monto':     (v['total'] as num?)?.toDouble() ?? 0,
          'metodo':    metodoPago,
          'cliente':   cliente.isEmpty ? 'Contado' : cliente,
          'usuario':   v['usuario']['nombre'] ?? '',
          'sucursal':  v['sucursal']['nombre'] ?? '',
          'tipo':      esFiado ? 'fiado' : 'venta',
          'productos': productos,
        });
      }
    }

    if ((tipo == null || tipo == 'abono') && metodo == null) {
      for (final a in abonos) {
        final fecha = a['fecha'].toString();
        if (fecha.compareTo(desde) < 0 || fecha.compareTo(hasta) > 0) continue;

        final venta = a['deudaCliente']['venta'];
        if (idSucursal != null && venta['sucursal']['idSucursal'].toString() != idSucursal) continue;

        final clienteAbono = a['deudaCliente']['cliente'];
        final cliente = '${clienteAbono['nombre'] ?? ''} ${clienteAbono['apellido'] ?? ''}'.trim();
        if (texto.isNotEmpty && !cliente.toLowerCase().contains(texto)) continue;

        resultado.add({
          'id':        a['idAbono'].toString(),
          'fecha':     fecha,
          'timestamp': DateTime.parse(fecha).millisecondsSinceEpoch,
          'monto':     (a['monto'] as num?)?.toDouble() ?? 0,
          'metodo':    'Abono',
          'cliente':   cliente,
          'usuario':   '',
          'sucursal':  venta['sucursal']['nombre'] ?? '',
          'tipo':      'abono',
          'productos': <Map<String, dynamic>>[],
        });
      }
    }

    resultado.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

    if (offset >= resultado.length) return [];
    return resultado.sublist(offset, (offset + limite).clamp(0, resultado.length));
  }

  Future<List<Map<String, dynamic>>> getInventarioDetalle({String? idSucursal}) async {
    final response = await _client.get(Uri.parse('$_baseUrl/api/inventario'));
    if (response.statusCode != 200) throw Exception('Error al cargar el inventario');

    final lista = <Map<String, dynamic>>[];
    for (final i in jsonDecode(response.body) as List) {
      if (idSucursal != null && i['sucursal']['idSucursal'].toString() != idSucursal) continue;
      lista.add({
        'id_inventario': i['idInventario'].toString(),
        'producto':      i['producto']['nombre'] ?? '',
        'sucursal':      i['sucursal']['nombre'] ?? '',
        'stock':         (i['stock'] as num?)?.toInt() ?? 0,
      });
    }
    lista.sort((a, b) => (a['producto'] as String).compareTo(b['producto'] as String));
    return lista;
  }

  Future<void> registrarMovimientoInventario({
    required String idInventario, required String tipo, required int cantidad,
    required String observacion, required String idUsuario,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/movimientos-inventario/registrar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idInventario': int.parse(idInventario),
        'tipo': tipo,
        'cantidad': cantidad,
        'observacion': observacion,
        'idUsuario': int.parse(idUsuario),
      }),
    );
    if (response.statusCode != 200) throw Exception(_mensajeError(response, 'No se pudo registrar el movimiento'));
  }

  Future<List<Map<String, dynamic>>> getMovimientosInventario({String? idSucursal}) async {
    final response = await _client.get(Uri.parse('$_baseUrl/api/movimientos-inventario'));
    if (response.statusCode != 200) throw Exception('Error al cargar los movimientos');

    final lista = <Map<String, dynamic>>[];
    for (final m in jsonDecode(response.body) as List) {
      final inventario = m['inventario'];
      if (idSucursal != null && inventario['sucursal']['idSucursal'].toString() != idSucursal) continue;
      final usuario = m['usuario'];
      final venta = m['venta'];
      lista.add({
        'id':          m['idMovimientoInventario'].toString(),
        'tipo':        m['tipoMovimiento']['nombre'] ?? '',
        'producto':    inventario['producto']['nombre'] ?? '',
        'sucursal':    inventario['sucursal']['nombre'] ?? '',
        'cantidad':    (m['cantidad'] as num?)?.toInt() ?? 0,
        'fecha':       DateTime.parse(m['fecha']),
        'usuario':     usuario != null ? (usuario['nombre'] ?? '') : '',
        'observacion': m['observacion'] ?? '',
        'id_venta':    venta != null ? venta['idVenta'].toString() : '',
      });
    }
    return lista;
  }
}
