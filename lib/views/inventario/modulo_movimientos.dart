import 'package:flutter/material.dart';
import '../../services/database_service.dart';

const _primario = Color(0xFF1A5276);
const _acento   = Color(0xFF2E86C1);
const _verde    = Color(0xFF1ABC9C);
const _rojo     = Color(0xFFE74C3C);
const _naranja  = Color(0xFFE67E22);
const _fondo    = Color(0xFFF0F4F8);

class ModuloMovimientos extends StatefulWidget {
  final String idUsuario;
  final String? idSucursal;
  const ModuloMovimientos({super.key, required this.idUsuario, this.idSucursal});

  @override
  State<ModuloMovimientos> createState() => _ModuloMovimientosState();
}

class _ModuloMovimientosState extends State<ModuloMovimientos> {
  final _svc = DatabaseService();
  List<Map<String, dynamic>> _movimientos = [];
  bool _cargando = true;
  String _filtroTipo = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final lista = await _svc.getMovimientosInventario(idSucursal: widget.idSucursal);
      setState(() => _movimientos = lista);
    } catch (e) {
      _snack('Error al cargar: ${_limpiar(e)}', _rojo);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<Map<String, dynamic>> get _filtrados {
    if (_filtroTipo == 'Todos') return _movimientos;
    return _movimientos.where((m) => m['tipo'] == _filtroTipo).toList();
  }

  String _limpiar(Object error) => error.toString().replaceFirst('Exception: ', '');

  void _snack(String mensaje, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensaje, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _abrirRegistro() async {
    List<Map<String, dynamic>> items;
    try {
      items = await _svc.getInventarioDetalle(idSucursal: widget.idSucursal);
    } catch (e) {
      _snack('Error al cargar productos: ${_limpiar(e)}', _rojo);
      return;
    }
    if (items.isEmpty) {
      _snack('No hay productos en el inventario', _rojo);
      return;
    }
    if (!mounted) return;

    String seleccionado = items.first['id_inventario'];
    String tipo = 'Entrada';
    final cantidadC = TextEditingController();
    final observacionC = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) {
        final item = items.firstWhere((i) => i['id_inventario'] == seleccionado);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Registrar movimiento',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _primario)),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  DropdownButtonFormField<String>(
                    value: seleccionado,
                    isExpanded: true,
                    decoration: _decoracion('Producto'),
                    items: items.map((i) => DropdownMenuItem<String>(
                      value: i['id_inventario'],
                      child: Text('${i['producto']} · ${i['sucursal']} (stock ${i['stock']})',
                          overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) => setSt(() => seleccionado = v ?? seleccionado),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _opcionTipo('Entrada', Icons.add_circle_outline_rounded, _verde, tipo, () => setSt(() => tipo = 'Entrada'))),
                    const SizedBox(width: 10),
                    Expanded(child: _opcionTipo('Merma', Icons.remove_circle_outline_rounded, _rojo, tipo, () => setSt(() => tipo = 'Merma'))),
                  ]),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: cantidadC,
                    keyboardType: TextInputType.number,
                    decoration: _decoracion('Cantidad'),
                    validator: (v) {
                      final cantidad = int.tryParse((v ?? '').trim());
                      if (cantidad == null || cantidad <= 0) return 'Ingresa una cantidad mayor a cero';
                      if (tipo == 'Merma' && cantidad > (item['stock'] as int)) {
                        return 'La merma supera el stock actual (${item['stock']})';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: observacionC,
                    decoration: _decoracion(tipo == 'Merma' ? 'Motivo (dañado, perdido, vencido)' : 'Observación (opcional)'),
                    validator: (v) => (tipo == 'Merma' && (v ?? '').trim().isEmpty) ? 'Indica el motivo de la merma' : null,
                  ),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primario, foregroundColor: Colors.white, elevation: 0),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                _registrar(seleccionado, tipo, int.parse(cantidadC.text.trim()), observacionC.text.trim());
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _registrar(String idInventario, String tipo, int cantidad, String observacion) async {
    try {
      await _svc.registrarMovimientoInventario(
        idInventario: idInventario,
        tipo: tipo,
        cantidad: cantidad,
        observacion: observacion,
        idUsuario: widget.idUsuario,
      );
      _snack(tipo == 'Entrada' ? 'Entrada registrada' : 'Merma registrada', _verde);
      _cargar();
    } catch (e) {
      _snack(_limpiar(e), _rojo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtrados;
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primario,
        elevation: 0,
        title: const Text('Movimientos de inventario',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _primario)),
        actions: [
          IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh_rounded, color: _acento)),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _abrirRegistro,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Registrar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primario,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: ['Todos', 'Entrada', 'Merma', 'Venta', 'Anulacion'].map((t) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(t == 'Anulacion' ? 'Anulación' : t),
              selected: _filtroTipo == t,
              selectedColor: _primario,
              labelStyle: TextStyle(color: _filtroTipo == t ? Colors.white : _primario, fontSize: 12),
              onSelected: (_) => setState(() => _filtroTipo = t),
            ),
          )).toList()),
        ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator(color: _acento))
              : lista.isEmpty
                  ? const Center(child: Text('Sin movimientos registrados', style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: lista.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _tarjeta(lista[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _tarjeta(Map<String, dynamic> m) {
    final tipo = m['tipo'] as String;
    final suma = tipo == 'Entrada' || tipo == 'Anulacion';
    final color = _colorTipo(tipo);
    final detalle = <String>[
      _nombreTipo(tipo),
      if ((m['usuario'] as String).isNotEmpty) m['usuario'],
      if ((m['sucursal'] as String).isNotEmpty) m['sucursal'],
      _formatoFecha(m['fecha'] as DateTime),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(_iconoTipo(tipo), color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m['producto'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2C3E50)), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(detalle.join(' · '), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          if ((m['observacion'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(m['observacion'], style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic)),
            ),
        ])),
        Text('${suma ? '+' : '-'}${m['cantidad']}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: suma ? _verde : _rojo)),
      ]),
    );
  }

  Widget _opcionTipo(String nombre, IconData icono, Color color, String actual, VoidCallback alTocar) {
    final activo = actual == nombre;
    return GestureDetector(
      onTap: alTocar,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: activo ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: activo ? color : Colors.grey[300]!),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icono, size: 18, color: activo ? color : Colors.grey),
          const SizedBox(width: 6),
          Text(nombre, style: TextStyle(fontWeight: FontWeight.w600, color: activo ? color : Colors.grey[600])),
        ]),
      ),
    );
  }

  InputDecoration _decoracion(String etiqueta) => InputDecoration(
        labelText: etiqueta,
        labelStyle: const TextStyle(fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF4F6F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      );

  Color _colorTipo(String tipo) {
    switch (tipo) {
      case 'Entrada':   return _verde;
      case 'Merma':     return _rojo;
      case 'Anulacion': return _naranja;
      default:          return _acento;
    }
  }

  IconData _iconoTipo(String tipo) {
    switch (tipo) {
      case 'Entrada':   return Icons.add_circle_outline_rounded;
      case 'Merma':     return Icons.remove_circle_outline_rounded;
      case 'Anulacion': return Icons.undo_rounded;
      default:          return Icons.point_of_sale_rounded;
    }
  }

  String _nombreTipo(String tipo) => tipo == 'Anulacion' ? 'Anulación' : tipo;

  String _formatoFecha(DateTime f) {
    final dia = f.day.toString().padLeft(2, '0');
    final mes = f.month.toString().padLeft(2, '0');
    final hora = f.hour.toString().padLeft(2, '0');
    final minuto = f.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${f.year} $hora:$minuto';
  }
}
