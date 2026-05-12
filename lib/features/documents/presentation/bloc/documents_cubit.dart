import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/models/driver_models.dart';

class DocumentsCubit extends Cubit<List<DriverDocument>> {
  DocumentsCubit()
    : super(const [
        DriverDocument(
          id: 'passport',
          type: 'Паспорт',
          status: DocumentStatus.notUploaded,
          required: true,
        ),
        DriverDocument(
          id: 'license',
          type: 'Водительское удостоверение',
          status: DocumentStatus.notUploaded,
          required: true,
        ),
        DriverDocument(
          id: 'sts',
          type: 'СТС',
          status: DocumentStatus.notUploaded,
          required: true,
        ),
        DriverDocument(
          id: 'osago',
          type: 'ОСАГО',
          status: DocumentStatus.notUploaded,
          required: true,
        ),
        DriverDocument(
          id: 'driver_photo',
          type: 'Фото водителя',
          status: DocumentStatus.notUploaded,
          required: true,
        ),
      ]);

  void approveAllForDemo() {
    emit(
      state
          .map(
            (document) => DriverDocument(
              id: document.id,
              type: document.type,
              status: DocumentStatus.approved,
              required: document.required,
              expiresAt: document.expiresAt,
            ),
          )
          .toList(growable: false),
    );
  }
}
