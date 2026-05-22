import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class VoiceRecorderService {
  AudioRecorder? _audioRecorderInstance;
  AudioRecorder get _audioRecorder => _audioRecorderInstance ??= AudioRecorder();

  Future<bool> hasPermission() async {
    debugPrint("🎤 Checking microphone permission...");
    final status = await Permission.microphone.request();
    if (status == PermissionStatus.granted) {
      debugPrint("✅ Microphone permission granted.");
      return true;
    } else {
      debugPrint("❌ Microphone permission denied.");
      return false;
    }
  }

  Future<void> startRecording() async {
    if (!await hasPermission()) return;

    final Directory tempDir = await getTemporaryDirectory();
    final String filePath = '${tempDir.path}/voice_command.wav';

    // Start recording to file with WAV encoder
    const config = RecordConfig(
      encoder: AudioEncoder.wav, 
      sampleRate: 16000, 
      bitRate: 128000,
      numChannels: 1,
    );
    
    // Check if file exists and delete
    final file = File(filePath);
    if (file.existsSync()) {
      file.deleteSync();
    }

    try {
      debugPrint("🎙️ Starting audio recording...");
      await _audioRecorder.start(config, path: filePath);
      debugPrint("🎙️ Audio recording started.");
    } catch (e) {
      debugPrint("❌ Error starting audio recording: $e");
    }
  }

  Future<String?> stopRecording() async {
    debugPrint("🛑 Stopping audio recording...");
    try {
      final path = await _audioRecorder.stop();
      debugPrint("====== DEBUG RECORDING ======");
      debugPrint("Audio Path: $path");
      if (path != null) {
        final file = File(path);
        final exists = file.existsSync();
        debugPrint("File exists: $exists");
        if (exists) {
          debugPrint("File size: ${file.lengthSync()} bytes");
          if (file.lengthSync() == 0) {
             debugPrint("❌ WARNING: Audio file is empty (0 bytes)!");
          }
        } else {
          debugPrint("❌ WARNING: Audio file does not exist after recording!");
        }
      }
      debugPrint("=============================");
      return path;
    } catch (e) {
      debugPrint("❌ Error stopping audio recording: $e");
      return null;
    }
  }

  Future<void> dispose() async {
    _audioRecorderInstance?.dispose();
  }
}
