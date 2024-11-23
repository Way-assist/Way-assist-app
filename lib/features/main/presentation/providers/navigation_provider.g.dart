// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$navigationHash() => r'1307a590327a5ef090ea2fe066add53407fefe65';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$Navigation extends BuildlessNotifier<NavigationState> {
  late final LatLng originPosition;
  late final LatLng destinationPosition;
  late final String destinationName;

  NavigationState build(
    LatLng originPosition,
    LatLng destinationPosition,
    String destinationName,
  );
}

/// See also [Navigation].
@ProviderFor(Navigation)
const navigationProvider = NavigationFamily();

/// See also [Navigation].
class NavigationFamily extends Family<NavigationState> {
  /// See also [Navigation].
  const NavigationFamily();

  /// See also [Navigation].
  NavigationProvider call(
    LatLng originPosition,
    LatLng destinationPosition,
    String destinationName,
  ) {
    return NavigationProvider(
      originPosition,
      destinationPosition,
      destinationName,
    );
  }

  @override
  NavigationProvider getProviderOverride(
    covariant NavigationProvider provider,
  ) {
    return call(
      provider.originPosition,
      provider.destinationPosition,
      provider.destinationName,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'navigationProvider';
}

/// See also [Navigation].
class NavigationProvider
    extends NotifierProviderImpl<Navigation, NavigationState> {
  /// See also [Navigation].
  NavigationProvider(
    LatLng originPosition,
    LatLng destinationPosition,
    String destinationName,
  ) : this._internal(
          () => Navigation()
            ..originPosition = originPosition
            ..destinationPosition = destinationPosition
            ..destinationName = destinationName,
          from: navigationProvider,
          name: r'navigationProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$navigationHash,
          dependencies: NavigationFamily._dependencies,
          allTransitiveDependencies:
              NavigationFamily._allTransitiveDependencies,
          originPosition: originPosition,
          destinationPosition: destinationPosition,
          destinationName: destinationName,
        );

  NavigationProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.originPosition,
    required this.destinationPosition,
    required this.destinationName,
  }) : super.internal();

  final LatLng originPosition;
  final LatLng destinationPosition;
  final String destinationName;

  @override
  NavigationState runNotifierBuild(
    covariant Navigation notifier,
  ) {
    return notifier.build(
      originPosition,
      destinationPosition,
      destinationName,
    );
  }

  @override
  Override overrideWith(Navigation Function() create) {
    return ProviderOverride(
      origin: this,
      override: NavigationProvider._internal(
        () => create()
          ..originPosition = originPosition
          ..destinationPosition = destinationPosition
          ..destinationName = destinationName,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        originPosition: originPosition,
        destinationPosition: destinationPosition,
        destinationName: destinationName,
      ),
    );
  }

  @override
  NotifierProviderElement<Navigation, NavigationState> createElement() {
    return _NavigationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NavigationProvider &&
        other.originPosition == originPosition &&
        other.destinationPosition == destinationPosition &&
        other.destinationName == destinationName;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, originPosition.hashCode);
    hash = _SystemHash.combine(hash, destinationPosition.hashCode);
    hash = _SystemHash.combine(hash, destinationName.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NavigationRef on NotifierProviderRef<NavigationState> {
  /// The parameter `originPosition` of this provider.
  LatLng get originPosition;

  /// The parameter `destinationPosition` of this provider.
  LatLng get destinationPosition;

  /// The parameter `destinationName` of this provider.
  String get destinationName;
}

class _NavigationProviderElement
    extends NotifierProviderElement<Navigation, NavigationState>
    with NavigationRef {
  _NavigationProviderElement(super.provider);

  @override
  LatLng get originPosition => (origin as NavigationProvider).originPosition;
  @override
  LatLng get destinationPosition =>
      (origin as NavigationProvider).destinationPosition;
  @override
  String get destinationName => (origin as NavigationProvider).destinationName;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
