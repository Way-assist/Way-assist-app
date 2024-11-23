import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:speech_to_text/speech_to_text.dart';

part 'speech_services_provider.g.dart';

class SpeechService {
  late SpeechToText _speech;

  SpeechService() {
    _speech = SpeechToText();
  }

  Future<bool> initialize() async {
    return await _speech.initialize(
        finalTimeout: Duration(seconds: 15), debugLogging: true);
  }

  void startListening(Function(String recognizedWords) onResult) async {
    Future.delayed(Duration(milliseconds: 1500), () {
      _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          }
        },
        listenFor: Duration(days: 20),
        pauseFor: Duration(seconds: 15),
      );
    });
  }

  void stopListening() async {
    _speech.stop();
    _speech.cancel();
  }
}

@riverpod
SpeechService speechService(ref) => SpeechService();
