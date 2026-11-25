import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> guardarArchivo(List<int> bytes, String nombre, String tipoMime) async {
  final carpeta = await getTemporaryDirectory();
  final archivo = File('${carpeta.path}/$nombre');
  await archivo.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(archivo.path, mimeType: tipoMime)], subject: nombre);
}
