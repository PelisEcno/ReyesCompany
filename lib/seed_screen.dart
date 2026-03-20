// ══════════════════════════════════════════════════════
//  seed_screen.dart — Inicialización Realtime Database
//  Ejecutar UNA sola vez
// ══════════════════════════════════════════════════════
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class SeedScreen extends StatefulWidget {
  const SeedScreen({super.key});
  @override
  State<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<SeedScreen> {
  final _db   = FirebaseDatabase.instance;
  final _auth = FirebaseAuth.instance;
  bool _ejecutando = false;
  final List<String> _logs = [];

  void _log(String msg) => setState(() => _logs.add(msg));

  Future<void> _seed() async {
    setState(() { _ejecutando = true; _logs.clear(); });
    try {

      // ── Sucursales ──────────────────────────────
      _log('Creando sucursales...');
      await _db.ref('sucursales/sucursal_1').set({'nombre': 'Sucursal Principal', 'direccion': '', 'telefono': '', 'estado': true});
      await _db.ref('sucursales/sucursal_2').set({'nombre': 'Sucursal 2', 'direccion': '', 'telefono': '', 'estado': true});
      _log('✅ Sucursales creadas');

      // ── Categorías ──────────────────────────────
      _log('Creando categorías...');
      for (final cat in ['Bebidas', 'Alimentos', 'Aseo', 'Licores', 'Snacks']) {
        await _db.ref('categorias').push().set({'nombre': cat});
      }
      _log('✅ Categorías creadas');

      // ── Métodos de pago ─────────────────────────
      _log('Creando métodos de pago...');
      for (final m in ['Efectivo', 'Nequi', 'Daviplata', 'Fiado']) {
        await _db.ref('metodos_pago').push().set({'nombre': m, 'activo': true});
      }
      _log('✅ Métodos de pago creados');

      // ── Usuario Admin ───────────────────────────
      _log('Creando usuario administrador...');
      try {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: 'admin@reyescompany.com',
          password: 'Admin123456',
        );
        await _db.ref('usuarios/${cred.user!.uid}').set({
          'nombre':      'Administrador',
          'email':       'admin@reyescompany.com',
          'rol':         'Administrador',
          'activo':      true,
          'id_sucursal': null,
          'created_at':  ServerValue.timestamp,
        });
        _log('✅ Admin creado correctamente');
      } catch (e) {
        _log('⚠️ Admin ya existe: $e');
      }

      _log('');
      _log('🎉 ¡Configuración completada!');
      _log('');
      _log('Email:    admin@reyescompany.com');
      _log('Password: Admin123456');

    } catch (e) {
      _log('❌ Error: $e');
    } finally {
      setState(() => _ejecutando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Configuración Inicial'),
        backgroundColor: const Color(0xFF1A5276),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text('Solo ejecutar UNA vez', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700, fontSize: 16)),
              ]),
              const SizedBox(height: 8),
              const Text('Crea en Firebase Realtime Database:\n• 2 sucursales\n• Categorías de productos\n• Métodos de pago\n• Usuario administrador'),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _ejecutando ? null : _seed,
              icon: _ejecutando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.rocket_launch_rounded),
              label: Text(_ejecutando ? 'Configurando...' : 'Inicializar Firebase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A5276), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_logs.isNotEmpty) Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16)),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(_logs[i], style: TextStyle(
                    color: _logs[i].startsWith('✅') ? Colors.greenAccent
                        : _logs[i].startsWith('❌') ? Colors.redAccent
                        : _logs[i].startsWith('⚠️') ? Colors.amberAccent
                        : _logs[i].startsWith('🎉') ? Colors.cyanAccent
                        : Colors.white70,
                    fontSize: 13, fontFamily: 'monospace',
                  )),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}