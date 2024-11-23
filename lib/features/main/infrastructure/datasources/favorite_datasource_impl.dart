import 'dart:io';
import 'package:dio/dio.dart';
import 'package:wayassist/config/config.dart';
import 'package:wayassist/features/main/main.dart';
import 'package:wayassist/features/shared/shared.dart';

class FavoriteDatasourceImpl extends FavoriteDatasource {
  Dio? dio;
  String accessToken = '';
  final KeyValueStorageSericeImpl _keyValueStorage =
      KeyValueStorageSericeImpl();

  Future<void> _initializeDio() async {
    if (dio == null) {
      // Verifica si Dio no ha sido inicializado previamente
      accessToken = await _getToken();
      dio = Dio(BaseOptions(
        baseUrl: Enviroment.apiUrl,
        headers: {'Authorization': 'Bearer $accessToken'},
      ));
    }
  }

  Future<String> _getToken() async {
    final token = await _keyValueStorage.getValue<String>('token');
    return token ?? '';
  }

  @override
  Future<Favorite> createFavorite(
      String name, double longitude, double latitude, String address) async {
    await _initializeDio();
    try {
      final response = await dio!.post('/favorite', data: {
        'name': name,
        'longitude': longitude,
        'latitude': latitude,
        'address': address,
      });
      return FavoriteMapper.favoriteJsonToEntity(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw CustomFavoriteError('Error inesperado: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteFavorite(String id) async {
    await _initializeDio();
    try {
      await dio!.delete('/favorite/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw CustomFavoriteError('Error inesperado: ${e.toString()}');
    }
  }

  @override
  Future<List<Favorite>> getFavorites() async {
    await _initializeDio();
    try {
      final response = await dio!.get('/favorite');
      return (response.data as List)
          .map((e) => FavoriteMapper.favoriteJsonToEntity(e))
          .toList();
    } on DioException catch (e) {
      print(e);
      throw _handleDioError(e);
    } catch (e) {
      print('Error: $e');
      throw CustomFavoriteError('Error inesperado: ${e.toString()}');
    }
  }

  @override
  Future<Favorite> getFavorite(String id) async {
    await _initializeDio();
    try {
      final response = await dio!.get('/favorite/$id');
      return FavoriteMapper.favoriteJsonToEntity(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw CustomFavoriteError('Error inesperado: ${e.toString()}');
    }
  }

  @override
  Future<Favorite> updateFavorite(String id, String name, double longitude,
      double latitude, String address, String description) async {
    await _initializeDio();
    try {
      final response = await dio!.patch('/favorite/$id', data: {
        'name': name,
        'longitude': longitude,
        'latitude': latitude,
        'address': address,
      });
      return FavoriteMapper.favoriteJsonToEntity(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw CustomFavoriteError('Error inesperado: ${e.toString()}');
    }
  }

  CustomFavoriteError _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return CustomFavoriteError(
          e.response?.data['message'] ?? 'Tiempo de espera agotado');
    }

    if (e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return CustomFavoriteError(
          'Verifica tu conexión a internet y vuelve a intentarlo o inténtalo más tarde.');
    }

    if (e.type == DioExceptionType.cancel) {
      return CustomFavoriteError('Solicitud cancelada');
    }

    final statusCode = e.response?.statusCode;
    if (statusCode != null) {
      if (statusCode >= 400 && statusCode < 500) {
        return CustomFavoriteError(
            e.response?.data['message'] ?? 'Error del cliente');
      } else if (statusCode >= 500 && statusCode < 600) {
        return CustomFavoriteError(
            e.response?.data['message'] ?? 'Error del servidor');
      }
    }

    if (e.type == DioExceptionType.unknown) {
      if (e.error is FormatException) {
        return CustomFavoriteError('Error en el formato de la respuesta');
      }
      if (e.error != null && e.error is SocketException) {
        return CustomFavoriteError(
            'No se pudo establecer una conexión con el servidor. Verifica tu conexión a internet.');
      }
      return CustomFavoriteError('Error de conexión a la red: ${e.error}');
    }

    return CustomFavoriteError('Error desconocido: ${e.message}');
  }
}
