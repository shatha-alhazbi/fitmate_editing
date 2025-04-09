import 'package:flutter_tts/flutter_tts.dart';

class VoiceFeedbackService {
  FlutterTts flutterTts = FlutterTts();
  String lastSpokenFeedback = '';
  DateTime lastSpokenTime = DateTime.now();
  bool isEnabled = true;
  
  Future<void> initialize() async {
    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.5); // Slower rate for better understanding
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);
      
      print("TTS initialized successfully");
    } catch (e) {
      print("Error initializing TTS: $e");
    }
  }
  
  Future<void> speak(String text) async {
    if (!isEnabled) return;
    
    // Don't repeat the same feedback too quickly
    final now = DateTime.now();
    if (text == lastSpokenFeedback && 
        now.difference(lastSpokenTime).inSeconds < 5) {
      print("Skipping repeated feedback: $text");
      return;
    }
    
    try {
      print("Speaking: $text");
      lastSpokenFeedback = text;
      lastSpokenTime = now;
      
      await flutterTts.speak(text);
    } catch (e) {
      print("Error speaking text: $e");
    }
  }
  
  Future<void> stop() async {
    try {
      await flutterTts.stop();
    } catch (e) {
      print("Error stopping TTS: $e");
    }
  }
  
  void toggleVoiceFeedback() {
    isEnabled = !isEnabled;
    if (!isEnabled) {
      stop();
    }
  }
}