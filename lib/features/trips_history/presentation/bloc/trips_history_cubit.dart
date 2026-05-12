import 'package:flutter_bloc/flutter_bloc.dart';

class TripsHistoryCubit extends Cubit<List<String>> {
  TripsHistoryCubit() : super(const []);

  void addCompletedTrip(String orderId) {
    emit([...state, orderId]);
  }
}
