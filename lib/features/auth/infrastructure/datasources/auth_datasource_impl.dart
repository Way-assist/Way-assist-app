import 'dart:async';
import 'dart:io';

import 'package:wayassist/config/config.dart';
import 'package:wayassist/features/auth/auth.dart';
import 'package:dio/dio.dart';

class AuthDatasourceImpl extends AuthDataSouce {
  final dio = Dio(BaseOptions(
    baseUrl: Enviroment.apiUrl,
  ));

  @override
  Future<User> checkAuthStatus(String token) async {
    try {
      final response = await dio.get('/auth/check',
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      final user = UserMapper.userJsonToEntity(response.data);
      return user;
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      throw Exception();
    }
    throw Exception('Error inesperado en la autenticación');
  }

  @override
  Future<User> loginGoogle(String googleToken) async {
    try {
      final response = await dio.post('/auth/google/mobile', data: {
        'token': googleToken,
      });
      final user = UserMapper.userJsonToEntity(response.data);
      return user;
    } on DioException catch (e) {
      print(e);
      _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado: ${e.toString()}');
    }
    throw Exception('Error inesperado en la autenticación de Google');
  }
}

void _handleDioError(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout) {
    throw CustomError(
        e.response?.data['message'] ?? 'Tiempo de espera agotado');
  }

  if (e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError) {
    throw CustomError('Verifica tu conexión a internet y vuelve a intentarlo o '
        'inténtalo más tarde.');
  }

  if (e.type == DioExceptionType.cancel) {
    throw CustomError('Solicitud cancelada');
  }

  final statusCode = e.response?.statusCode;
  if (statusCode != null) {
    if (statusCode >= 400 && statusCode < 500) {
      throw CustomError(e.response?.data['message'] ?? 'Error del cliente');
    } else if (statusCode >= 500 && statusCode < 600) {
      throw CustomError(e.response?.data['message'] ?? 'Error del servidor');
    }
  }

  if (e.type == DioExceptionType.unknown) {
    if (e.error is FormatException) {
      throw CustomError('Error en el formato de la respuesta');
    }
    if (e.error != null && e.error is SocketException) {
      throw CustomError(
          'No se pudo establecer una conexión con el servidor. Verifica tu conexión a internet.');
    }
    throw CustomError('Error de conexión a la red: ${e.error}');
  }

  throw Exception('Error desconocido: ${e.message}');
}
