import 'package:flutter_dotenv/flutter_dotenv.dart';

class Enviroment {
  static initEnviroment() async {
    await dotenv.load(fileName: ".env");
  }

  static String apiUrl = dotenv.env['API_URL'] ?? 'No esta configurado el url';
  static String googleMapsKey =
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'No esta configurado el api key';
}
