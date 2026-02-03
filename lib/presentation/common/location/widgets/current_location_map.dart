import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/utils/color_utils.dart';
import '../../core/utils/ui_utils.dart';
import '../view_model/location_view_model.dart';
import 'location_map.dart';

/// Widget that displays the current location on a map.
class CurrentLocationMap extends HookConsumerWidget {
  CurrentLocationMap({super.key});

  final dataFutureProvider = FutureProvider<void>((ref) async {
    final provider = ref.read(locationViewModelProvider.notifier);
    return await provider.startGettingLocation();
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.read(locationViewModelProvider.notifier);
    final state = ref.watch(locationViewModelProvider);

    var futureProvider = ref.watch(dataFutureProvider);

    final points = provider.savedPositionsLatLng();

    final currentPosition = state.currentPosition;
    final currentLatitude = currentPosition?.latitude ?? 0;
    final currentLongitude = currentPosition?.longitude ?? 0;

    final markers = <Marker>[
      Marker(
        markerId: const MarkerId('current_position'),
        position: LatLng(currentLatitude, currentLongitude),
        infoWindow: const InfoWindow(title: 'Current Location'),
      ),
    ];

    if (points.isNotEmpty) {
      markers.add(
        Marker(
          markerId: const MarkerId('start_position'),
          position: LatLng(
            points.first.latitude,
            points.first.longitude,
          ),
          infoWindow: const InfoWindow(title: 'Start Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    if (points.length > 1) {
      markers.add(
        Marker(
          markerId: const MarkerId('end_position'),
          position: LatLng(
            points.last.latitude,
            points.last.longitude,
          ),
          infoWindow: const InfoWindow(title: 'End Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    useEffect(() {
      return () async {
        await provider.cancelLocationStream();
      };
    }, []);

    return futureProvider.when(data: (total) {
      return Expanded(
          child: SizedBox(
              height: 500,
              child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(150),
                    topRight: Radius.circular(150),
                  ),
                  child: LocationMap(
                    points: points,
                    markers: markers,
                    currentPosition: LatLng(currentLatitude, currentLongitude),
                    mapController: null,
                  ))));
    }, loading: () {
      return Expanded(child: Center(child: UIUtils.loader));
    }, error: (error, stackTrace) {
      return Text('$error');
    });
  }
}
