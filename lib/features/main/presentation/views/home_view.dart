import 'package:wayassist/features/auth/auth.dart';
import 'package:wayassist/features/main/presentation/views/favorite_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wayassist/config/config.dart';
import 'package:wayassist/features/main/presentation/providers/favorites_provider.dart';
import 'package:wayassist/features/main/presentation/providers/search_map_provider.dart';
import 'package:wayassist/features/main/presentation/providers/shared_data_map_provider.dart';
import 'package:wayassist/features/shared/shared.dart';
import 'package:go_router/go_router.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with TickerProviderStateMixin {
  bool _isModalOpen = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('El servicio de ubicación está deshabilitado.'),
      ));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Los permisos de ubicación han sido denegados.'),
        ));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Los permisos de ubicación han sido denegados permanentemente.'),
      ));
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    ref.read(favoritesProvider.notifier).getFavorites();
    ref.watch(searchMapProvider.notifier).onLongPress(
          position.longitude,
          position.latitude,
        );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchMapProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final sharedDataState = ref.watch(sharedDataProvider);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(0xFF08a8dd),
      systemNavigationBarColor: Theme.of(context).colorScheme.onSurface,
    ));

    if (sharedDataState.latitude != null && sharedDataState.longitude != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isModalOpen && ModalRoute.of(context)?.isCurrent == true) {
          _isModalOpen = true;

          ref
              .read(searchMapProvider.notifier)
              .onLatitudeModifyChange(sharedDataState.latitude!.toString());
          ref
              .read(searchMapProvider.notifier)
              .onLongitudeModifyChange(sharedDataState.longitude!.toString());

          showModalBottomSheet(
            isScrollControlled: true,
            isDismissible: true,
            enableDrag: true,
            context: context,
            builder: (context) {
              return const ModalFavorite();
            },
          ).whenComplete(() {
            _isModalOpen = false;
          });
        }
      });
    }
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: searchState.latitude == 0 && searchState.longitude == 0
          ? const CheckAuthStatusScreen()
          : Scaffold(
              appBar: AppBar(
                backgroundColor: Theme.of(context).primaryColor,
                title: Text('Zona de búsqueda',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(color: colors.surface)),
                centerTitle: true,
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 120,
                      child: CustomFilledButton(
                        text: 'Buscar por voz',
                        onPressed: searchState.search.value.isEmpty
                            ? () {
                                ref
                                    .read(searchMapProvider.notifier)
                                    .onIsVozChange(true);
                                ref
                                    .read(searchMapProvider.notifier)
                                    .startVoiceSearch();
                              }
                            : null,
                        leadingIconSvg: 'assets/icons/microfono.svg',
                        borderColor: colors.secondary.withOpacity(0.2),
                        textColor: searchState.search.value.isEmpty
                            ? colors.secondary
                            : colors.secondary.withOpacity(0.5),
                        buttonColor: searchState.search.value.isEmpty
                            ? colors.surface
                            : colors.surface.withOpacity(0.7),
                        iconColor: searchState.search.value.isEmpty
                            ? colors.primary
                            : colors.primary.withOpacity(0.5),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    CustomTextFormField(
                      hint: 'Lugar de búsqueda',
                      label: 'Buscar',
                      keyboardType: TextInputType.name,
                      initialvalue: searchState.search.value,
                      onChanged: searchState.isVoz
                          ? null
                          : (value) {
                              ref
                                  .read(searchMapProvider.notifier)
                                  .onSearchChange(value);
                            },
                      suffixIconS: searchState.search.isValid
                          ? Icon(Icons.check_circle,
                              color: MaterialTheme.success.seed)
                          : null,
                      errorMessage: !searchState.isValid
                          ? searchState.search.errorMessage
                          : null,
                    ),
                    SizedBox(
                      height: screenHeight * 0.33,
                      child: Column(
                        children: [
                          if (searchState.isLoading)
                            const CircularProgressIndicator()
                          else if (searchState.errorMensage.isNotEmpty)
                            Text(
                              searchState.errorMensage,
                              style: const TextStyle(color: Colors.red),
                            )
                          else if (searchState.places.isNotEmpty)
                            Expanded(
                              child: SingleChildScrollView(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: searchState.places.length,
                                  itemBuilder: (context, index) {
                                    final place = searchState.places[index];
                                    return ListTile(
                                      title: Text(place.description),
                                      onTap: () {
                                        ref
                                            .watch(searchMapProvider.notifier)
                                            .onPlaceSelected(place);
                                        context.push(
                                            '/home/map/origin/${searchState.latitude},${searchState.longitude}/destination/${place.location!.latitude},${place.location!.longitude}/name/${place.description}');
                                      },
                                      onLongPress: () async {
                                        if (place.location != null) {
                                          await ref
                                              .watch(searchMapProvider.notifier)
                                              .onAddressSelectedChange(
                                                  place.description);
                                          await ref
                                              .watch(searchMapProvider.notifier)
                                              .onLatitudeModifyChange(place
                                                  .location!.latitude
                                                  .toString());
                                          await ref
                                              .watch(searchMapProvider.notifier)
                                              .onLongitudeModifyChange(place
                                                  .location!.longitude
                                                  .toString());
                                          await ref
                                              .watch(searchMapProvider.notifier)
                                              .onPlaceSelected(place);
                                          if (mounted) {
                                            showModalBottomSheet(
                                              isScrollControlled: true,
                                              context: context,
                                              builder: (context) {
                                                return const ModalFavorite();
                                              },
                                            );
                                          }
                                        }
                                      },
                                      selected:
                                          searchState.selectedIndex == index,
                                    );
                                  },
                                ),
                              ),
                            )
                          else
                            const Center(
                                child: Text('No se encontraron resultados')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
