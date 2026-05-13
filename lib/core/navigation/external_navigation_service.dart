import 'package:url_launcher/url_launcher.dart';

import '../errors/app_exception.dart';

enum ExternalNavigatorApp { yandexNavigator, twoGis, googleMaps }

class NavigationTarget {
  const NavigationTarget({
    required this.label,
    this.latitude,
    this.longitude,
    this.address,
  });

  final String label;
  final double? latitude;
  final double? longitude;
  final String? address;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get query {
    if (hasCoordinates) {
      return '$latitude,$longitude';
    }

    final value = address?.trim();
    if (value == null || value.isEmpty) {
      throw const ValidationException(
        'navigation target requires address or coordinates',
      );
    }

    return value;
  }
}

class ExternalNavigationService {
  const ExternalNavigationService();

  Future<void> openRoute({
    required NavigationTarget destination,
    ExternalNavigatorApp preferredNavigator =
        ExternalNavigatorApp.yandexNavigator,
  }) async {
    final candidates = [
      preferredNavigator,
      ...ExternalNavigatorApp.values.where((app) => app != preferredNavigator),
    ];

    for (final navigator in candidates) {
      final uri = _buildAppUri(navigator, destination);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    for (final uri in _fallbackUris(destination)) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    throw const AppException('no navigation application is available');
  }

  Uri _buildAppUri(
    ExternalNavigatorApp navigator,
    NavigationTarget destination,
  ) {
    return switch (navigator) {
      ExternalNavigatorApp.yandexNavigator =>
        destination.hasCoordinates
            ? Uri(
                scheme: 'yandexnavi',
                host: 'build_route_on_map',
                queryParameters: {
                  'lat_to': destination.latitude.toString(),
                  'lon_to': destination.longitude.toString(),
                },
              )
            : Uri(
                scheme: 'yandexnavi',
                host: 'search',
                queryParameters: {'text': destination.query},
              ),
      ExternalNavigatorApp.twoGis =>
        destination.hasCoordinates
            ? Uri.parse(
                'dgis://2gis.ru/routeSearch/rsType/car/to/${destination.longitude},${destination.latitude}',
              )
            : Uri(
                scheme: 'dgis',
                host: '2gis.ru',
                pathSegments: ['search', destination.query],
              ),
      ExternalNavigatorApp.googleMaps => Uri(
        scheme: 'google.navigation',
        queryParameters: {'q': destination.query},
      ),
    };
  }

  List<Uri> _fallbackUris(NavigationTarget destination) {
    final query = destination.query;
    return [
      Uri(
        scheme: 'geo',
        path: destination.hasCoordinates ? query : '0,0',
        queryParameters: destination.hasCoordinates ? null : {'q': query},
      ),
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': query,
        'travelmode': 'driving',
      }),
      Uri.https('yandex.ru', '/maps/', {'rtext': '~$query', 'rtt': 'auto'}),
    ];
  }
}
