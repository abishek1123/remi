import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide TTS with user-customisable voice, speed, and pitch.
/// Settings persist locally via shared_preferences.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  String? voiceName;
  String? voiceLocale;
  double rate = 1.0; // 1.0 = normal; up to 3.0 for faster speech
  double pitch = 1.0; // 0.5-2.0
  bool enabled = true;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    voiceName = prefs.getString('tts_voice_name');
    voiceLocale = prefs.getString('tts_voice_locale');
    rate = prefs.getDouble('tts_rate') ?? 1.0;
    pitch = prefs.getDouble('tts_pitch') ?? 1.0;
    enabled = prefs.getBool('tts_enabled') ?? true;
    await _apply();
  }

  Future<void> setEnabled(bool value) async {
    enabled = value;
    if (!value) await stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_enabled', value);
  }

  Future<void> _apply() async {
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    if (voiceName != null && voiceLocale != null) {
      try {
        await _tts.setVoice({'name': voiceName!, 'locale': voiceLocale!});
      } catch (e) {
        debugPrint('Failed to set voice: $e');
      }
    }
  }

  Future<void> saveSettings({
    String? name,
    String? locale,
    required double newRate,
    required double newPitch,
  }) async {
    voiceName = name;
    voiceLocale = locale;
    rate = newRate;
    pitch = newPitch;

    final prefs = await SharedPreferences.getInstance();
    if (name != null && locale != null) {
      await prefs.setString('tts_voice_name', name);
      await prefs.setString('tts_voice_locale', locale);
    } else {
      await prefs.remove('tts_voice_name');
      await prefs.remove('tts_voice_locale');
    }
    await prefs.setDouble('tts_rate', newRate);
    await prefs.setDouble('tts_pitch', newPitch);
    await _apply();
  }

  /// Available voices as {name, locale} maps (browser voices on web).
  Future<List<Map<String, String>>> getVoices() async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((v) => {
                'name': v['name']?.toString() ?? '',
                'locale': v['locale']?.toString() ?? '',
              })
          .where((v) => v['name']!.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Failed to list voices: $e');
      return [];
    }
  }

  Future<void> speak(String text) async {
    await init();
    if (!enabled) return;
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
