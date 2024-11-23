import 'package:dio/dio.dart';
import 'package:wayassist/config/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:formz/formz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wayassist/config/config.dart';
import 'package:wayassist/features/main/presentation/providers/favorites_provider.dart';
import 'package:wayassist/features/main/presentation/providers/shared_data_map_provider.dart';
import 'package:wayassist/features/shared/infrastructure/inputs/decimal.dart';
import 'package:wayassist/features/shared/shared.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'search_map_provider.g.dart';

enum SearchListeningStatus { idle, listening, error }

class PlaceSearchResult {
  final String placeId;
  final String description;
  final LatLng? location;

  PlaceSearchResult({
    required this.placeId,
    required this.description,
    this.location,
  });
}

class SearchMapState {
  final GenericWord search;
  final List<PlaceSearchResult> places;
  final bool isLoading;
  final String region;
  final GenericWord nameFavorite;
  final GenericWord addressSelected;
  final double longitude;
  final double latitude;
  final Decimal latitudeModify;
  final Decimal longitudeModify;
  final SearchListeningStatus listeningStatus;
  final int? selectedIndex;
  final PlaceSearchResult? selectedPlace;
  final bool isValid;
  final bool isVoz;
  final String errorMensage;
  final String? searchType;
  final String idFavorite;

  SearchMapState({
    this.search = const GenericWord.pure(),
    this.addressSelected = const GenericWord.pure(),
    this.places = const [],
    this.longitude = 0,
    this.idFavorite = 'new',
    this.isVoz = false,
    this.nameFavorite = const GenericWord.pure(),
    this.latitude = 0,
    this.region = 'Huanuco',
    this.isLoading = false,
    this.latitudeModify = const Decimal.pure(),
    this.longitudeModify = const Decimal.pure(),
    this.listeningStatus = SearchListeningStatus.idle,
    this.selectedIndex,
    this.selectedPlace,
    this.isValid = false,
    this.errorMensage = '',
    this.searchType,
  });

  SearchMapState copyWith({
    GenericWord? search,
    GenericWord? nameFavorite,
    GenericWord? addressSelected,
    String? idFavorite,
    List<PlaceSearchResult>? places,
    bool? isLoading,
    double? longitude,
    Decimal? longitudeModify,
    Decimal? latitudeModify,
    bool? isVoz,
    double? latitude,
    String? region,
    SearchListeningStatus? listeningStatus,
    int? selectedIndex,
    PlaceSearchResult? selectedPlace,
    bool? isValid,
    String? errorMensage,
    String? searchType,
  }) =>
      SearchMapState(
        search: search ?? this.search,
        nameFavorite: nameFavorite ?? this.nameFavorite,
        addressSelected: addressSelected ?? this.addressSelected,
        isVoz: isVoz ?? this.isVoz,
        idFavorite: idFavorite ?? this.idFavorite,
        longitudeModify: longitudeModify ?? this.longitudeModify,
        latitudeModify: latitudeModify ?? this.latitudeModify,
        places: places ?? this.places,
        isLoading: isLoading ?? this.isLoading,
        longitude: longitude ?? this.longitude,
        latitude: latitude ?? this.latitude,
        region: region ?? this.region,
        listeningStatus: listeningStatus ?? this.listeningStatus,
        selectedIndex: selectedIndex ?? this.selectedIndex,
        selectedPlace: selectedPlace ?? this.selectedPlace,
        isValid: isValid ?? this.isValid,
        errorMensage: errorMensage ?? this.errorMensage,
        searchType: searchType ?? this.searchType,
      );
}

@Riverpod(keepAlive: true)
class SearchMap extends _$SearchMap {
  late final Dio _dio;
  late final SpeechService _speech;
  late final TtsService _flutterTts;
  late final KeyValueStorageService _keyValueStorage;
  static String googleApiKey = Enviroment.googleMapsKey;

  @override
  SearchMapState build() {
    _initializeDio();
    _speech = ref.read(speechServiceProvider);
    _keyValueStorage = KeyValueStorageSericeImpl();
    _flutterTts = ref.read(ttsServiceProvider);
    _checkWelcomeMessage();
    return SearchMapState();
  }

