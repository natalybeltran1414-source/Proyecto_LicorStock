import 'package:dio/dio.dart';

import 'api.dart';

class VentasServicio {
  Future<Response<dynamic>> listar([Map<String, dynamic>? params]) =>
      api.get<dynamic>('/ventas/', queryParameters: params ?? {});

  Future<Response<dynamic>> obtener(int id) => api.get<dynamic>('/ventas/$id/');

  Future<Response<dynamic>> crear(Map<String, dynamic> data) =>
      api.post<dynamic>('/ventas/', data: data);

  Future<Response<dynamic>> anular(int id) =>
      api.post<dynamic>('/ventas/$id/anular/');

  Future<Response<dynamic>> resumen() => api.get<dynamic>('/ventas/resumen/');

  Future<Response<dynamic>> semanal() => api.get<dynamic>('/ventas/semanal/');

  Future<Response<dynamic>> topProductos([Map<String, dynamic>? params]) =>
      api.get<dynamic>('/ventas/top_productos/', queryParameters: params ?? {});
}

class DeudasServicio {
  Future<Response<dynamic>> listar([Map<String, dynamic>? params]) =>
      api.get<dynamic>('/deudas/', queryParameters: params ?? {});

  Future<Response<dynamic>> abonar(int id, Map<String, dynamic> data) =>
      api.post<dynamic>('/deudas/$id/abonar/', data: data);

  Future<Response<dynamic>> resumen() => api.get<dynamic>('/deudas/resumen/');
}

final ventasService = VentasServicio();
final deudasService = DeudasServicio();