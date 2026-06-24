import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'gps_disabled',
        'GPS вимкнено. Увімкніть локацію для визначення погоди.',
      );
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          'permission_denied',
          'Дозвіл на локацію відхилено. Без нього автоматичний пошук не працюватиме.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'permission_denied_forever',
        'Дозвіл відхилено назавжди. Перейдіть у налаштування додатку, щоб дозволити доступ.',
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
