import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class VoiceRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<void> startRecording() async {
    if (!await hasPermission()) return;

    final Directory tempDir = await getTemporaryDirectory();
    final String filePath = '${tempDir.path}/voice_command.wav';

    // Start recording to file with WAV encoder (preferred by Bhasini)
    // If not supported, we might need to convert, but let's try WAV/PCM16.
    const config = RecordConfig(
      encoder: AudioEncoder.wav, 
      sampleRate: 16000, 
      numChannels: 1,
    );
    
    // Check if file exists and delete
    final file = File(filePath);
    if (file.existsSync()) {
      file.deleteSync();
    }

    await _audioRecorder.start(config, path: filePath);
  }

  Future<String?> stopRecording() async {
    return await _audioRecorder.stop();
  }

  Future<void> dispose() async {
    _audioRecorder.dispose();
  }
}
