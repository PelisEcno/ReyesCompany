import 'package:flutter/material.dart';

Future<void> mostrarExportacion(
  BuildContext context, {
  required String titulo,
  required String descripcion,
  required void Function(String formato) alElegir,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (hoja) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        Text(descripcion, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 20),
        _opcion(
          icono: Icons.picture_as_pdf_rounded,
          color: const Color(0xFFDC2626),
          titulo: 'PDF',
          subtitulo: 'Documento listo para imprimir o compartir',
          alTocar: () { Navigator.pop(hoja); alElegir('PDF'); },
        ),
        const SizedBox(height: 12),
        _opcion(
          icono: Icons.table_chart_rounded,
          color: const Color(0xFF059669),
          titulo: 'Excel',
          subtitulo: 'Hoja de cálculo editable (.xlsx)',
          alTocar: () { Navigator.pop(hoja); alElegir('Excel'); },
        ),
      ]),
    ),
  );
}

Widget _opcion({
  required IconData icono,
  required Color color,
  required String titulo,
  required String subtitulo,
  required VoidCallback alTocar,
}) =>
    GestureDetector(
      onTap: alTocar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icono, color: color, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 14)),
            Text(subtitulo, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ])),
          Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ]),
      ),
    );
