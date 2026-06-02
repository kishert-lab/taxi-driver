import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/navigation/external_navigation_service.dart';
import '../../chat/presentation/dispatcher_chat_button.dart';
import '../domain/driver_order.dart';
import 'orders_controllers.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderDetailsProvider(widget.orderId).notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderDetailsProvider(widget.orderId));
    final data = state.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Детали поездки')),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(orderDetailsProvider(widget.orderId).notifier).load(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.errorMessage != null && data == null)
              _ErrorCard(message: state.errorMessage!),
            if (data != null) ...[
              _OrderMainCard(order: data.order),
              const SizedBox(height: 12),
              if (data.route?.points.isNotEmpty == true)
                _RouteCard(route: data.route!, order: data.order),
            ] else if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderMainCard extends StatelessWidget {
  const _OrderMainCard({required this.order});

  final DriverOrder order;

  @override
  Widget build(BuildContext context) {
    final date = order.displayDate;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Row(label: 'Пассажир', value: order.passenger.name),
            _Row(label: 'Телефон', value: order.passenger.phone),
            _Row(
              label: 'Рейтинг',
              value:
                  '${order.passenger.rating.toStringAsFixed(1)} (${order.passenger.ratingsCount})',
            ),
            if (date != null)
              _Row(
                label: 'Дата',
                value: DateFormat('dd.MM.yyyy HH:mm').format(date.toLocal()),
              ),
            _Row(label: 'Подача', value: order.pickupPoint.address),
            _Row(label: 'Назначение', value: order.destinationPoint.address),
            _Row(label: 'Статус', value: order.statusLabel),
            _Row(label: 'Стоимость', value: order.price.formatted),
            if (order.comment?.isNotEmpty == true)
              _Row(label: 'Комментарий', value: order.comment!),
            _Row(
              label: 'Действия',
              value: order.allowedActions.isEmpty
                  ? 'Нет доступных действий'
                  : order.allowedActions.join(', '),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (order.passenger.phone.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri(scheme: 'tel', path: order.passenger.phone),
                    ),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Позвонить'),
                  ),
                FilledButton.icon(
                  onPressed: () async {
                    final service = const ExternalNavigationService();
                    final target = NavigationTarget(
                      label: 'Подача',
                      latitude: order.destinationPoint.location.latitude,
                      longitude: order.destinationPoint.location.longitude,
                      address: order.destinationPoint.address,
                    );
                    await service.openRoute(destination: target);
                  },
                  icon: const Icon(Icons.route_outlined),
                  label: const Text('Маршрут'),
                ),
                DispatcherChatButton(orderId: order.orderId),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route, required this.order});

  final DriverRoute route;
  final DriverOrder order;

  @override
  Widget build(BuildContext context) {
    final points = route.points
        .map(
          (point) => LatLng(point.location.latitude, point.location.longitude),
        )
        .toList(growable: false);
    final hasPolyline = points.length > 1;
    final singlePoint = points.first;
    final bounds = hasPolyline ? LatLngBounds.fromPoints(points) : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Трек поездки',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: singlePoint,
                    initialZoom: hasPolyline ? 13 : 16,
                    initialCameraFit: bounds == null
                        ? null
                        : CameraFit.bounds(
                            bounds: bounds,
                            padding: const EdgeInsets.all(24),
                          ),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'taxi_driver_app',
                    ),
                    PolylineLayer(
                      polylines: [
                        if (hasPolyline)
                          Polyline(
                            points: points,
                            strokeWidth: 4,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: points.first,
                          width: 36,
                          height: 36,
                          child: const _MapMarker(
                            icon: Icons.radio_button_checked,
                            color: Colors.green,
                          ),
                        ),
                        Marker(
                          point: points.last,
                          width: 36,
                          height: 36,
                          child: const _MapMarker(
                            icon: Icons.location_on,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Точек маршрута: ${route.points.length}'),
            Text('Подача: ${order.pickupPoint.address}'),
            Text('Назначение: ${order.destinationPoint.address}'),
          ],
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
