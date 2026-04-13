// Modelos de datos para el sistema ReyesCompany

enum TipoVenta { contado, fiado }

extension TipoVentaExt on TipoVenta {
  String get valor => this == TipoVenta.contado ? 'Contado' : 'Fiado';
  static TipoVenta fromString(String s) =>
      s.toLowerCase() == 'fiado' ? TipoVenta.fiado : TipoVenta.contado;
}

// Clase para manejar la informacion de las sucursales
class Sucursal {
  final String _id;
  String _nombre;
  String _direccion;
  String _telefono;
  bool _activa;

  Sucursal({required String id, required String nombre, String direccion = '', String telefono = '', bool activa = true})
      : _id = id, _nombre = nombre, _direccion = direccion, _telefono = telefono, _activa = activa;

  factory Sucursal.fromMap(String id, Map<String, dynamic> d) => Sucursal(
    id: id, nombre: d['nombre'] ?? '', direccion: d['direccion'] ?? '',
    telefono: d['telefono'] ?? '', activa: d['estado'] ?? true,
  );

  String get idSucursal => _id;
  String get nombre     => _nombre;
  String get direccion  => _direccion;
  String get telefono   => _telefono;
  bool   get activa     => _activa;
  set nombre(String v)  => _nombre = v;

  @override
  String toString() => _nombre;
}

// Clase para las categorias de los productos
class Categoria {
  final String _id;
  String _nombre;

  Categoria({required String id, required String nombre}) : _id = id, _nombre = nombre;

  factory Categoria.fromMap(String id, Map<String, dynamic> d) =>
      Categoria(id: id, nombre: d['nombre'] ?? '');

  String get idCategoria => _id;
  String get nombre      => _nombre;
  set nombre(String v)   => _nombre = v;
}

// Clase para los metodos de pago
class MetodoPago {
  final String _id;
  String _nombre;
  bool _activo;

  MetodoPago({required String id, required String nombre, required bool activo})
      : _id = id, _nombre = nombre, _activo = activo;

  factory MetodoPago.fromMap(String id, Map<String, dynamic> d) =>
      MetodoPago(id: id, nombre: d['nombre'] ?? '', activo: d['activo'] ?? true);

  factory MetodoPago.fromJson(Map<String, dynamic> j) => MetodoPago(
    id:     j['id']?.toString() ?? j['id_metodo_pago']?.toString() ?? '',
    nombre: j['nombre'] ?? '',
    activo: j['activo'] is bool ? j['activo'] : ((j['activo'] as int?) ?? 1) == 1,
  );

  String get idMetodoPago => _id;
  String get nombre       => _nombre;
  bool   get activo       => _activo;
  void activar()          => _activo = true;
  void desactivar()       => _activo = false;
}

// Clase para guardar los datos de los productos
class Producto {
  final String _id;
  String _nombre;
  String _descripcion;
  String _idCategoria;
  String _categoriaNombre;
  double _precioCompra;
  double _precioVenta;
  int _stockActual;
  int _stockMinimo;

  Producto({
    required String id,
    required String nombre,
    String descripcion = '',
    required String idCategoria,
    String categoriaNombre = '',
    required double precioCompra,
    required double precioVenta,
    required int stockActual,
    required int stockMinimo,
  })  : _id             = id,
        _nombre         = nombre,
        _descripcion    = descripcion,
        _idCategoria    = idCategoria,
        _categoriaNombre = categoriaNombre,
        _precioCompra   = precioCompra,
        _precioVenta    = precioVenta,
        _stockActual    = stockActual,
        _stockMinimo    = stockMinimo;

  factory Producto.fromMap(String id, Map<String, dynamic> d, {int stockActual = 0, int stockMinimo = 0}) => Producto(
    id:              id,
    nombre:          d['nombre']           ?? '',
    descripcion:     d['descripcion']      ?? '',
    idCategoria:     d['id_categoria']     ?? '',
    categoriaNombre: d['categoria_nombre'] ?? '',
    precioCompra:    (d['precio_compra']   as num?)?.toDouble() ?? 0,
    precioVenta:     (d['precio_venta']    as num?)?.toDouble() ?? 0,
    stockActual:     stockActual,
    stockMinimo:     stockMinimo,
  );

