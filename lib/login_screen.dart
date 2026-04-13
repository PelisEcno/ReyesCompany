import 'package:flutter/material.dart';
import 'database_service.dart';
import 'dashboard.dart';

// Pantalla para que los usuarios entren al sistema
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  final _svc       = DatabaseService();

  bool _verPass  = false;
  bool _cargando = false;

  late AnimationController _animCtrl;
  late Animation<Offset>   _slide;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    // Configuracion de las animaciones de entrada
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fade  = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _animCtrl.forward();
  }

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); _animCtrl.dispose(); super.dispose(); }

  // Funcion para validar los datos y entrar al dashboard
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      final data = await _svc.login(_emailCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      if (data == null) { _error('Usuario no encontrado'); return; }

      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => DashboardScreen(
          usuario: UsuarioSesion(
            idUsuario:      data['id_usuario'],
            nombre:         data['nombre'],
            rol:            data['rol'],
            idSucursal:     data['id_sucursal'],
            sucursalNombre: data['sucursal_nombre'] ?? '',
          ),
        ),
      ));
    } catch (e) {
      if (mounted) _error(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _error(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: Colors.redAccent,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(16),
  ));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(children: [
        // Fondo con color azul
        Container(height: size.height * 0.42,
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF1A5276), Color(0xFF2E86C1)]),
          ),
        ),
        SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const SizedBox(height: 48),
            // Logo y bienvenida
            FadeTransition(opacity: _fade, child: Column(children: [
              Container(width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                child: const Icon(Icons.storefront_rounded, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 14),
              const Text('ReyesCompany', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Text('Bienvenido de vuelta', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14)),
            ])),
            const SizedBox(height: 36),
            // Cuadro del login
            Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SlideTransition(position: _slide, child: FadeTransition(opacity: _fade,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Iniciar sesión', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A5276))),
                    const SizedBox(height: 6),
                    Text('Ingresa tu email y contraseña', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                    const SizedBox(height: 28),
                    _label('Email'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _deco('tu@email.com', Icons.email_outlined),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'El email es obligatorio' : null,
                    ),
                    const SizedBox(height: 20),
                    _label('Contraseña'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: !_verPass,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: _deco('••••••••', Icons.lock_outline_rounded, suffix: IconButton(
                        icon: Icon(_verPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey[400], size: 20),
                        onPressed: () => setState(() => _verPass = !_verPass),
                      )),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'La contraseña es obligatoria';
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // Boton para entrar
                    SizedBox(width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: _cargando ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A5276), foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
                        ),
                        child: _cargando
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Ingresar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ])),
                ),
              )),
            )),
            const SizedBox(height: 20),
          ]),
        )),
      ]),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)));

  // Estilo de los campos de texto
  InputDecoration _deco(String hint, IconData icon, {Widget? suffix}) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
    prefixIcon: Icon(icon, color: const Color(0xFF2E86C1), size: 20), suffixIcon: suffix,
    filled: true, fillColor: const Color(0xFFF4F6F8),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!, width: 1)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E86C1), width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
  );
}
