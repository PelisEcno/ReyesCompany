// Modelos para manejar los datos del sistema

enum TipoVenta { contado, fiado }

extension TipoVentaExt on TipoVenta {
  String get valor => this == TipoVenta.contado ? 'Contado' : 'Fiado';
  static TipoVenta fromString(String s) =>
      s.toLowerCase() == 'fiado' ? TipoVenta.fiado : TipoVenta.contado;
}

// Clase para las categorias de los productos
class Categoria {
  int _idCategoria;
  String _nombre;

  Categoria({required int idCategoria, required String nombre})
      : _idCategoria = idCategoria,
        _nombre = nombre;

  factory Categoria.fromJson(Map<String, dynamic> j) => Categoria(
    idCategoria: int.tryParse(j['id_categoria'].toString()) ?? 0,
    nombre: j['nombre'] ?? '',
  );

  int get idCategoria => _idCategoria;
  String get nombre => _nombre;
  set nombre(String v) => _nombre = v;

  Map<String, dynamic> toJson() => {'id_categoria': _idCategoria, 'nombre': _nombre};
}

// Clase para los metodos de pago como efectivo o nequi
class MetodoPago {
  int _idMetodoPago;
  String _nombre;
  bool _activo;

  MetodoPago({required int idMetodoPago, required String nombre, required bool activo})
      : _idMetodoPago = idMetodoPago,
        _nombre = nombre,
        _activo = activo;

  factory MetodoPago.fromJson(Map<String, dynamic> j) => MetodoPago(
    idMetodoPago: int.tryParse(j['id_metodo_pago'].toString()) ?? 0,
    nombre: j['nombre'] ?? '',
    activo: (int.tryParse(j['activo'].toString()) ?? 1) == 1,
  );

  int get idMetodoPago => _idMetodoPago;
  String get nombre => _nombre;
  bool get activo => _activo;
  set nombre(String v) => _nombre = v;

  void activar() => _activo = true;
  void desactivar() => _activo = false;

  Map<String, dynamic> toJson() => {'id_metodo_pago': _idMetodoPago, 'nombre': _nombre, 'activo': _activo ? 1 : 0};
}

// Clase para la informacion de los productos
class Producto {
  int _idProducto;
  String _codigo;
  String _nombre;
  String _descripcion;
  int _idCategoria;
  String _categoriaNombre;
  double _precioCompra;
  double _precioVenta;
  int _stockActual;
  int _stockMinimo;

  Producto({
    required int idProducto,
    required String codigo,
    required String nombre,
    required String descripcion,
    required int idCategoria,
    required String categoriaNombre,
    required double precioCompra,
    required double precioVenta,
    required int stockActual,
    required int stockMinimo,
  })  : _idProducto = idProducto,
        _codigo = codigo,
        _nombre = nombre,
        _descripcion = descripcion,
        _idCategoria = idCategoria,
        _categoriaNombre = categoriaNombre,
        _precioCompra = precioCompra,
        _precioVenta = precioVenta,
        _stockActual = stockActual,
        _stockMinimo = stockMinimo;

  factory Producto.fromJson(Map<String, dynamic> j) => Producto(
    idProducto: int.tryParse(j['id_producto'].toString()) ?? 0,
    codigo: j['codigo'] ?? '',
    nombre: j['nombre'] ?? '',
    descripcion: j['descripcion'] ?? '',
    idCategoria: int.tryParse(j['id_categoria'].toString()) ?? 0,
    categoriaNombre: j['categoria_nombre'] ?? '',
    precioCompra: double.tryParse(j['precio_compra'].toString()) ?? 0,
    precioVenta: double.tryParse(j['precio_venta'].toString()) ?? 0,
    stockActual: int.tryParse(j['stock_actual'].toString()) ?? 0,
    stockMinimo: int.tryParse(j['stock_minimo'].toString()) ?? 0,
  );

  int get idProducto => _idProducto;
  String get codigo => _codigo;
  String get nombre => _nombre;
  String get descripcion => _descripcion;
  int get idCategoria => _idCategoria;
  String get categoriaNombre => _categoriaNombre;
  double get precioCompra => _precioCompra;
  double get precioVenta => _precioVenta;
  int get stockActual => _stockActual;
  int get stockMinimo => _stockMinimo;
  double get ganancia => _precioVenta - _precioCompra;

  set nombre(String v) => _nombre = v;
  set descripcion(String v) => _descripcion = v;
  set precioCompra(double v) => _precioCompra = v;
  set precioVenta(double v) => _precioVenta = v;
  set idCategoria(int v) => _idCategoria = v;
  set stockMinimo(int v) => _stockMinimo = v;

  void aumentarStock(int cantidad) => _stockActual += cantidad;
  void disminuirStock(int cantidad) => _stockActual -= cantidad;
  bool estaEnStockMinimo() => _stockActual <= _stockMinimo;

  Map<String, dynamic> toJson() => {
    'id_producto': _idProducto,
    'codigo': _codigo,
    'nombre': _nombre,
    'descripcion': _descripcion,
    'id_categoria': _idCategoria,
    'precio_compra': _precioCompra,
    'precio_venta': _precioVenta,
    'stock_actual': _stockActual,
    'stock_minimo': _stockMinimo,
  };
}

// Clase para los datos de los clientes y sus deudas
class Cliente {
  int _idCliente;
  String _nombre;
  String _telefono;
  String _direccion;
  double _saldoPendiente;

  Cliente({
    required int idCliente,
    required String nombre,
    required String telefono,
    required String direccion,
    required double saldoPendiente,
  })  : _idCliente = idCliente,
        _nombre = nombre,
        _telefono = telefono,
        _direccion = direccion,
        _saldoPendiente = saldoPendiente;

