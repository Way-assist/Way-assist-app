import 'package:wayassist/features/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wayassist/config/config.dart';
import 'package:wayassist/features/main/presentation/providers/favorites_provider.dart';
import 'package:wayassist/features/main/presentation/providers/search_map_provider.dart';
import 'package:wayassist/features/main/presentation/providers/shared_data_map_provider.dart';
import 'package:wayassist/features/shared/shared.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icon.dart';
import 'package:line_icons/line_icons.dart';

class FavoriteView extends ConsumerStatefulWidget {
  const FavoriteView({Key? key}) : super(key: key);

  @override
  _FavoriteViewState createState() => _FavoriteViewState();
}

class _FavoriteViewState extends ConsumerState<FavoriteView>
    with TickerProviderStateMixin {
  bool _isModalOpen = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      ref.read(favoritesProvider.notifier).getFavorites();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchMapProvider);

    final favoriteState = ref.watch(favoritesProvider);
    print(favoriteState.favorites);
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
      child: searchState.latitude == 0 &&
              searchState.longitude == 0 &&
              favoriteState.isLoading
          ? const CheckAuthStatusScreen()
          : favoriteState.favorites.isEmpty
              ? Scaffold(
                  appBar: AppBar(
                    backgroundColor: Theme.of(context).primaryColor,
                    title: Text('Lugares Favoritos',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge!
                            .copyWith(color: colors.surface)),
                    centerTitle: true,
                  ),
                  body: Center(
                    child: Text('No hay favoritos'),
                  ),
                )
              : Scaffold(
                  appBar: AppBar(
                    title: const Text('Lugares Favoritos'),
                    centerTitle: true,
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: SingleChildScrollView(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: favoriteState.favorites.length,
                        itemBuilder: (context, index) {
                          final favorite = favoriteState.favorites[index];
                          return ListTile(
                            title: Text(favorite.name),
                            onTap: () {
                              context.push(
                                  '/home/map/origin/${searchState.latitude},${searchState.longitude}/destination/${favorite.latitude},${favorite.longitude}/name/${favorite.name}');
                            },
                            onLongPress: () async {
                              await ref
                                  .read(searchMapProvider.notifier)
                                  .loadFavoriteforId(favorite.id);
                              if (mounted) {
                                showModalBottomSheet(
                                  isScrollControlled: true,
                                  context: context,
                                  builder: (context) {
                                    return const ModalFavorite();
                                  },
                                );
                              }
                            },
                            subtitle: Text(favorite.address),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    onPressed: () {
                                      ref
                                          .read(favoritesProvider.notifier)
                                          .deleteFavorite(favorite.id);
                                    },
                                    icon: LineIcon.trash(
                                      size: 25,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    )),
                                Icon(
                                  LineIcons.streetView,
                                  size: 30,
                                  color: MaterialTheme.success.seed,
                                ),
                              ],
                            ),
                            trailing: Icon(
                              LineIcons.star,
                              size: 30,
                              color: MaterialTheme.warning.seed,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
    );
  }
}

class ModalFavorite extends ConsumerWidget {
  const ModalFavorite({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchMapProvider);
    final colors = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextFormField(
                  hint: 'Nombre del lugar favorito',
                  label: 'Nombre',
                  keyboardType: TextInputType.name,
                  initialvalue: searchState.nameFavorite.value,
                  onChanged: (value) {
                    ref
                        .read(searchMapProvider.notifier)
                        .onFavoriteNameChange(value);
                  },
                  suffixIconS: searchState.nameFavorite.isValid
                      ? Icon(Icons.check_circle,
                          color: MaterialTheme.success.seed)
                      : null,
                  errorMessage: !searchState.isValid
                      ? searchState.nameFavorite.errorMessage
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  hint: 'Latitud',
                  label: 'Latitud',
                  keyboardType: TextInputType.name,
                  initialvalue: searchState.latitudeModify.value,
                  onChanged: (value) {
                    ref
                        .read(searchMapProvider.notifier)
                        .onLatitudeModifyChange(value);
                  },
                  suffixIconS: searchState.latitudeModify.isValid
                      ? Icon(Icons.check_circle,
                          color: MaterialTheme.success.seed)
                      : null,
                  errorMessage: !searchState.isValid
                      ? searchState.latitudeModify.errorMessage
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  hint: 'Longitud',
                  label: 'Longitud',
                  keyboardType: TextInputType.name,
                  initialvalue: searchState.longitudeModify.value,
                  onChanged: (value) {
                    ref
                        .read(searchMapProvider.notifier)
                        .onLongitudeModifyChange(value);
                  },
                  suffixIconS: searchState.longitudeModify.isValid
                      ? Icon(Icons.check_circle,
                          color: MaterialTheme.success.seed)
                      : null,
                  errorMessage: !searchState.isValid
                      ? searchState.longitudeModify.errorMessage
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  hint: 'Ubicación',
                  label: 'Ubicación',
                  keyboardType: TextInputType.name,
                  initialvalue: searchState.addressSelected.value,
                  onChanged: (value) {
                    ref
                        .read(searchMapProvider.notifier)
                        .onAddressSelectedChange(value);
                  },
                  suffixIconS: searchState.addressSelected.isValid
                      ? Icon(Icons.check_circle,
                          color: MaterialTheme.success.seed)
                      : null,
                  errorMessage: !searchState.isValid
                      ? searchState.addressSelected.errorMessage
                      : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: CustomFilledButton(
                    borderColor: colors.secondary.withOpacity(0.2),
                    textColor: colors.secondary,
                    buttonColor: colors.surface,
                    text: 'Guardar',
                    onPressed: () async {
                      await ref
                          .read(searchMapProvider.notifier)
                          .onFormSubmited();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
