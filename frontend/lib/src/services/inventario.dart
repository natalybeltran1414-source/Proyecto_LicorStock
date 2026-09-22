import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import 'api.dart';

class ProductosServicio {
  Future<Response<dynamic>> listar([Map<String, dynamic>? params]) =>
      api.get<dynamic>('/productos/', queryParameters: params ?? {});

  Future<Response<dynamic>> obtener(int id) => api.get<dynamic>('/productos/$id/');

  Future<Response<dynamic>> crear(Map<String, dynamic> data) =>
      api.post<dynamic>('/productos/', data: data);

  Future<Response<dynamic>> actualizar(int id, Map<String, dynamic> data) =>
      api.patch<dynamic>('/productos/$id/', data: data);

  Future<Response<dynamic>> eliminar(int id) =>
      api.delete<dynamic>('/productos/$id/');

  Future<Response<dynamic>> bajoStock() =>
      api.get<dynamic>('/productos/bajo_stock/');

  Future<Response<dynamic>> resumen() => api.get<dynamic>('/productos/resumen/');

  Future<Response<dynamic>> subirImagen(int id, XFile archivo) async {
    final bytes = await archivo.readAsBytes();
    var tipo = 'image/jpeg';
    if (archivo.name.toLowerCase().endsWith('.png')) tipo = 'image/png';
    if (archivo.name.toLowerCase().endsWith('.webp')) tipo = 'image/webp';
    if ((archivo.mimeType ?? '').isNotEmpty) tipo = archivo.mimeType!;
    final partes = tipo.split('/');
    final form = FormData.fromMap({
      'imagen': MultipartFile.fromBytes(
        bytes,
        filename: 'p${id}_${DateTime.now().millisecondsSinceEpoch}.${tipo.split('/').last}',
        contentType: MediaType(partes.first.isEmpty ? 'image' : partes.first, partes.last),
      ),
    });
    return api.post<dynamic>('/productos/$id/imagen/', data: form);
  }

  Future<Response<dynamic>> quitarImagen(int id) =>
      api.delete<dynamic>('/productos/$id/imagen/');
}

class CategoriasServicio {
  Future<Response<dynamic>> listar() => api.get<dynamic>('/categorias/');

  Future<Response<dynamic>> crear(Map<String, dynamic> data) =>
      api.post<dynamic>('/categorias/', data: data);

  Future<Response<dynamic>> actualizar(int id, Map<String, dynamic> data) =>
      api.patch<dynamic>('/categorias/$id/', data: data);

  Future<Response<dynamic>> eliminar(int id) =>
      api.delete<dynamic>('/categorias/$id/');
}

class MovimientosServicio {
  Future<Response<dynamic>> listar([Map<String, dynamic>? params]) =>
      api.get<dynamic>('/movimientos/', queryParameters: params ?? {});

  Future<Response<dynamic>> ajustar(Map<String, dynamic> data) =>
      api.post<dynamic>('/movimientos/ajustar/', data: data);
}

final productosService = ProductosServicio();
final categoriasService = CategoriasServicio();
final movimientosService = MovimientosServicio();