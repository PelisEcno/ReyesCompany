import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<void> guardarArchivo(List<int> bytes, String nombre, String tipoMime) async {
  final datos = Uint8List.fromList(bytes);
  final blob = web.Blob([datos.toJS].toJS, web.BlobPropertyBag(type: tipoMime));
  final direccion = web.URL.createObjectURL(blob);
  final enlace = web.document.createElement('a') as web.HTMLAnchorElement;
  enlace.href = direccion;
  enlace.download = nombre;
  enlace.click();
  web.URL.revokeObjectURL(direccion);
}