  String get idProducto      => _id;
  String get codigo          => _id.substring(0, _id.length.clamp(0, 6)).toUpperCase();
  String get nombre          => _nombre;
  String get descripcion     => _descripcion;
  String get idCategoria     => _idCategoria;
  String get categoriaNombre => _categoriaNombre;
  double get precioCompra    => _precioCompra;
  double get precioVenta     => _precioVenta;
  int    get stockActual     => _stockActual;
  int    get stockMinimo     => _stockMinimo;
  double get ganancia        => _precioVenta - _precioCompra;

  set nombre(String v)       => _nombre = v;
  set descripcion(String v)  => _descripcion = v;
  set precioCompra(double v) => _precioCompra = v;
  set precioVenta(double v)  => _precioVenta = v;
  set idCategoria(String v)  => _idCategoria = v;
  set stockMinimo(int v)     => _stockMinimo = v;

  void aumentarStock(int c)  => _stockActual += c;
  void disminuirStock(int c) => _stockActual -= c;
  bool estaEnStockMinimo()   => _stockActual <= _stockMinimo;
}

// Clase para la informacion de los clientes
class Cliente {
  final String _id;
  String _nombre;
  String _telefono;
  String _direccion;
  double _saldoPendiente;

  Cliente({required String id, required String nombre, String telefono = '', String direccion = '', double saldoPendiente = 0})
      : _id = id, _nombre = nombre, _telefono = telefono, _direccion = direccion, _saldoPendiente = saldoPendiente;

  factory Cliente.fromMap(String id, Map<String, dynamic> d) => Cliente(
    id:             id,
    nombre:         d['nombre']          ?? '',
    telefono:       d['telefono']        ?? '',
    direccion:      d['direccion']       ?? '',
    saldoPendiente: (d['saldo_pendiente'] as num?)?.toDouble() ?? 0,
  );

  factory Cliente.fromJson(Map<String, dynamic> j) => Cliente(
    id:             j['id_cliente']?.toString() ?? '',
    nombre:         j['nombre']          ?? '',
    telefono:       j['telefono']        ?? '',
    direccion:      j['direccion']       ?? '',
    saldoPendiente: (j['saldo_pendiente'] as num?)?.toDouble() ?? 0,
  );

  String get idCliente      => _id;
  String get nombre         => _nombre;
  String get telefono       => _telefono;
  String get direccion      => _direccion;
  double get saldoPendiente => _saldoPendiente;

  set nombre(String v)    => _nombre = v;
  set telefono(String v)  => _telefono = v;
  set direccion(String v) => _direccion = v;

  void aumentarSaldo(double m)  => _saldoPendiente += m;
  void disminuirSaldo(double m) => _saldoPendiente -= m;
}

// Clase para manejar los usuarios del sistema
class Usuario {
  final String _id;
  String _nombre;
  String _email;
  String _rol;
  bool _activo;
  String? _idSucursal;
  String _sucursalNombre;

  Usuario({required String id, required String nombre, required String email, required String rol, required bool activo, String? idSucursal, String sucursalNombre = ''})
      : _id = id, _nombre = nombre, _email = email, _rol = rol, _activo = activo, _idSucursal = idSucursal, _sucursalNombre = sucursalNombre;

  factory Usuario.fromMap(String id, Map<String, dynamic> d, {String sucursalNombre = ''}) => Usuario(
    id:             id,
    nombre:         d['nombre']      ?? '',
    email:          d['email']       ?? '',
    rol:            d['rol']         ?? 'Empleado',
    activo:         d['activo']      ?? true,
    idSucursal:     d['id_sucursal'] as String?,
    sucursalNombre: sucursalNombre,
  );

