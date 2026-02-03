import 'package:flutter/material.dart';
import 'package:run_flutter_run/l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../domain/entities/enum/activity_type.dart';
import '../../common/core/utils/activity_utils.dart';
import '../../common/core/utils/color_utils.dart';
import '../../common/core/utils/ui_utils.dart';
import '../../common/core/widgets/share_map_button.dart';
import '../../common/location/view_model/location_view_model.dart';
import '../../common/location/widgets/location_map.dart';
import '../../common/metrics/widgets/metrics.dart';
import '../../common/timer/widgets/timer_sized.dart';
import '../view_model/sum_up_view_model.dart';
import '../widgets/save_button.dart';

class SumUpScreen extends HookConsumerWidget {
  const SumUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sumUpViewModelProvider);
    final provider = ref.read(sumUpViewModelProvider.notifier);
    ActivityType selectedType = state.type;

    final locations = ref.read(locationViewModelProvider).savedPositions;

    final List<LatLng> points =
        ref.read(locationViewModelProvider.notifier).savedPositionsLatLng();

    final List<Marker> markers = [];

    // Add markers to the map if activity locations are available.
    if (locations.isNotEmpty) {
      markers.add(
        Marker(
          markerId: const MarkerId('start_location'),
          position: LatLng(
            locations.first.latitude,
            locations.first.longitude,
          ),
          infoWindow: const InfoWindow(title: 'Start Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      if (locations.length > 1) {
        markers.add(
          Marker(
            markerId: const MarkerId('end_location'),
            position: LatLng(
              locations.last.latitude,
              locations.last.longitude,
            ),
            infoWindow: const InfoWindow(title: 'End Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    }

    return Scaffold(
      body: state.isSaving
          ? Center(child: UIUtils.loader)
          : SafeArea(
              child: Column(
                children: [
                  UIUtils.createHeader(
                      AppLocalizations.of(context)!.activity_sumup),
                  const SizedBox(height: 10),
                  ActivityUtils.buildActivityTypeDropdown(
                      context, selectedType, provider),
                  const TimerTextSized(),
                  const Metrics(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SizedBox(
                      height: 500,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(150),
                          topRight: Radius.circular(150),
                        ),
                        child: RepaintBoundary(
                          key: state.boundaryKey,
                          child: LocationMap(
                            points: points,
                            markers: markers,
                            mapController: null,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 16,
            right: 80,
            child: SaveButton(disabled: state.isSaving),
          ),
          Positioned(
            bottom: 16,
            left: 80,
            child: ShareMapButton(
                activity: provider.getActivity(),
                boundaryKey: state.boundaryKey),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
