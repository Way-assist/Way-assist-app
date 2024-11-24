import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:wayassist/config/constant/enviroment.dart';
import 'package:wayassist/config/router/app_router.dart';
import 'package:wayassist/features/main/presentation/providers/bluetooth_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:location/location.dart';
import 'package:google_maps_routes/google_maps_routes.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mtk;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_provider.g.dart';

class NavigationState {
  final bool isLoading;
  final bool isNavigationMode;
  final bool isFollowingUser;
  final String navigationInstruction;
  final double distanceToDestination;
  final Set<Marker> markers;
  final Set<Polygon> polygons;
  final Polyline? currentRoute;
  final geo.Position? currentPosition;
  final LatLng destinationPosition;
  final String destinationName;
  final String lastInstruction;
  final bool isMapInitialized;
  final List<Map<String, dynamic>> navigationSteps;
  final int currentStepIndex;
  final bool isRecalculating;

  NavigationState({
    this.isLoading = true,
    this.isNavigationMode = false,
    this.isFollowingUser = false,
    this.navigationInstruction = '',
    this.distanceToDestination = 0.0,
    this.markers = const {},
    this.polygons = const {},
    this.currentRoute,
    this.currentPosition,
    required this.destinationPosition,
    required this.destinationName,
    this.lastInstruction = '',
    this.isMapInitialized = false,
    this.navigationSteps = const [],
    this.currentStepIndex = 0,
    this.isRecalculating = false,
  });

  NavigationState copyWith({
    bool? isLoading,
    bool? isNavigationMode,
    bool? isFollowingUser,
    String? navigationInstruction,
    double? distanceToDestination,
    Set<Marker>? markers,
    Set<Polygon>? polygons,
    Polyline? currentRoute,
    geo.Position? currentPosition,
    LatLng? destinationPosition,
    String? destinationName,
    String? lastInstruction,
    bool? isMapInitialized,
    List<Map<String, dynamic>>? navigationSteps,
    int? currentStepIndex,
    bool? isRecalculating,
  }) {
    return NavigationState(
      isLoading: isLoading ?? this.isLoading,
      isNavigationMode: isNavigationMode ?? this.isNavigationMode,
      isMapInitialized: isMapInitialized ?? this.isMapInitialized,
      isFollowingUser: isFollowingUser ?? this.isFollowingUser,
      navigationInstruction:
          navigationInstruction ?? this.navigationInstruction,
      distanceToDestination:
          distanceToDestination ?? this.distanceToDestination,
      markers: markers ?? this.markers,
      polygons: polygons ?? this.polygons,
      currentRoute: currentRoute ?? this.currentRoute,
      currentPosition: currentPosition ?? this.currentPosition,
      destinationPosition: destinationPosition ?? this.destinationPosition,
      destinationName: destinationName ?? this.destinationName,
      lastInstruction: lastInstruction ?? this.lastInstruction,
      navigationSteps: navigationSteps ?? this.navigationSteps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isRecalculating: isRecalculating ?? this.isRecalculating,
    );
  }
}

@Riverpod(keepAlive: true)
class Navigation extends _$Navigation {
  GoogleMapController? _mapController;
  late Location _location;
  late MapsRoutes _route;
  late FlutterTts _flutterTts;
  StreamSubscription<LocationData>? _locationSubscription;
  Timer? _navigationTimer;
  String googleApiKey = Enviroment.googleMapsKey;
  late final Dio _dio;

  @override
  NavigationState build(LatLng originPosition, LatLng destinationPosition,
      String destinationName) {
    _location = Location();
    _route = MapsRoutes();
    _flutterTts = FlutterTts();

    final initialState = NavigationState(
      destinationPosition: destinationPosition,
      destinationName: destinationName,
      currentPosition: geo.Position(
        latitude: originPosition.latitude,
        longitude: originPosition.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ),
    );

    _initializeServices();
    return initialState;
  }