  String  get idUsuario      => _id;
  String  get nombre         => _nombre;
  String  get email          => _email;
  String  get rol            => _rol;
  bool    get activo         => _activo;
  String? get idSucursal     => _idSucursal;
  String  get sucursalNombre => _sucursalNombre;
  bool    get esAdminGlobal  => _idSucursal == null;

  set nombre(String v)      => _nombre = v;
  set email(String v)       => _email = v;
  set idSucursal(String? v) => _idSucursal = v;

  void activar()                   => _activo = true;
  void desactivar()                => _activo = false;
  void cambiarRol(String r)        => _rol = r;
}

// Detalle de los productos que se venden
class DetalleVenta {
  final Producto _producto;
  int _cantidad;

  DetalleVenta({required Producto producto, required int cantidad})
      : _producto = producto, _cantidad = cantidad;

  Producto get producto       => _producto;
  int      get cantidad       => _cantidad;
  double   get precioUnitario => _producto.precioVenta;
  double   get subtotal       => _producto.precioVenta * _cantidad;
  set cantidad(int v)         => _cantidad = v;

  Map<String, dynamic> toMap() => {
    'id_producto':     _producto.idProducto,
    'nombre_producto': _producto.nombre,
    'cantidad':        _cantidad,
    'precio_unitario': precioUnitario,
    'subtotal':        subtotal,
  };
}

// Informacion general de una venta realizada
class Venta {
  final String _id;
  final String _fecha;
  final String _idMetodoPago;
  final String _metodoPagoNombre;
  final String _idUsuario;
  final String? _idCliente;
  final String _clienteNombre;
  final double _total;
  final TipoVenta _tipoVenta;
  final String _idSucursal;
  final bool _anulada;
  final int _timestamp;

  Venta({
    required String id,
    required String fecha,
    required String idMetodoPago,
    required String metodoPagoNombre,
    required String idUsuario,
    String? idCliente,
    String clienteNombre = '',
    required double total,
    required TipoVenta tipoVenta,
    required String idSucursal,
    bool anulada = false,
    int timestamp = 0,
  })  : _id              = id,
        _fecha           = fecha,
        _idMetodoPago    = idMetodoPago,
        _metodoPagoNombre = metodoPagoNombre,
        _idUsuario       = idUsuario,
        _idCliente       = idCliente,
        _clienteNombre   = clienteNombre,
        _total           = total,
        _tipoVenta       = tipoVenta,
        _idSucursal      = idSucursal,
        _anulada         = anulada,
        _timestamp       = timestamp;

  factory Venta.fromMap(String id, Map<String, dynamic> d) => Venta(
    id:               id,
    fecha:            d['fecha']             ?? '',
    idMetodoPago:     d['id_metodo_pago']    ?? '',
    metodoPagoNombre: d['metodo_pago_nombre'] ?? '',
    idUsuario:        d['id_usuario']        ?? '',
    idCliente:        d['id_cliente']        as String?,
    clienteNombre:    d['cliente_nombre']    ?? '',
    total:            (d['total']            as num?)?.toDouble() ?? 0,
    tipoVenta:        TipoVentaExt.fromString(d['tipo_venta'] ?? 'Contado'),
    idSucursal:       d['id_sucursal']       ?? '',
    anulada:          d['anulada']           ?? false,
    timestamp:        (d['timestamp']        as num?)?.toInt() ?? 0,
  );

  String   get idVenta          => _id;
  String   get fecha            => _fecha;
  String   get idMetodoPago     => _idMetodoPago;
  String   get metodoPagoNombre => _metodoPagoNombre;
  String   get idUsuario        => _idUsuario;
  String?  get idCliente        => _idCliente;
  String   get clienteNombre    => _clienteNombre;
  double   get total            => _total;
  TipoVenta get tipoVenta       => _tipoVenta;
  String   get idSucursal       => _idSucursal;
  bool     get esFiado          => _tipoVenta == TipoVenta.fiado;
  bool     get anulada          => _anulada;
  int      get timestamp        => _timestamp;
}