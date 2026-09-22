import 'package:dio/dio.dart';

import 'api.dart';

class ClientesServicio {
  Future<Response<dynamic>> listar([Map<String, dynamic>? params]) =>
      api.get<dynamic>('/clientes/', queryParameters: params ?? {});

  Future<Response<dynamic>> obtener(int id) => api.get<dynamic>('/clientes/$id/');

  Future<Response<dynamic>> crear(Map<String, dynamic> data) =>
      api.post<dynamic>('/clientes/', data: data);

  Future<Response<dynamic>> actualizar(int id, Map<String, dynamic> data) =>
      api.patch<dynamic>('/clientes/$id/', data: data);

  Future<Response<dynamic>> eliminar(int id) =>
      api.delete<dynamic>('/clientes/$id/');

  Future<Response<dynamic>> toggleEstado(int id) =>
      api.post<dynamic>('/clientes/$id/toggle_estado/');
}

final clientesService = ClientesServicio();