import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsCubit extends Cubit<List<String>> {
  NotificationsCubit() : super(const []);

  void push(String message) {
    emit([message, ...state]);
  }

  void markAllRead() {
    emit(const []);
  }
}
