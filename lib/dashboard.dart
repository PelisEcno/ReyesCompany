import 'package:flutter/material.dart';
import 'modulo_inventario.dart';
import 'modulo_ventas.dart';
import 'modulo_clientes.dart';
import 'modulo_usuarios.dart';

class UsuarioSesion {
  final int idUsuario;
  final String nombre;
  final String rol;

  const UsuarioSesion({
    required this.idUsuario,
    required this.nombre,
    required this.rol,
  });
}

class DashboardScreen extends StatefulWidget {
  final UsuarioSesion usuario;
  const DashboardScreen({super.key, required this.usuario});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _moduloActivo = 0;

  final List<_ModuloItem> _modulos = const [
    _ModuloItem(icono: Icons.dashboard_rounded,       label: 'Inicio'),
    _ModuloItem(icono: Icons.point_of_sale_rounded,   label: 'Ventas'),
    _ModuloItem(icono: Icons.inventory_2_rounded,     label: 'Inventario'),
    _ModuloItem(icono: Icons.people_alt_rounded,      label: 'Clientes'),
    _ModuloItem(icono: Icons.manage_accounts_rounded, label: 'Usuarios'),
  ];

  static const Color kPrimary   = Color(0xFF1A5276);
  static const Color kAccent    = Color(0xFF2E86C1);
  static const Color kBg        = Color(0xFFF0F4F8);
  static const Color kSidebar   = Color(0xFF162E40);

  @override
  Widget build(BuildContext context) {
    final bool esMovil = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: kBg,

      drawer: esMovil ? _buildDrawer() : null,

      appBar: esMovil ? _buildAppBarMovil() : null,

      body: Row(
        children: [
          if (!esMovil) _buildSidebar(),

          Expanded(
            child: Column(
              children: [
                if (!esMovil) _buildTopBar(),

                Expanded(
                  child: _buildContenido(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBarMovil() {
    return AppBar(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        _modulos[_moduloActivo].label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            backgroundColor: kAccent,
            radius: 18,
            child: Text(
              widget.usuario.nombre[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: kSidebar,
      child: _buildSidebarContent(),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: kSidebar,
      child: _buildSidebarContent(),
    );
  }

  Widget _buildSidebarContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ReyesCompany',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Sistema SIV',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(color: Colors.white12, height: 1),
        const SizedBox(height: 12),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _modulos.length,
            itemBuilder: (context, index) {
              final activo = _moduloActivo == index;
              return _buildMenuItem(
                modulo: _modulos[index],
                activo: activo,
                onTap: () {
                  setState(() => _moduloActivo = index);
                  if (MediaQuery.of(context).size.width < 768) {
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),

        const Divider(color: Colors.white12, height: 1),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: kAccent,
                radius: 18,
                child: Text(
                  widget.usuario.nombre[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.usuario.nombre,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.usuario.rol,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded,
                    color: Colors.white54, size: 20),
                tooltip: 'Cerrar sesión',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required _ModuloItem modulo,
    required bool activo,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: activo ? kAccent.withOpacity(0.25) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: activo
            ? Border.all(color: kAccent.withOpacity(0.4), width: 1)
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          modulo.icono,
          color: activo ? Colors.white : Colors.white54,
          size: 20,
        ),
        title: Text(
          modulo.label,
          style: TextStyle(
            color: activo ? Colors.white : Colors.white70,
            fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            _modulos[_moduloActivo].label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A5276),
            ),
          ),
          const Spacer(),
          Text(
            _fechaHoy(),
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            backgroundColor: kAccent,
            radius: 18,
            child: Text(
              widget.usuario.nombre[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.usuario.nombre,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    switch (_moduloActivo) {
      case 0: return const ModuloInicio();
      case 1: return ModuloVentas(idUsuario: widget.usuario.idUsuario);
      case 2: return const ModuloInventario();
      case 3: return const ModuloClientes();
      case 4: return ModuloUsuarios(idUsuarioActual: widget.usuario.idUsuario);
      default: return const ModuloInicio();
    }
  }

  String _fechaHoy() {
    final now = DateTime.now();
    const meses = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${now.day} ${meses[now.month]} ${now.year}';
  }
}

class _ModuloItem {
  final IconData icono;
  final String label;
  const _ModuloItem({required this.icono, required this.label});
}

class ModuloInicio extends StatelessWidget {
  const ModuloInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del día',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A5276)),
          ),
          const SizedBox(height: 20),

          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
              children: const [
                _TarjetaMetrica(
                  titulo: 'Ventas hoy',
                  valor: '\$0',
                  icono: Icons.trending_up_rounded,
                  color: Color(0xFF1ABC9C),
                ),
                _TarjetaMetrica(
                  titulo: 'Productos',
                  valor: '0',
                  icono: Icons.inventory_2_rounded,
                  color: Color(0xFF2E86C1),
                ),
                _TarjetaMetrica(
                  titulo: 'Clientes fiados',
                  valor: '0',
                  icono: Icons.people_alt_rounded,
                  color: Color(0xFFE67E22),
                ),
                _TarjetaMetrica(
                  titulo: 'Stock bajo',
                  valor: '0',
                  icono: Icons.warning_amber_rounded,
                  color: Color(0xFFE74C3C),
                ),
              ],
            );
          }),

          const SizedBox(height: 28),

          const Text(
            'Acciones rápidas',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _BotonAccion(label: 'Nueva venta',    icono: Icons.add_shopping_cart_rounded, color: Color(0xFF1ABC9C)),
              _BotonAccion(label: 'Agregar producto', icono: Icons.add_box_rounded,          color: Color(0xFF2E86C1)),
              _BotonAccion(label: 'Nuevo cliente',  icono: Icons.person_add_rounded,        color: Color(0xFFE67E22)),
              _BotonAccion(label: 'Ver reportes',   icono: Icons.bar_chart_rounded,         color: Color(0xFF8E44AD)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaMetrica extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;
  const _TarjetaMetrica({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(valor,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50))),
                Text(titulo,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final String label;
  final IconData icono;
  final Color color;
  const _BotonAccion({required this.label, required this.icono, required this.color});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icono, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}

class _PlaceholderModulo extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;

  const _PlaceholderModulo({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 56, color: color),
          ),
          const SizedBox(height: 20),
          Text(
            titulo,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 8),
          Text(
            descripcion,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: Colors.grey[500], height: 1.6),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('Desarrollar módulo $titulo'),
          ),
        ],
      ),
    );
  }
}