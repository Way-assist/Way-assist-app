import 'dart:async';
import 'package:dio/dio.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shared_data_map_provider.g.dart';

class SharedDataState {
  final String? latitude;
  final String? longitude;
  final String? address;
  final bool isLoading;
  final String? errorMessage;

  SharedDataState({
    this.latitude,
    this.longitude,
    this.address,
    this.isLoading = false,
    this.errorMessage,
  });

  SharedDataState copyWith({
    String? latitude,
    String? longitude,
    String? address,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SharedDataState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory SharedDataState.initial() {
    return SharedDataState(
      latitude: null,
      longitude: null,
      address: null,
      isLoading: false,
      errorMessage: null,
    );
  }
}

@riverpod
class SharedData extends _$SharedData {
  final Dio _dio = Dio();
  StreamSubscription? _intentDataStreamSubscription;

  @override
  SharedDataState build() {
    _initializeIntentListener();
    return SharedDataState.initial();
  }

  void _initializeIntentListener() {
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedData(value);
      }
    }).catchError((err) {
      state = state.copyWith(
          errorMessage: "Error al obtener la intención inicial: $err");
    });

    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedData(value);
      }
    }, onError: (err) {
      state = state.copyWith(errorMessage: "Error: $err");
    });
  }

  Future<void> _handleSharedData(List<SharedMediaFile> sharedFiles) async {
    for (var file in sharedFiles) {
      if (file.path.contains("maps.app.goo.gl")) {
        try {
          state = state.copyWith(isLoading: true);
          final expandedUrl = await _expandShortUrl(file.path);
          final coordinates = _extractCoordinates(expandedUrl);
          if (coordinates != null) {
            state = state.copyWith(
              latitude: coordinates.latitude,
              longitude: coordinates.longitude,
              address: coordinates.address,
              isLoading: false,
            );
          } else {
            state = state.copyWith(
                isLoading: false,
                errorMessage:
                    "No se encontraron coordenadas en la URL expandida");
          }
        } catch (e) {
          state = state.copyWith(
              isLoading: false,
              errorMessage: "Error al procesar el enlace: $e");
        }
      }
    }
  }

  Future<String> _expandShortUrl(String shortUrl) async {
    final response =
        await _dio.get(shortUrl, options: Options(followRedirects: true));
    return response.realUri.toString();
  }

  SharedDataState _extractCoordinates(String url) {
    final uri = Uri.parse(url);
    String? address;
    if (uri.pathSegments.isNotEmpty) {
      address = uri.pathSegments.first.replaceAll('+', ' ');
    }
    final regex = RegExp(r'!3d([-.\d]+)!4d([-.\d]+)');
    final match = regex.firstMatch(uri.toString());
    if (match != null) {
      final latitude = match.group(1);
      final longitude = match.group(2);
      if (latitude != null && longitude != null) {
        return state.copyWith(
            latitude: latitude, longitude: longitude, address: address ?? '');
      }
    }
    if (uri.queryParameters.containsKey('q')) {
      final latLng = uri.queryParameters['q']?.split(',');
      if (latLng != null && latLng.length == 2) {
        return state.copyWith(
            latitude: latLng[0], longitude: latLng[1], address: address ?? '');
      }
    }
    return state.copyWith(errorMessage: "No se pudieron extraer coordenadas");
  }

  clearState() {
    state = SharedDataState.initial();
  }
}
