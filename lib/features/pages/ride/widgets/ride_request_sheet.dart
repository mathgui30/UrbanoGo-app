import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:urbanogo/core/models/ride_model.dart';
import 'package:urbanogo/core/theme/app_colors.dart';
import 'package:urbanogo/features/pages/ride/cubit/ride_flow_cubit.dart';
import 'package:urbanogo/features/pages/ride/widgets/rating_form.dart';

class RideRequestSheet extends StatelessWidget {
  final LatLng? origin;

  const RideRequestSheet({super.key, required this.origin});

  static String _money(int cents) =>
      'R\$ ${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  static String _trackingLabel(String status) {
    switch (status) {
      case 'requested':
        return 'Enviando pedido...';
      case 'searching':
        return 'Procurando um motorista...';
      case 'assigned':
        return 'Motorista a caminho';
      case 'in_progress':
        return 'Em viagem';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RideFlowCubit, RideFlowState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.slate,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                ..._content(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _content(BuildContext context, RideFlowState state) {
    final cubit = context.read<RideFlowCubit>();

    switch (state.status) {
      case RideFlowStatus.idle:
        return [
          const Text(
            'Toque no mapa para escolher o destino',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _typeToggle(state, cubit),
        ];

      case RideFlowStatus.ready:
        return [
          _typeToggle(state, cubit),
          const SizedBox(height: 16),
          _primaryButton(
            label: 'Ver preço',
            onPressed: origin == null
                ? null
                : () => cubit.getQuote(origin!),
          ),
          if (origin == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Aguardando sua localização...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ];

      case RideFlowStatus.quoting:
        return [_loading('Calculando preço...')];

      case RideFlowStatus.quoted:
        final q = state.quote!;
        final m = q.priceBreakdown.multipliers;
        final extras = <String>[
          if (m.time != 1.0) 'horário x${m.time}',
          if (m.demand != 1.0) 'demanda x${m.demand}',
          if (m.weather != 1.0) 'clima x${m.weather}',
        ];
        return [
          Text(
            _money(q.priceCents),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(q.distanceMeters / 1000).toStringAsFixed(1)} km'
            '${extras.isEmpty ? '' : '  ·  ${extras.join('  ')}'}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _primaryButton(
            label: state.rideType == 'delivery'
                ? 'Solicitar entrega'
                : 'Solicitar corrida',
            onPressed: origin == null
                ? null
                : () => cubit.requestRide(origin!),
          ),
          const SizedBox(height: 8),
          _textButton('Escolher outro destino', cubit.reset),
        ];

      case RideFlowStatus.requesting:
        return [_loading('Solicitando...')];

      case RideFlowStatus.tracking:
        final ride = state.ride;
        return [
          Row(
            children: [
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _trackingLabel(ride?.status ?? 'searching'),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
          if (ride?.driver != null) ...[
            const SizedBox(height: 12),
            _driverCard(ride!.driver!),
          ],
          const SizedBox(height: 16),
          _textButton('Cancelar corrida', cubit.cancelRide),
        ];

      case RideFlowStatus.completed:
        return [
          RatingForm(
            key: const ValueKey('passenger-rating'),
            title: 'Como foi sua viagem?',
            subtitle: state.ride?.driver != null
                ? 'Avalie ${state.ride!.driver!.name}'
                : 'Avalie o motorista',
            submitting: state.ratingSubmitting,
            submitted: state.ratingSubmitted,
            errorMessage: state.ratingError,
            onSubmit: cubit.rateRide,
            onDone: cubit.reset,
          ),
        ];

      case RideFlowStatus.cancelled:
        final status = state.ride?.status;
        return [
          Text(
            status == 'expired'
                ? 'Nenhum motorista disponível'
                : 'Corrida cancelada',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _primaryButton(label: 'Nova corrida', onPressed: cubit.reset),
        ];

      case RideFlowStatus.failure:
        return [
          Text(
            state.errorMessage ?? 'Algo deu errado.',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          _primaryButton(
            label: 'Tentar de novo',
            onPressed: () {
              if (state.destination == null) {
                cubit.reset();
              } else {
                cubit.chooseDestination(state.destination!);
              }
            },
          ),
        ];
    }
  }

  Widget _typeToggle(RideFlowState state, RideFlowCubit cubit) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'ride',
          label: Text('Carona'),
          icon: Icon(Icons.directions_car),
        ),
        ButtonSegment(
          value: 'delivery',
          label: Text('Entrega'),
          icon: Icon(Icons.local_shipping),
        ),
      ],
      selected: {state.rideType},
      onSelectionChanged: (s) => cubit.setType(s.first),
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.black
              : Colors.white,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Colors.transparent,
        ),
      ),
    );
  }

  Widget _driverCard(RideDriverModel driver) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${driver.vehicleModel} · ${driver.vehiclePlate}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.verified_user, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                driver.trustScore.toStringAsFixed(2),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({required String label, VoidCallback? onPressed}) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _textButton(String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: Colors.grey),
      child: Text(label),
    );
  }

  Widget _loading(String label) {
    return Row(
      children: [
        const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }
}