  void _initializeDio() {
    _dio = Dio();
    _dio.options.baseUrl = 'https://maps.googleapis.com/maps/api';
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);
    _dio.options.contentType = Headers.jsonContentType;
  }

  Future<void> _checkWelcomeMessage() async {
    bool? hasSeenWelcomeMessage =
        await _keyValueStorage.getValue<bool>('hasSeenWelcomeMessage') ?? false;
    if (hasSeenWelcomeMessage != true) {
      await welcomeMessage();

      await _keyValueStorage.setKeyValue('hasSeenWelcomeMessage', true);
    }
  }

  Future<void> welcomeMessage() async {
    await _speakAndListen(
        'Bienvenido a Wey Assist. Para comenzar a buscar, solo presiona el boton de busqueda por voz o escribir en el texto de busqueda. ' +
            'Recuerda que también puedes importar tu ubicación desde Google Maps. ' +
            'Esto te permitirá añadir tu domicilio o cualquier lugar favorito a donde desees ir. ' +
            'Si necesitas ayuda para esto, dile a una persona de confianza que te asista. ' +
            'Lo único que esa persona tiene que hacer es compartir la ubicación desde Google Maps, ' +
            'seleccionar nuestra app, y se abrirá un formulario que esa persona deberá rellenar. ' +
            'Una vez completado, todo quedará configurado. ' +
            'Gracias, espero que lo pases de lo mejor.',
        () {});
  }

  Future<void> loadFavoriteforId(String id) async {
    final favorite = await ref.read(favoritesProvider.notifier).getFavorite(id);
    state = state.copyWith(
      idFavorite: favorite.id,
      nameFavorite: GenericWord.dirty(favorite.name),
      addressSelected: GenericWord.dirty(favorite.address),
      latitudeModify: Decimal.dirty(favorite.latitude.toString()),
      longitudeModify: Decimal.dirty(favorite.longitude.toString()),
    );
  }

  onIsVozChange(bool value) {
    state = state.copyWith(isVoz: value);
  }

  onAddressSelectedChange(String value) {
    final addressSelected = GenericWord.dirty(value);
    state = state.copyWith(
        addressSelected: addressSelected,
        isValid: Formz.validate([
          addressSelected,
          state.nameFavorite,
          state.latitudeModify,
          state.longitudeModify
        ]));
  }

  onFavoriteNameChange(String value) {
    final nameFavorite = GenericWord.dirty(value);
    state = state.copyWith(
        nameFavorite: nameFavorite,
        isValid: Formz.validate([
          nameFavorite,
          state.addressSelected,
          state.latitudeModify,
          state.longitudeModify
        ]));
  }

  onLongPress(double longitude, double latitude) {
    state = state.copyWith(longitude: longitude, latitude: latitude);
  }

  onLatitudeModifyChange(String value) {
    final latitudM = Decimal.dirty(value);
    state = state.copyWith(
        latitudeModify: latitudM,
        isValid: Formz.validate([
          latitudM,
          state.longitudeModify,
          state.nameFavorite,
          state.addressSelected
        ]));
  }

  onLongitudeModifyChange(String value) {
    final longitude = Decimal.dirty(value);
    state = state.copyWith(
        longitudeModify: longitude,
        isValid: Formz.validate([
          longitude,
          state.latitudeModify,
          state.nameFavorite,
          state.addressSelected
        ]));
  }

  onPlaceSelected(dynamic place) {
    state = state.copyWith(
      selectedPlace: place,
    );
  }

  onSearchChange(String value) {
    final search = GenericWord.dirty(value);
    state = state.copyWith(search: search, isValid: Formz.validate([search]));

    if (value.toLowerCase() == 'buscar por voz') {
      startVoiceSearch();
    } else if (value.length >= 2) {
      searchPlace(value, false);
    } else {
      state = state.copyWith(places: [], errorMensage: '');
    }
  }

  onFormSubmited() async {
    if (state.isValid) {
      final String name = state.nameFavorite.value;
      final double longitude =
          double.tryParse(state.longitudeModify.value) ?? 0;
      final double latitude = double.tryParse(state.latitudeModify.value) ?? 0;
      final String address = state.addressSelected.value;
      if (state.idFavorite == 'new') {
        await ref.read(favoritesProvider.notifier).createupdateFavorite(
              'new',
              name,
              latitude,
              longitude,
              address,
            );
      } else {
        await ref.read(favoritesProvider.notifier).createupdateFavorite(
              state.idFavorite,
              name,
              latitude,
              longitude,
              address,
            );
      }
      await ref.read(sharedDataProvider.notifier).clearState();
      state = state.copyWith(
        idFavorite: 'new',
        nameFavorite: GenericWord.pure(),
        addressSelected: GenericWord.pure(),
        search: GenericWord.pure(),
        selectedPlace: null,
        isValid: false,
      );
    }
  }

  Future<void> startVoiceSearch() async {
    await _speakAndListen(
        '¿Qué deseas buscar? Un jirón, calle, lugar público, o favoritos?',
        _startListeningForType);
  }

  Future<void> _speakAndListen(String text, VoidCallback onComplete) async {
    await _flutterTts.speak(text);
    _flutterTts.setCompletionHandler(() async {
      await Future.delayed(Duration(seconds: 1));
      onComplete();
    });
  }

  int _attemptCounter = 0;

  void _startListeningForType() async {
    bool available = await _speech.initialize();
    if (available) {
      state = state.copyWith(listeningStatus: SearchListeningStatus.listening);

      _speech.startListening((recognizedWords) async {
        if (recognizedWords.isNotEmpty) {
          _attemptCounter = 0;
          String type = recognizedWords.toLowerCase().trim();
          _speech.stopListening();

          if (type.contains('jirón') || type.contains('calle')) {
            state = state.copyWith(
                searchType: 'calle',
                listeningStatus: SearchListeningStatus.idle);
            await _speakAndListen(
                'Dime el nombre del jirón o calle que deseas buscar.',
                _startListeningForStreetName);
          } else if (type.contains('lugar público')) {
            state = state.copyWith(
                searchType: 'lugar público',
                listeningStatus: SearchListeningStatus.idle);
            await _speakAndListen(
                'Dime el nombre del lugar público que deseas buscar.',
                _startListeningForSearch);
          } else if (type.contains('favoritos')) {
            state = state.copyWith(
                searchType: 'favoritos',
                listeningStatus: SearchListeningStatus.idle);
            await _speakAndListen(
                'Enumerando tus favoritos.', _startListeningForFavorites);
          } else {
            state = state.copyWith(listeningStatus: SearchListeningStatus.idle);
            await _handleFailedAttempt();
          }
        }
      });

      Future.delayed(const Duration(seconds: 9), () {
        if (state.listeningStatus == SearchListeningStatus.listening) {
          _speech.stopListening();
          _handleFailedAttempt();
        }
      });
    }
  }

  Future<void> _handleFailedAttempt() async {
    _attemptCounter++;

    if (_attemptCounter >= 3) {
      state.copyWith(listeningStatus: SearchListeningStatus.idle);
      await _speakAndListen(
          'No se pudo entender después de varios intentos. Cancelo la interacción.',
          () {});
      _attemptCounter = 0;
    } else {
      await _speakAndListen(
          'No se pudo entender. Inténtalo de nuevo.¿Qué deseas buscar? Un jirón, calle, lugar público, o favoritos?',
          _startListeningForType);
    }
  }

  void _startListeningForFavorites() async {
    final favorites = ref.read(favoritesProvider).favorites;
    if (favorites.isEmpty) {
      await _speakAndListen('No tienes favoritos guardados.', startVoiceSearch);
      return;
    }

    String favoritesList = 'Tienes los siguientes favoritos: ';
    for (int i = 0; i < favorites.length; i++) {
      favoritesList += '${i + 1}: ${favorites[i].name}. ';
    }
    favoritesList += 'Dime el número de la opción que deseas seleccionar.';

    await _speakAndListen(favoritesList, _startListeningForFavoriteSelection);
  }

  void _startListeningForFavoriteSelection() async {
    bool available = await _speech.initialize();
    if (available) {
      state = state.copyWith(listeningStatus: SearchListeningStatus.listening);
      bool hasResponded = false;

      final favorites = ref.read(favoritesProvider).favorites;

      _speech.startListening((recognizedWords) async {
        if (recognizedWords.isNotEmpty && !hasResponded) {
          hasResponded = true;
          String cleanedWords = recognizedWords.trim();
          int? selectedIndex =
              int.tryParse(cleanedWords) ?? _convertWordsToNumber(cleanedWords);

          if (selectedIndex != null &&
              selectedIndex > 0 &&
              selectedIndex <= favorites.length) {
            final selectedFavorite = favorites[selectedIndex - 1];
            await _speakAndListen(
                'Has seleccionado ${selectedFavorite.name}. ¿Estás seguro? Di sí o no.',
                () => _startListeningForFavoriteConfirmation(selectedFavorite));
          } else {
            await _speakAndListen(
                'Selección inválida. Volviendo a enumerar los favoritos. Por favor, di un número válido.',
                _startListeningForFavorites);
          }
        }
      });

      Future.delayed(const Duration(seconds: 6), () {
        if (!hasResponded) {
          _speech.stopListening();
          _speakAndListen(
              'No se pudo entender. Volviendo a enumerar los favoritos.',
              _startListeningForFavorites);
        }
      });
    }
  }

  void _startListeningForFavoriteConfirmation(dynamic selectedFavorite) async {
    bool available = await _speech.initialize();
    if (available) {
      state = state.copyWith(listeningStatus: SearchListeningStatus.listening);
      bool hasResponded = false;

      _speech.startListening((recognizedWords) async {
        if (recognizedWords.isNotEmpty && !hasResponded) {
          hasResponded = true;
          String action = recognizedWords.trim().toLowerCase();
          _speech.stopListening();

          if (action.contains('sí') || action.contains('si')) {
            state = state.copyWith(listeningStatus: SearchListeningStatus.idle);
            _speakAndListen('Has confirmado la selección.', () {
              print('Has seleccionado el favorito: ${selectedFavorite.name}');
            });
          } else if (action.contains('no')) {
            state = state.copyWith(listeningStatus: SearchListeningStatus.idle);
            _speakAndListen('Volvamos a empezar,', startVoiceSearch);
          } else {
            _speakAndListen('No se entendió la respuesta, intenta de nuevo.',
                () {
              _startListeningForFavoriteConfirmation(selectedFavorite);
            });
          }
        }
      });

      Future.delayed(const Duration(seconds: 6), () {
        if (!hasResponded) {
          _speech.stopListening();
          _speakAndListen('No se pudo entender. Inténtalo de nuevo.', () {
            _startListeningForFavoriteConfirmation(selectedFavorite);
          });
        }
      });
    }
  }

  void _startListeningForStreetName() async {
    bool available = await _speech.initialize();
    if (available) {
      state = state.copyWith(listeningStatus: SearchListeningStatus.listening);

      _speech.startListening((recognizedWords) async {
        if (recognizedWords.isNotEmpty) {
          String streetName = recognizedWords.trim();
          _speech.stopListening();

          state = state.copyWith(
              search: GenericWord.dirty(streetName),
              listeningStatus: SearchListeningStatus.idle);
          await _speakAndListen('Dime el número del jirón o calle.',
              _startListeningForStreetNumber);
        }
      });

      Future.delayed(const Duration(seconds: 6), () {
        if (state.listeningStatus == SearchListeningStatus.listening) {
          _speech.stopListening();
          _speakAndListen(
              'No se pudo entender el nombre de la calle. Inténtalo de nuevo.',
              _startListeningForStreetName);
        }
      });
    }
  }

  void _startListeningForStreetNumber() async {
    bool available = await _speech.initialize();
    if (available) {
      state = state.copyWith(listeningStatus: SearchListeningStatus.listening);

      _speech.startListening((recognizedWords) async {
        if (recognizedWords.isNotEmpty) {
          String streetNumber = recognizedWords.trim();
          _speech.stopListening();

          String fullAddress = '${state.search.value} $streetNumber';
          state = state.copyWith(
              search: GenericWord.dirty(fullAddress),
              listeningStatus: SearchListeningStatus.idle);

          await _speakAndListen('Buscando la dirección: jiron $fullAddress.',
              () {
            searchPlace(fullAddress, true);
          });
        }
      });

      Future.delayed(const Duration(seconds: 6), () {
        if (state.listeningStatus == SearchListeningStatus.listening) {
          _speech.stopListening();
          _speakAndListen(
              'No se pudo entender el número de la calle. Inténtalo de nuevo.',
              _startListeningForStreetNumber);
        }
      });
    }
  }

  void _startListeningForSearch() async {
    bool available = await _speech.initialize();
    if (available) {
      state = state.copyWith(listeningStatus: SearchListeningStatus.listening);
      _speech.startListening(
        (recognizedWords) {
          if (recognizedWords.isNotEmpty) {
            _speech.stopListening();
            state = state.copyWith(
              search: GenericWord.dirty(recognizedWords),
              listeningStatus: SearchListeningStatus.idle,
            );
            searchPlace(recognizedWords, true);
          }
        },
      );

      Future.delayed(const Duration(seconds: 6), () {
        if (state.listeningStatus == SearchListeningStatus.listening) {
          _speech.stopListening();
          _speakAndListen(
              'No se pudo entender. Inténtalo de nuevo.', startVoiceSearch);
        }
      });
    }
  }

  Future<void> searchPlace(String query, bool isVoz) async {
    if (query.isEmpty || (state.latitude == 0 && state.longitude == 0)) {
      state = state.copyWith(places: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, errorMensage: '');

    try {
      final location = "${state.latitude},${state.longitude}";

      final response = await _dio.get(
        '/place/autocomplete/json',
        queryParameters: {
          'input': query,
          'location': location,
          'radius': '50000',
          'strictbounds': 'true',
          'components': 'country:pe',
          'key': googleApiKey,
        },
      );

      if (response.statusCode == 200 && response.data['predictions'] != null) {
        final predictions = response.data['predictions'] as List;
        final features = await Future.wait(
          predictions.take(5).map((prediction) async {
            final details = await _getPlaceDetails(prediction['place_id']);
            return PlaceSearchResult(
              placeId: prediction['place_id'],
              description: prediction['description'],
              location: details,
            );
          }),
        );
        state = state.copyWith(places: features, isLoading: false);
        print('Se encontraron ${features} resultados');
        if (isVoz) {
          if (features.isNotEmpty) {
            String resultText =
                'Se encontraron ${features.length} resultados. ';
            for (int i = 0; i < features.length; i++) {
              //!aqui modifiaar
              resultText += '${i + 1}:  ${features[i].description}. ';
            }
            resultText += 'Di el número de la opción que deseas seleccionar.';
            await _speakAndListen(resultText, _startListeningForSelection);
          } else {
            await _speakAndListen(
                'No se encontraron resultados. Prueba con otra búsqueda.',
                startVoiceSearch);
          }
        }
      } else {
        state = state.copyWith(
            isLoading: false, errorMensage: 'Error al buscar lugares');
        if (isVoz) {
          await _speakAndListen('Hubo un error al buscar lugares.', () {});
        }
      }
    } catch (e) {
      print(e);
      state = state.copyWith(isLoading: false, errorMensage: 'Error: $e');
      await _speakAndListen('Ocurrió un error durante la búsqueda.', () {});
    }
  }

  Future<LatLng?> _getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get(
        '/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'geometry',
          'key': googleApiKey,
        },
      );

      if (response.statusCode == 200 &&
          response.data['result'] != null &&
          response.data['result']['geometry'] != null &&
          response.data['result']['geometry']['location'] != null) {
        final location = response.data['result']['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      }
    } catch (e) {
      print('Error al obtener detalles del lugar: $e');
    }
    return null;
  }

  int? _convertWordsToNumber(String words) {
    Map<String, int> wordToNumberMap = {
      'uno': 1,
      '1': 1,
      'primero': 1,
      'primera': 1,
      'dos': 2,
      '2': 2,
      'segundo': 2,
      'segunda': 2,
      'tres': 3,
      '3': 3,
      'tercero': 3,
      'tercera': 3,
      'cuatro': 4,
      'cuarto': 4,
      'cuarta': 4,
      '4': 4,
      'cinco': 5,
      '5': 5,
      'quinto': 5,
      'quinta': 5,
      'seis': 6,
      '6': 6,
      'sexto': 6,
      'sexta': 6,
      'siete': 7,
      'séptimo': 7,
      '7': 7,
      'séptima': 7,
      'ocho': 8,
      'octavo': 8,
      'octava': 8,
      '8': 8,
      'nueve': 9,
      '9': 9,
      'novena': 9,
      'diez': 10,
      '10': 10,
      'décimo': 10,
      'décima': 10,
    };

    words = words.toLowerCase();

    for (var entry in wordToNumberMap.entries) {
      if (words.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  void _startListeningForSelection() async {
    bool available = await _speech.initialize();
    if (available) {
      state = state.copyWith(listeningStatus: SearchListeningStatus.listening);
      bool hasResponded = false;

      _speech.startListening((recognizedWords) {
        String cleanedWords = recognizedWords.trim();
        print('Palabras reconocidas: $cleanedWords');
        if (cleanedWords.isNotEmpty) {
          int? selectedIndex =
              int.tryParse(cleanedWords) ?? _convertWordsToNumber(cleanedWords);
          print('Palabras reconocidas: $selectedIndex');
          if (selectedIndex != null &&
              selectedIndex > 0 &&
              selectedIndex <= state.places.length) {
            print("entre 1");
            if (!hasResponded) {
              print("entre 2");
              hasResponded = true;
              PlaceSearchResult selectedPlace = state.places[selectedIndex - 1];
              onLatitudeModifyChange(
                  selectedPlace.location!.latitude.toString());
              onLongitudeModifyChange(
                  selectedPlace.location!.longitude.toString());
              onAddressSelectedChange(selectedPlace.description);
              state = state.copyWith(
                  selectedIndex: selectedIndex - 1,
                  selectedPlace: selectedPlace,
                  listeningStatus: SearchListeningStatus.idle);
              _speakAndListen(
                  'Has seleccionado la opción $selectedIndex, . ¿Qué deseas hacer, Continuar o agregar a favoritos?',
                  _startListeningForNextAction);
            }
          } else {
            if (!hasResponded) {
              hasResponded = true;
              _speech.stopListening();
              Future.delayed(const Duration(seconds: 7), () {
                _speakAndListen('Por favor, di un número válido.',
                    _startListeningForSelection);
              });
            }
          }
        }
      });

      Future.delayed(const Duration(seconds: 6), () {
        if (state.listeningStatus == SearchListeningStatus.listening &&
            !hasResponded) {
          hasResponded = true;
          _speech.stopListening();
          Future.delayed(const Duration(seconds: 7), () {
            if (state.selectedPlace == null) {
              _speakAndListen(
                  'No se recibió una selección. Por favor, intenta de nuevo.',
                  _startListeningForSelection);
            }
          });
        }
      });
    }
  }

  void _startListeningForNextAction() async {
    bool available = await _speech.initialize();
    if (available) {
      state = state.copyWith(listeningStatus: SearchListeningStatus.listening);

      _speech.startListening((recognizedWords) async {
        if (recognizedWords.isNotEmpty) {
          String action = recognizedWords.trim().toLowerCase();
          _speech.stopListening();

          if (action.contains('continuar')) {
            state = state.copyWith(listeningStatus: SearchListeningStatus.idle);
            _speakAndListen('Has elegido continuar.', () {
              print('Continúa con la acción deseada.');
              ref.read(appRouterProvider).push(
                  '/home/map/origin/${state.latitude},${state.longitude}/destination/${state.latitudeModify.value},${state.longitudeModify.value}/name/${state.addressSelected.value}');
            });
          } else if (action.contains('agregar') ||
              action.contains('destacados')) {
            state = state.copyWith(listeningStatus: SearchListeningStatus.idle);
            _speakAndListen(
              '¿Con qué nombre deseas guardar este lugar en tus favoritos?',
              _startListeningForFavoriteName,
            );
          } else {
            _speakAndListen('No se entendió la opción, intenta de nuevo.',
                _startListeningForNextAction);
          }
        }
      });

      Future.delayed(const Duration(seconds: 6), () {
        if (state.listeningStatus == SearchListeningStatus.listening) {
          _speech.stopListening();
          _speakAndListen('No se pudo entender. Inténtalo de nuevo.',
              _startListeningForNextAction);
        }
      });
    }
  }

  void _startListeningForFavoriteName() async {
    bool available = await _speech.initialize();
    if (available) {
      state = state.copyWith(listeningStatus: SearchListeningStatus.listening);

      bool hasResponded = false;

      _speech.startListening((recognizedWords) async {
        onFavoriteNameChange(recognizedWords);
        if (recognizedWords.isNotEmpty && !hasResponded) {
          hasResponded = true;
          _speech.stopListening();
          state = state.copyWith(listeningStatus: SearchListeningStatus.idle);

          _speakAndListen('Guardando tu lugar en favoritos.', () async {
            await onFormSubmited();
            ref.read(appRouterProvider).push(
                '/home/map/origin/${state.latitude},${state.longitude}/destination/${state.latitudeModify.value},${state.longitudeModify.value}/name/${state.addressSelected.value}');
          });
        }
      });

      Future.delayed(const Duration(seconds: 6), () {
        if (state.listeningStatus == SearchListeningStatus.listening &&
            !hasResponded) {
          hasResponded = true;
          _speech.stopListening();
          _speakAndListen('No se pudo entender el nombre. Inténtalo de nuevo.',
              _startListeningForFavoriteName);
        }
      });
    }
  }
}
