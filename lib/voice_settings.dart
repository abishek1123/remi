import 'package:flutter/material.dart';
import 'tts_service.dart';
import 'theme.dart';

Future<void> showVoiceSettings(BuildContext context) async {
  final tts = TtsService.instance;
  await tts.init();
  final voices = await tts.getVoices();

  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    backgroundColor: kSurface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _VoiceSettingsSheet(voices: voices),
  );
}

class _VoiceSettingsSheet extends StatefulWidget {
  final List<Map<String, String>> voices;
  const _VoiceSettingsSheet({required this.voices});

  @override
  State<_VoiceSettingsSheet> createState() => _VoiceSettingsSheetState();
}

class _VoiceSettingsSheetState extends State<_VoiceSettingsSheet> {
  late String? _selectedName;
  late double _rate;
  late double _pitch;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final tts = TtsService.instance;
    _selectedName = tts.voiceName;
    _rate = tts.rate;
    _pitch = tts.pitch;
    _enabled = tts.enabled;
  }

  Map<String, String>? get _selectedVoice {
    for (final v in widget.voices) {
      if (v['name'] == _selectedName) return v;
    }
    return null;
  }

  Future<void> _test() async {
    final tts = TtsService.instance;
    await tts.setEnabled(true);
    await tts.saveSettings(
      name: _selectedVoice?['name'],
      locale: _selectedVoice?['locale'],
      newRate: _rate,
      newPitch: _pitch,
    );
    await tts.speak('Hi! This is how I sound now.');
    await tts.setEnabled(_enabled);
  }

  Future<void> _save() async {
    final tts = TtsService.instance;
    await tts.setEnabled(_enabled);
    await tts.saveSettings(
      name: _selectedVoice?['name'],
      locale: _selectedVoice?['locale'],
      newRate: _rate,
      newPitch: _pitch,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Voice Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Voice replies'),
            subtitle: const Text(
              'Read answers out loud',
              style: TextStyle(color: kTextSecondary, fontSize: 12),
            ),
            activeThumbColor: kRed,
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          const SizedBox(height: 8),
          if (widget.voices.isEmpty)
            const Text(
              'No voices available on this device.',
              style: TextStyle(color: kTextSecondary),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedName,
              isExpanded: true,
              dropdownColor: kSurfaceLight,
              decoration: const InputDecoration(labelText: 'Voice'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Default voice'),
                ),
                ...widget.voices.map(
                  (v) => DropdownMenuItem<String>(
                    value: v['name'],
                    child: Text(
                      '${v['name']} (${v['locale']})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _selectedName = value),
            ),
          const SizedBox(height: 20),
          Text('Speed: ${_rate.toStringAsFixed(2)}x',
              style: const TextStyle(color: kTextSecondary)),
          Slider(
            value: _rate.clamp(0.25, 3.0),
            min: 0.25,
            max: 3.0,
            divisions: 11,
            activeColor: kRed,
            label: '${_rate.toStringAsFixed(2)}x',
            onChanged: (v) => setState(() => _rate = v),
          ),
          Text('Pitch: ${_pitch.toStringAsFixed(2)}',
              style: const TextStyle(color: kTextSecondary)),
          Slider(
            value: _pitch,
            min: 0.5,
            max: 2.0,
            activeColor: kRed,
            onChanged: (v) => setState(() => _pitch = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _test,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kTextPrimary,
                    side: const BorderSide(color: kTextSecondary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Test'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
