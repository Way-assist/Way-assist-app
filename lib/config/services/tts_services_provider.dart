import 'package:flutter_tts/flutter_tts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tts_services_provider.g.dart';

class TtsService {
  late FlutterTts _flutterTts;

  TtsService() {
    _flutterTts = FlutterTts();
    _initialize();
  }

  void _initialize() async {
    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  void setCompletionHandler(Function onComplete) {
    _flutterTts.setCompletionHandler(() async {
      await Future.delayed(Duration(seconds: 1));
      onComplete();
    });
  }

  void stop() {
    _flutterTts.stop();
  }
}

@Riverpod(keepAlive: true)
TtsService ttsService(ref) {
  return TtsService();
}