  Future<void> _initializeServices() async {
    await _initTTS();
    _addDestinationMarker();
    _dio = Dio();

    await _initializeLocation();
    getNewRouteFromAPI();
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("es-ES");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    state = state.copyWith(isMapInitialized: true);
    _startLocationUpdates();
    if (state.currentRoute != null) {
      _showCurrentRoute();
    }
  }

  Future<void> _animateCamera(CameraUpdate cameraUpdate) async {
    if (_mapController == null || !state.isMapInitialized) return;

    try {
      await _mapController!.animateCamera(cameraUpdate);
    } catch (e) {
      print('Error al animar cámara: $e');
    }
  }

  void _addDestinationMarker() {
    final markers = Set<Marker>();
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: state.destinationPosition,
        infoWindow: InfoWindow(
          title: state.destinationName,
          snippet: 'Destino',
        ),
      ),
    );
    state = state.copyWith(markers: markers);
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Servicios de ubicación deshabilitados');
      }

      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        throw Exception('Permisos de ubicación denegados permanentemente');
      }

      await _setInitialLocation();
    } catch (e) {
      print('Error en la inicialización de la ubicación: $e');
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _setInitialLocation() async {
    try {
      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );
      state = state.copyWith(currentPosition: position);
    } catch (e) {
      print('Error al establecer la ubicación inicial: $e');
      rethrow;
    }
  }

  void startNavigation() {
    state = state.copyWith(
      isNavigationMode: true,
      isFollowingUser: true,
    );
    toggleFollowUser();
    if (state.currentPosition != null) {
      _updateCameraPosition();
    }
    _navigationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      updateNavigationInfo();
    });

    if (state.navigationSteps.isNotEmpty) {
      final firstStep = state.navigationSteps[0];
      final firstInstruction =
          "${firstStep['instruction']} a ${firstStep['distance']}";
      state = state.copyWith(
        navigationInstruction: firstInstruction,
        lastInstruction: firstInstruction,
      );
      _flutterTts.speak("Iniciando navegación");
      _flutterTts.speak(state.navigationInstruction);
    } else {
      _flutterTts.speak("Iniciando navegación hacia ${state.destinationName}");
    }

    getNewRouteFromAPI();
  }

  void stopNavigation() {
    state = state.copyWith(
      isNavigationMode: false,
      isFollowingUser: false,
      navigationInstruction: '',
      lastInstruction: '',
    );
    _navigationTimer?.cancel();
    _flutterTts.stop();
  }

  void toggleFollowUser() {
    final newFollowingState = !state.isFollowingUser;
    state = state.copyWith(isFollowingUser: newFollowingState);
    if (newFollowingState) {
      _updateCameraPosition();
    }
  }

  void _updateCameraPosition() {
    if (state.currentPosition == null || !state.isMapInitialized) return;

    double currentHeading = state.currentPosition!.heading;

    if (currentHeading == 0 && state.currentPosition!.speed > 0.5) {
      if (state.navigationSteps.isNotEmpty &&
          state.currentStepIndex < state.navigationSteps.length) {
        final nextStep = state.navigationSteps[state.currentStepIndex];
        final nextLocation = nextStep['end_location'] as LatLng;

        currentHeading = geo.Geolocator.bearingBetween(
          state.currentPosition!.latitude,
          state.currentPosition!.longitude,
          nextLocation.latitude,
          nextLocation.longitude,
        );
      }
    }

    final CameraPosition newPosition = CameraPosition(
      target: LatLng(
        state.currentPosition!.latitude,
        state.currentPosition!.longitude,
      ),
      zoom: 19.0,
      tilt: 45.0,
      bearing: currentHeading,
    );

    try {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(newPosition),
      );
    } catch (e) {
      print('Error al actualizar la posición de la cámara: $e');
    }
  }

  Future<void> _showCurrentRoute() async {
    if (!state.isMapInitialized || state.currentPosition == null) return;

    try {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          min(state.currentPosition!.latitude,
              state.destinationPosition.latitude),
          min(state.currentPosition!.longitude,
              state.destinationPosition.longitude),
        ),
        northeast: LatLng(
          max(state.currentPosition!.latitude,
              state.destinationPosition.latitude),
          max(state.currentPosition!.longitude,
              state.destinationPosition.longitude),
        ),
      );

      await _animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
    } catch (e) {
      print('Error al mostrar la ruta: $e');
    }
  }

  Future<void> getNewRouteFromAPI() async {
    if (state.currentPosition == null || state.isRecalculating) return;

    try {
      state = state.copyWith(isLoading: true, isRecalculating: true);

      final response = await _dio.get(
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${state.currentPosition!.latitude},${state.currentPosition!.longitude}'
          '&destination=${state.destinationPosition.latitude},${state.destinationPosition.longitude}'
          '&mode=walking'
          '&language=es'
          '&units=metric'
          '&alternatives=false'
          '&avoid=highways|ferries|indoor'
          '&optimize=true'
          '&key=$googleApiKey');

      if (response.statusCode == 200) {
        final data = response.data;
        print(data);
        if (data['status'] == 'OK') {
          final List<Map<String, dynamic>> steps = [];
          final route = data['routes'][0]['legs'][0];
          final duration = route['duration']['text'];
          final totalDistance = route['distance']['text'];

          print('Duración total: $duration');
          print('Distancia total: $totalDistance');
          state = state.copyWith(
            distanceToDestination: route['distance']['value'].toDouble(),
          );

          for (var step in route['steps']) {
            String instruction = step['html_instructions']
                .toString()
                .replaceAll(RegExp(r'<[^>]*>'), ' ')
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();

            steps.add({
              'instruction': instruction,
              'distance': step['distance']['text'],
              'duration': step['duration']['text'],
              'maneuver': step['maneuver'] ?? '',
              'start_location': LatLng(
                step['start_location']['lat'].toDouble(),
                step['start_location']['lng'].toDouble(),
              ),
              'end_location': LatLng(
                step['end_location']['lat'].toDouble(),
                step['end_location']['lng'].toDouble(),
              ),
            });

            print('Paso: $instruction - ${step['distance']['text']}');
          }
          final newPoints =
              _decodePolyline(data['routes'][0]['overview_polyline']['points']);

          final newRoute = Polyline(
            polylineId: const PolylineId('route'),
            points: newPoints,
            color: Colors.blue,
            width: 5,
          );
          state = state.copyWith(
            navigationSteps: steps,
            currentStepIndex: 0,
            currentRoute: newRoute,
            isRecalculating: false,
          );
          if (state.isMapInitialized && _mapController != null) {
            await _updateMapView(newPoints);
          }
        }
      }
    } catch (e) {
      print('Error detallado al obtener la ruta: $e');
      if (e is DioError) {
        print('DioError: ${e.response?.data}');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> _updateMapView(List<LatLng> points) async {
    try {
      if (points.isEmpty) return;

      //  bounds de la ruta
      double minLat = points[0].latitude;
      double maxLat = points[0].latitude;
      double minLng = points[0].longitude;
      double maxLng = points[0].longitude;

      for (var point in points) {
        minLat = min(minLat, point.latitude);
        maxLat = max(maxLat, point.latitude);
        minLng = min(minLng, point.longitude);
        maxLng = max(maxLng, point.longitude);
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    } catch (e) {
      print('Error al actualizar vista del mapa: $e');
    }
  }

  void _startLocationUpdates() {
    _locationSubscription?.cancel();

    _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 2000,
      distanceFilter: 4.5,
    );

    List<LocationData> locationBuffer = [];
    final int bufferSize = 5;

    _locationSubscription =
        _location.onLocationChanged.listen((LocationData locationData) {
      if (locationData.latitude == null || locationData.longitude == null)
        return;

      if (locationData.accuracy == null || locationData.accuracy! > 15) {
        print('Precisión insuficiente: ${locationData.accuracy} metros');
        return;
      }

      locationBuffer.add(locationData);
      if (locationBuffer.length > bufferSize) {
        locationBuffer.removeAt(0);
      }

      if (locationBuffer.length >= bufferSize) {
        bool isActuallyMoving = _isActuallyMoving(locationBuffer);

        if (!isActuallyMoving) {
          if (state.currentPosition != null) {
            return;
          }
        }

        // Calcular la mediana de las posiciones
        final sortedLats = locationBuffer.map((e) => e.latitude!).toList()
          ..sort();
        final sortedLngs = locationBuffer.map((e) => e.longitude!).toList()
          ..sort();
        final medianLat = sortedLats[bufferSize ~/ 2];
        final medianLng = sortedLngs[bufferSize ~/ 2];

        if (state.currentPosition != null) {
          final distance = geo.Geolocator.distanceBetween(
            state.currentPosition!.latitude,
            state.currentPosition!.longitude,
            medianLat,
            medianLng,
          );

          if (distance < 4.5) return;
        }

        final newPosition = geo.Position(
          latitude: medianLat,
          longitude: medianLng,
          timestamp: DateTime.now(),
          accuracy: locationData.accuracy ?? 0,
          altitude: locationData.altitude ?? 0,
          heading: isActuallyMoving
              ? _calculateSmoothedHeading(locationBuffer)
              : state.currentPosition?.heading ?? 0,
          speed: isActuallyMoving ? _calculateSmoothedSpeed(locationBuffer) : 0,
          speedAccuracy: locationData.speedAccuracy ?? 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );

        state = state.copyWith(
          currentPosition: newPosition,
          isFollowingUser:
              state.isNavigationMode ? true : state.isFollowingUser,
        );

        if (state.currentRoute != null && isActuallyMoving) {
          navigationProcess();
        }

        if (state.isFollowingUser) {
          _updateCameraPosition();
        }
      }
    });
  }

  bool _isActuallyMoving(List<LocationData> buffer) {
    if (buffer.isEmpty) return false;

    bool hasSignificantSpeed = buffer
        .any((location) => location.speed != null && location.speed! > 0.5);

    if (!hasSignificantSpeed) return false;

    double totalDistance = 0;
    for (int i = 1; i < buffer.length; i++) {
      totalDistance += geo.Geolocator.distanceBetween(
        buffer[i - 1].latitude!,
        buffer[i - 1].longitude!,
        buffer[i].latitude!,
        buffer[i].longitude!,
      );
    }

    return totalDistance > 3;
  }

  double _calculateSmoothedHeading(List<LocationData> buffer) {
    final validHeadings = buffer
        .where((location) => location.heading != null && location.speed! > 0.5)
        .map((location) => location.heading!)
        .toList();

    if (validHeadings.isEmpty) return 0;

    double sinSum = 0;
    double cosSum = 0;
    for (double heading in validHeadings) {
      final radians = heading * (pi / 180);
      sinSum += sin(radians);
      cosSum += cos(radians);
    }

    final averageHeading = atan2(sinSum, cosSum) * (180 / pi);
    return averageHeading < 0 ? averageHeading + 360 : averageHeading;
  }

  double _calculateSmoothedSpeed(List<LocationData> buffer) {
    final validSpeeds = buffer
        .where((location) => location.speed != null && location.speed! > 0.3)
        .map((location) => location.speed!)
        .toList();

    if (validSpeeds.isEmpty) return 0;

    // Eliminar valores atípicos
    validSpeeds.sort();
    if (validSpeeds.length >= 3) {
      final q1Index = (validSpeeds.length * 0.25).floor();
      final q3Index = (validSpeeds.length * 0.75).floor();
      final iqr = validSpeeds[q3Index] - validSpeeds[q1Index];
      final lowerBound = validSpeeds[q1Index] - 1.5 * iqr;
      final upperBound = validSpeeds[q3Index] + 1.5 * iqr;

      final filteredSpeeds = validSpeeds
          .where((speed) => speed >= lowerBound && speed <= upperBound)
          .toList();

      if (filteredSpeeds.isNotEmpty) {
        double avgSpeed =
            filteredSpeeds.reduce((a, b) => a + b) / filteredSpeeds.length;
        return avgSpeed < 0.3 ? 0 : avgSpeed;
      }
    }

    return 0;
  }

  //!cambio de codigo
  bool _hasSignificantMovement(
    geo.Position currentPosition,
    double newLat,
    double newLng,
  ) {
    // Aumentar el umbral de distancia mínima
    const double minDistance = 3.0;

    final distance = geo.Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      newLat,
      newLng,
    );

    if (currentPosition.speed > 0) {
      final timeDiff =
          DateTime.now().difference(currentPosition.timestamp).inSeconds;
      if (timeDiff > 0) {
        final theoreticalSpeed = distance / timeDiff;

        if (theoreticalSpeed > currentPosition.speed * 2) {
          return false;
        }
      }
    }

    return distance >= minDistance;
  }

  void updateNavigationInfo() {
    if (state.currentPosition == null ||
        state.currentRoute == null ||
        state.navigationSteps.isEmpty) return;

    final currentPos = LatLng(
      state.currentPosition!.latitude,
      state.currentPosition!.longitude,
    );

    final currentStep = state.navigationSteps[state.currentStepIndex];
    final hasNextStep =
        state.currentStepIndex < state.navigationSteps.length - 1;
    final nextStep =
        hasNextStep ? state.navigationSteps[state.currentStepIndex + 1] : null;

    if (hasNextStep) {
      final nextStepLocation = nextStep!['start_location'] as LatLng;
      final distanceToNextStep = geo.Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        nextStepLocation.latitude,
        nextStepLocation.longitude,
      );

      final bearing = geo.Geolocator.bearingBetween(
        currentPos.latitude,
        currentPos.longitude,
        nextStepLocation.latitude,
        nextStepLocation.longitude,
      );

      final relativeDirection = _getRelativeDirection(
        state.currentPosition!.heading,
        bearing,
      );

      if (distanceToNextStep > 100) {
        String intermediateInstruction = _generateIntermediateInstruction(
          distanceToNextStep,
          nextStep,
          relativeDirection,
        );

        if (intermediateInstruction != state.lastInstruction &&
            _shouldUpdateInstruction(
                state.lastInstruction, intermediateInstruction)) {
          _flutterTts.speak(intermediateInstruction);
          state = state.copyWith(lastInstruction: intermediateInstruction);
        }
      } else if (distanceToNextStep < 30) {
        String immediateInstruction = _generateImmediateInstruction(
          nextStep,
          relativeDirection,
        );

        if (immediateInstruction != state.lastInstruction) {
          _flutterTts.speak(immediateInstruction);
          state = state.copyWith(
            lastInstruction: immediateInstruction,
            currentStepIndex: state.currentStepIndex + 1,
          );
        }
      }
    }

    final distanceToDestination = geo.Geolocator.distanceBetween(
      currentPos.latitude,
      currentPos.longitude,
      state.destinationPosition.latitude,
      state.destinationPosition.longitude,
    );
  }

  String _getRelativeDirection(double deviceHeading, double targetBearing) {
    double relativeBearing = (targetBearing - deviceHeading + 360) % 360;

    if (relativeBearing >= 337.5 || relativeBearing < 22.5) {
      return "al frente";
    } else if (relativeBearing >= 22.5 && relativeBearing < 67.5) {
      return "a la derecha al frente";
    } else if (relativeBearing >= 67.5 && relativeBearing < 112.5) {
      return "a la derecha";
    } else if (relativeBearing >= 112.5 && relativeBearing < 157.5) {
      return "a la derecha atrás";
    } else if (relativeBearing >= 157.5 && relativeBearing < 202.5) {
      return "atrás";
    } else if (relativeBearing >= 202.5 && relativeBearing < 247.5) {
      return "a la izquierda atrás";
    } else if (relativeBearing >= 247.5 && relativeBearing < 292.5) {
      return "a la izquierda";
    } else {
      return "a la izquierda al frente";
    }
  }

  String _generateIntermediateInstruction(
    double distance,
    Map<String, dynamic> nextStep,
    String direction,
  ) {
    final streetName = _getCleanStreetName(nextStep['instruction']);
    print('Distancia a $streetName: $distance metros');
    if (distance >= 1000) {
      final km = (distance / 1000).toStringAsFixed(1);
      state = state.copyWith(
          navigationInstruction:
              "En $km kilómetros, ${_getDirectionInstruction(direction)} y luego giras hacia $streetName");
      return "En $km kilómetros, ${_getDirectionInstruction(direction)} y luego giras hacia $streetName";
    } else {
      final meters = (distance / 100).round() * 100;
      if (meters > 100) {
        state = state.copyWith(
            navigationInstruction:
                "En $meters metros, ${_getDirectionInstruction(direction)} y luego giras hacia $streetName");
        return "En $meters metros, ${_getDirectionInstruction(direction)} y luego giras hacia $streetName";
      } else {
        state = state.copyWith(
            navigationInstruction:
                " ${_getDirectionInstruction(direction)} hacia $streetName");

        return " ${_getDirectionInstruction(direction)} hacia $streetName";
      }
    }
  }

  String _generateImmediateInstruction(
    Map<String, dynamic> step,
    String direction,
  ) {
    final streetName = _getCleanStreetName(step['instruction']);
    final maneuver = step['maneuver'] ?? '';
    toggleFollowUser();
    print('Instrucción inmediata: $maneuver');
    print('Dirección relativa: $streetName');

    switch (maneuver) {
      case 'turn-right':
      case 'turn-slight-right':
        ref.read(bluetoothProvider.notifier).sendMessage('d');
        print("se mando la letra d");
        return "Gira a la derecha ahora hacia $streetName";
      case 'turn-left':
      case 'turn-slight-left':
        ref.read(bluetoothProvider.notifier).sendMessage('i');
        print("se mando la letra i");
        return "Gira a la izquierda ahora hacia $streetName";
      case 'roundabout-right':
      case 'roundabout-left':
        return "Toma la rotonda hacia $streetName";
      default:
        return "Continúa ${direction.toLowerCase()} por $streetName";
    }
  }

  String _getDirectionInstruction(String direction) {
    toggleFollowUser();

    switch (direction) {
      case "al frente":
        return "continúa recto";
      case "a la derecha al frente":
        return "gira ligeramente a la derecha";
      case "a la derecha":
        return "gira a la derecha";
      case "a la derecha atrás":
        return "da la vuelta por la derecha";
      case "atrás":
        return "da la vuelta";
      case "a la izquierda atrás":
        return "da la vuelta por la izquierda";
      case "a la izquierda":
        return "gira a la izquierda";
      case "a la izquierda al frente":
        return "gira ligeramente a la izquierda";
      default:
        return "continúa";
    }
  }

  String _getCleanStreetName(String instruction) {
    return instruction
        .replaceAll(RegExp(r'^(Gira|Continúa|Dirígete|En|Toma).*hacia\s'), '')
        .replaceAll(RegExp(r'^(a la|al)\s+(derecha|izquierda)\s+en\s+'), '')
        .replaceAll(RegExp(r'El destino está.*$'), '')
        .trim();
  }

  bool _shouldUpdateInstruction(String lastInstruction, String newInstruction) {
    try {
      final lastNumber = double.parse(
          RegExp(r'[\d.]+').firstMatch(lastInstruction)?.group(0) ?? '0');
      final newNumber = double.parse(
          RegExp(r'[\d.]+').firstMatch(newInstruction)?.group(0) ?? '0');

      if (newInstruction.contains('kilómetros')) {
        return (lastNumber - newNumber).abs() >= 0.2;
      }
      return (lastNumber - newNumber).abs() >= 200;
    } catch (e) {
      return true;
    }
  }

  void dispose() {
    _locationSubscription?.cancel();
    _flutterTts.stop();
    _navigationTimer?.cancel();
    if (_mapController != null) {
      _mapController!.dispose();
    }
  }

  void navigationProcess() {
    if (state.currentRoute == null || state.currentPosition == null) return;

    List<mtk.LatLng> routePoints = state.currentRoute!.points
        .map((point) => mtk.LatLng(point.latitude, point.longitude))
        .toList();

    mtk.LatLng userPosition = mtk.LatLng(
      state.currentPosition!.latitude,
      state.currentPosition!.longitude,
    );

    // Aumentar la tolerancia para considerar que estás en la ruta
    bool isNearRoute = mtk.PolygonUtil.isLocationOnPath(
      userPosition,
      routePoints,
      true,
      tolerance: 30,
    );

    // Encontrar el punto más cercano en la ruta
    double minDistance = double.infinity;
    int closestPointIndex = -1;

    for (int i = 0; i < routePoints.length; i++) {
      double distance = geo.Geolocator.distanceBetween(
        state.currentPosition!.latitude,
        state.currentPosition!.longitude,
        routePoints[i].latitude,
        routePoints[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestPointIndex = i;
      }
    }

    // Si estamos muy lejos de la ruta o fuera de ella
    if (!isNearRoute || minDistance > 50) {
      // Solo recalcular si realmente nos hemos desviado significativamente
      if (!_isMovingTowardsRoute(routePoints)) {
        getNewRouteFromAPI();
      }
    } else {
      _updateRouteFromClosestPoint(
          routePoints, closestPointIndex, userPosition);
    }

    _checkDestinationProximity();
  }

  bool _isMovingTowardsRoute(List<mtk.LatLng> routePoints) {
    if (state.currentPosition == null || routePoints.isEmpty) return false;

    // Encontrar el punto más cercano en la ruta
    double minDistance = double.infinity;
    mtk.LatLng closestPoint = routePoints[0];

    for (var point in routePoints) {
      double distance = geo.Geolocator.distanceBetween(
        state.currentPosition!.latitude,
        state.currentPosition!.longitude,
        point.latitude,
        point.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = point;
      }
    }

    // Calcular el bearing hacia el punto más cercano
    double bearingToRoute = geo.Geolocator.bearingBetween(
      state.currentPosition!.latitude,
      state.currentPosition!.longitude,
      closestPoint.latitude,
      closestPoint.longitude,
    );

    // Comparar con nuestro heading actual
    double headingDifference =
        (state.currentPosition!.heading - bearingToRoute).abs();
    if (headingDifference > 180) headingDifference = 360 - headingDifference;

    // Consideramos que nos movemos hacia la ruta si la diferencia es menor a 60 grados
    return headingDifference < 45;
  }

  void _handleOffRoute(List<mtk.LatLng> routePoints, mtk.LatLng userPosition) {
    if (state.isLoading) return;

    double distanceToRoute = double.infinity;
    int nextImportantPointIndex = -1;
    int startSearchIndex =
        state.currentStepIndex > 0 ? state.currentStepIndex * 10 : 0;

    for (int i = startSearchIndex;
        i < min(routePoints.length, startSearchIndex + 50);
        i += 5) {
      double currentDistance = geo.Geolocator.distanceBetween(
        state.currentPosition!.latitude,
        state.currentPosition!.longitude,
        routePoints[i].latitude,
        routePoints[i].longitude,
      );

      if (currentDistance < distanceToRoute) {
        distanceToRoute = currentDistance;
        nextImportantPointIndex = i;
      }
    }

    if (distanceToRoute > 40) {
      _consecutiveOffRoute++;

      if (_consecutiveOffRoute >= 2) {
        bool isMovingTowardsDestination = _isMovingTowardsDestination();
        if (!isMovingTowardsDestination) {
          _consecutiveOffRoute = 0;
          getNewRouteFromAPI();
        }
      }
      return;
    } else {
      _consecutiveOffRoute = 0;
    }

    if (nextImportantPointIndex != -1) {
      _updateRouteFromPoint(routePoints, nextImportantPointIndex);
    }
  }

  int _consecutiveOffRoute = 0;

  bool _isMovingTowardsDestination() {
    if (state.currentPosition == null) return false;

    double currentDistance = geo.Geolocator.distanceBetween(
      state.currentPosition!.latitude,
      state.currentPosition!.longitude,
      state.destinationPosition.latitude,
      state.destinationPosition.longitude,
    );

    double bearingToDestination = geo.Geolocator.bearingBetween(
      state.currentPosition!.latitude,
      state.currentPosition!.longitude,
      state.destinationPosition.latitude,
      state.destinationPosition.longitude,
    );

    double headingDifference =
        (state.currentPosition!.heading - bearingToDestination).abs();
    if (headingDifference > 180) headingDifference = 360 - headingDifference;

    return headingDifference < 90 && state.currentPosition!.speed > 0.3;
  }

  void _updateRouteFromPoint(List<mtk.LatLng> routePoints, int startIndex) {
    List<mtk.LatLng> newRoutePoints =
        routePoints.sublist(min(startIndex, routePoints.length - 1));

    final newRoute = Polyline(
      polylineId: const PolylineId('route'),
      points:
          newRoutePoints.map((e) => LatLng(e.latitude, e.longitude)).toList(),
      color: Colors.blue,
      width: 5,
    );

    state = state.copyWith(currentRoute: newRoute);
  }

  void _updateRouteFromClosestPoint(
    List<mtk.LatLng> routePoints,
    int closestPointIndex,
    mtk.LatLng userPosition,
  ) {
    routePoints[closestPointIndex] = userPosition;
    List<mtk.LatLng> remainingRoute = routePoints.sublist(closestPointIndex);

    final newRoute = Polyline(
      polylineId: const PolylineId('route'),
      points:
          remainingRoute.map((e) => LatLng(e.latitude, e.longitude)).toList(),
      color: Colors.blue,
      width: 5,
    );

    state = state.copyWith(currentRoute: newRoute);
  }

  void _checkDestinationProximity() {
    if (state.currentPosition == null || state.currentRoute == null) return;

    double distanceToDestination = geo.Geolocator.distanceBetween(
      state.currentPosition!.latitude,
      state.currentPosition!.longitude,
      state.destinationPosition.latitude,
      state.destinationPosition.longitude,
    );

    // Verifica si la última posición de la ruta es la misma que la posición actual
    LatLng lastRoutePosition = state.currentRoute!.points.last;
    double distanceToEndOfRoute = geo.Geolocator.distanceBetween(
      state.currentPosition!.latitude,
      state.currentPosition!.longitude,
      lastRoutePosition.latitude,
      lastRoutePosition.longitude,
    );

    if (distanceToDestination < 20 || distanceToEndOfRoute < 1) {
      print("se mando la letra x");
      ref.read(bluetoothProvider.notifier).sendMessage('x');
      _flutterTts
          .speak("Has llegado a tu destino, gracias por usar Wey assist");
      Future.delayed(const Duration(seconds: 6), () {
        stopNavigation();
        ref.read(appRouterProvider).go('/home');
        dispose();
      });
    }
  }

  void centerOnUser() {
    if (state.currentPosition == null || !state.isMapInitialized) return;

    _animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            state.currentPosition!.latitude,
            state.currentPosition!.longitude,
          ),
          zoom: 18.0,
        ),
      ),
    );
  }

  void recalculateRoute() {
    getNewRouteFromAPI();
  }

  Future<bool> checkLocationPermission() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          return false;
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  Future<void> openLocationSettings() async {
    await geo.Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await geo.Geolocator.openAppSettings();
  }

  void onCameraMove(CameraPosition position) {
    if (state.isFollowingUser) {
      state = state.copyWith(isFollowingUser: false);
    }
  }
}