  factory Cliente.fromJson(Map<String, dynamic> j) => Cliente(
    idCliente: int.tryParse(j['id_cliente'].toString()) ?? 0,
    nombre: j['nombre'] ?? '',
    telefono: j['telefono'] ?? '',
    direccion: j['direccion'] ?? '',
    saldoPendiente: double.tryParse(j['saldo_pendiente'].toString()) ?? 0,
  );

  int get idCliente => _idCliente;
  String get nombre => _nombre;
  String get telefono => _telefono;
  String get direccion => _direccion;
  double get saldoPendiente => _saldoPendiente;

  set nombre(String v) => _nombre = v;
  set telefono(String v) => _telefono = v;
  set direccion(String v) => _direccion = v;

  void aumentarSaldo(double monto) => _saldoPendiente += monto;
  void disminuirSaldo(double monto) => _saldoPendiente -= monto;

  Map<String, dynamic> toJson() => {
    'id_cliente': _idCliente,
    'nombre': _nombre,
    'telefono': _telefono,
    'direccion': _direccion,
    'saldo_pendiente': _saldoPendiente,
  };
}

// Clase para los usuarios que entran al sistema
class Usuario {
  int _idUsuario;
  String _nombre;
  String _email;
  String _rol;
  bool _activo;

  Usuario({
    required int idUsuario,
    required String nombre,
    required String email,
    required String rol,
    required bool activo,
  })  : _idUsuario = idUsuario,
        _nombre = nombre,
        _email = email,
        _rol = rol,
        _activo = activo;

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
    idUsuario: int.tryParse(j['id_usuario'].toString()) ?? 0,
    nombre: j['nombre'] ?? '',
    email: j['email'] ?? '',
    rol: j['rol'] ?? '',
    activo: (int.tryParse(j['activo'].toString()) ?? 1) == 1,
  );

  int get idUsuario => _idUsuario;
  String get nombre => _nombre;
  String get email => _email;
  String get rol => _rol;
  bool get activo => _activo;

  set nombre(String v) => _nombre = v;
  set email(String v) => _email = v;

  void activar() => _activo = true;
  void desactivar() => _activo = false;
  void cambiarRol(String nuevoRol) => _rol = nuevoRol;

  Map<String, dynamic> toJson() => {
    'id_usuario': _idUsuario,
    'nombre': _nombre,
    'email': _email,
    'rol': _rol,
    'activo': _activo ? 1 : 0,
  };
}

// Clase para saber que productos se llevan en una venta
class DetalleVenta {
  final Producto _producto;
  int _cantidad;

  DetalleVenta({required Producto producto, required int cantidad})
      : _producto = producto,
        _cantidad = cantidad;

  Producto get producto => _producto;
  int get cantidad => _cantidad;
  double get precioUnitario => _producto.precioVenta;
  double get subtotal => calcularSubtotal();

  set cantidad(int v) => _cantidad = v;

  double calcularSubtotal() => _producto.precioVenta * _cantidad;

  Map<String, dynamic> toJson() => {
    'id_producto': _producto.idProducto,
    'cantidad': _cantidad,
    'precio_unitario': precioUnitario,
    'subtotal': subtotal,
  };
}

// Clase para guardar toda la informacion de una venta
class Venta {
  int _idVenta;
  DateTime _fecha;
  int _idMetodoPago;
  String _metodoPagoNombre;
  int _idUsuario;
  int? _idCliente;
  String _clienteNombre;
  double _total;
  TipoVenta _tipoVenta;
  List<DetalleVenta> _detalles;

  Venta({
    required int idVenta,
    required DateTime fecha,
    required int idMetodoPago,
    required String metodoPagoNombre,
    required int idUsuario,
    int? idCliente,
    required String clienteNombre,
    required double total,
    required TipoVenta tipoVenta,
    List<DetalleVenta>? detalles,
  })  : _idVenta = idVenta,
        _fecha = fecha,
        _idMetodoPago = idMetodoPago,
        _metodoPagoNombre = metodoPagoNombre,
        _idUsuario = idUsuario,
        _idCliente = idCliente,
        _clienteNombre = clienteNombre,
        _total = total,
        _tipoVenta = tipoVenta,
        _detalles = detalles ?? [];

  factory Venta.fromJson(Map<String, dynamic> j) => Venta(
    idVenta: int.tryParse(j['id_venta'].toString()) ?? 0,
    fecha: DateTime.tryParse(j['fecha'].toString()) ?? DateTime.now(),
    idMetodoPago: int.tryParse(j['id_metodo_pago'].toString()) ?? 0,
    metodoPagoNombre: j['metodo_pago'] ?? '',
    idUsuario: int.tryParse(j['id_usuario'].toString()) ?? 0,
    idCliente: j['id_cliente'] != null ? int.tryParse(j['id_cliente'].toString()) : null,
    clienteNombre: j['cliente'] ?? '',
    total: double.tryParse(j['total'].toString()) ?? 0,
    tipoVenta: TipoVentaExt.fromString(j['tipo_venta'] ?? 'Contado'),
  );

  int get idVenta => _idVenta;
  DateTime get fecha => _fecha;
  int get idMetodoPago => _idMetodoPago;
  String get metodoPagoNombre => _metodoPagoNombre;
  int get idUsuario => _idUsuario;
  int? get idCliente => _idCliente;
  String get clienteNombre => _clienteNombre;
  double get total => _total;
  TipoVenta get tipoVenta => _tipoVenta;
  List<DetalleVenta> get detalles => _detalles;
  bool get esFiado => _tipoVenta == TipoVenta.fiado;
  bool get anulada => _metodoPagoNombre.toLowerCase() == 'anulada';

  double calcularTotal() {
    _total = _detalles.fold(0, (sum, d) => sum + d.calcularSubtotal());
    return _total;
  }
}