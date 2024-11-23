import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wayassist/features/main/infrastructure/repositories/favorite_repository_impl.dart';
import 'package:wayassist/features/main/main.dart';
part 'favorites_provider.g.dart';

class FavoriteState {
  final List<Favorite> favorites;
  final bool isLoading;
  final String messageError;

  FavoriteState({
    this.favorites = const [],
    this.isLoading = false,
    this.messageError = '',
  });

  FavoriteState copyWith({
    List<Favorite>? favorites,
    bool? isLoading,
    String? messageError,
  }) {
    return FavoriteState(
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
      messageError: messageError ?? this.messageError,
    );
  }
}

@riverpod
class Favorites extends _$Favorites {
  late final FavoriteRepository _favoriteRepository = FavoriteRepositoryImpl();

  @override
  FavoriteState build() {
    return FavoriteState(
      favorites: [],
      isLoading: false,
      messageError: '',
    );
  }

  Future<void> createupdateFavorite(String id, String name, double latitude,
      double longitude, String address) async {
    state = state.copyWith(isLoading: true);
    if (id == 'new') {
      try {
        final favorite = await _favoriteRepository.createFavorite(
            name, longitude, latitude, address);
        state = state.copyWith(
            favorites: [...state.favorites, favorite], isLoading: false);
      } catch (e) {
        state = state.copyWith(messageError: e.toString());
      } finally {
        state = state.copyWith(isLoading: false);
      }
    } else {
      try {
        final favorite = await _favoriteRepository.updateFavorite(
            id, name, longitude, latitude, address, '');

        state = state.copyWith(
          favorites: [
            ...state.favorites.where((element) => element.id != id),
            favorite,
          ],
          isLoading: false,
        );
      } catch (e) {
        print(e);
        state = state.copyWith(messageError: e.toString());
      } finally {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> deleteFavorite(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _favoriteRepository.deleteFavorite(id);

      state = state.copyWith(
        favorites: [...state.favorites.where((element) => element.id != id)],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(messageError: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<Favorite> getFavorite(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final favorite = await _favoriteRepository.getFavorite(id);

      final exists = state.favorites.any((element) => element.id == id);

      if (!exists) {
        state = state.copyWith(
          favorites: [...state.favorites, favorite],
          isLoading: false,
        );
      }

      return favorite;
    } catch (e) {
      state = state.copyWith(messageError: e.toString());

      print(e);
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> getFavorites() async {
    state = state.copyWith(isLoading: true);
    try {
      final favorites = await _favoriteRepository.getFavorites();

      if (favorites.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(
          favorites: [...state.favorites, ...favorites], isLoading: false);
    } catch (e) {
      state = state.copyWith(messageError: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
