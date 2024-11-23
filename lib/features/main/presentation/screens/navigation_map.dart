import 'package:wayassist/features/main/presentation/providers/navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationScreen extends ConsumerWidget {
  final String origin;
  final String destination;
  final String destinationName;

  const NavigationScreen({
    Key? key,
    required this.origin,
    required this.destination,
    required this.destinationName,
  }) : super(key: key);

  LatLng _parseLatLng(String coordString) {
    final parts = coordString.split(',');
    if (parts.length != 2) {
      throw const FormatException('Formato de coordenadas inválido');
    }

    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);

    if (lat == null || lng == null) {
      throw const FormatException('Coordenadas inválidas');
    }

    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    late final LatLng originPosition;
    late final LatLng destinationPosition;
    try {
      originPosition = _parseLatLng(origin);
      destinationPosition = _parseLatLng(destination);
    } catch (e) {
      return SafeArea(
        child: Scaffold(
          body: Center(
            child: Text(
              'Error: Coordenadas inválidas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      );
    }

    final navigationState = ref.watch(navigationProvider(
        originPosition, destinationPosition, destinationName));

    if (navigationState.isLoading) {
      return _LoadingView();
    }

    return Scaffold(
      body: Stack(
        children: [
          _MapView(
            ref: ref,
            state: navigationState,
            originPosition: originPosition,
            destinationPosition: destinationPosition,
            destinationName: destinationName,
          ),
          _TopBar(
            state: navigationState,
            onBack: () {
              ref
                  .read(navigationProvider(
                          originPosition, destinationPosition, destinationName)
                      .notifier)
                  .stopNavigation();
              context.go('/home');
            },
          ),
          if (navigationState.isNavigationMode)
            _NavigationOverlay(state: navigationState),
          _ActionButtons(
            ref: ref,
            state: navigationState,
            originPosition: originPosition,
            destinationPosition: destinationPosition,
            destinationName: destinationName,
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Preparando navegación...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapView extends StatelessWidget {
  final WidgetRef ref;
  final NavigationState state;
  final LatLng originPosition;
  final LatLng destinationPosition;
  final String destinationName;

  const _MapView({
    required this.ref,
    required this.state,
    required this.originPosition,
    required this.destinationPosition,
    required this.destinationName,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      mapType: MapType.normal,
      onMapCreated: (controller) {
        ref
            .read(navigationProvider(
                    originPosition, destinationPosition, destinationName)
                .notifier)
            .setMapController(controller);
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      compassEnabled: true,
      markers: state.markers,
      polygons: state.polygons,
      polylines: state.currentRoute != null ? {state.currentRoute!} : {},
      zoomControlsEnabled: false,
      initialCameraPosition: CameraPosition(
        target: state.destinationPosition,
        zoom: 15.0,
      ),
      onCameraMove: (position) => ref
          .read(navigationProvider(
                  originPosition, destinationPosition, destinationName)
              .notifier)
          .onCameraMove(position),
    );
  }
}

class _TopBar extends ConsumerWidget {
  final NavigationState state;
  final VoidCallback onBack;

  const _TopBar({
    required this.state,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _BackButton(onBack: onBack),
                const SizedBox(width: 12),
                Expanded(
                  child: _DestinationInfo(
                    destinationName: state.destinationName,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onBack;

  const _BackButton({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _DestinationInfo extends StatelessWidget {
  final String destinationName;

  const _DestinationInfo({
    required this.destinationName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Navegando hacia',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          destinationName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _NavigationOverlay extends StatelessWidget {
  final NavigationState state;

  const _NavigationOverlay({required this.state});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 120,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavigationMetric(
                  icon: Icons.directions_walk,
                  value: '${state.distanceToDestination.toStringAsFixed(1)} m',
                  label: 'Distancia',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Semantics(
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  state.navigationInstruction,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _NavigationMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final WidgetRef ref;
  final NavigationState state;
  final LatLng originPosition;
  final LatLng destinationPosition;
  final String destinationName;

  const _ActionButtons({
    required this.ref,
    required this.state,
    required this.originPosition,
    required this.destinationPosition,
    required this.destinationName,
  });

  @override
  Widget build(BuildContext context) {
    final provider =
        navigationProvider(originPosition, destinationPosition, destinationName)
            .notifier;

    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (state.isNavigationMode) const SizedBox(height: 12),
          _NavigationButton(
            icon: Icons.my_location,
            backgroundColor: Colors.white,
            iconColor: Colors.black54,
            onPressed: () => ref.read(provider).centerOnUser(),
          ),
          const SizedBox(height: 12),
          if (!state.isNavigationMode)
            _StartNavigationButton(
              onPressed: () => ref.read(provider).startNavigation(),
            ),
        ],
      ),
    );
  }
}

class _StartNavigationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _StartNavigationButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: "btnStart",
      backgroundColor: Theme.of(context).colorScheme.primary,
      onPressed: onPressed,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 0),
      label: SizedBox(
        width: MediaQuery.of(context).size.width - 40,
        child: Row(
          children: [
            const Expanded(child: SizedBox()),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.navigation,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Iniciar navegación',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onPressed;

  const _NavigationButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: null,
      backgroundColor: backgroundColor,
      onPressed: onPressed,
      child: Icon(
        icon,
        color: iconColor,
      ),
    );
  }
}
