import 'dart:async';
import 'dart:io';
import 'dart:math' show sqrt;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

class SttService {
  SttService();

  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();
  final StreamController<bool> _vadStateController =
      StreamController<bool>.broadcast();

  Stream<String> get transcriptStream => _transcriptController.stream;

  /// Emits `true` when VAD detects speech, `false` when silence/end-of-speech.
  Stream<bool> get vadStateStream => _vadStateController.stream;

  // Tunable parameters
  double rmsThreshold = 0.015;
  double silenceThreshold = 0.6;
  double vadSpeechThreshold = 0.6;
  int hardCapSeconds = 4;
  int overlapMs = 500;

  bool _running = false;
  bool get isRunning => _running;

  bool isInitialized = false;
  String? initError;

  StreamSubscription<Uint8List>? _streamSub;

  late sherpa.OfflineRecognizer _recognizer;
  late Directory _modelDir;

  Future<void> initialize() async {
    try {
      sherpa.initBindings();
      _modelDir = await _prepareModelDir();
      _recognizer = sherpa.OfflineRecognizer(_buildConfig(_modelDir.path));
      isInitialized = true;
    } catch (e) {
      initError = e.toString();
      rethrow;
    }
  }

  Future<void> start() async {
    if (_running) return;
    _running = true;
    unawaited(_recordLoop());
  }

  Future<void> stop() async {
    _running = false;
    await _streamSub?.cancel();
    _streamSub = null;
  }

  void dispose() {
    _running = false;
    _transcriptController.close();
    _vadStateController.close();
    _recognizer.free();
  }

  // ---------------------------------------------------------------------------

  sherpa.OfflineRecognizerConfig _buildConfig(String dir) {
    return sherpa.OfflineRecognizerConfig(
      model: sherpa.OfflineModelConfig(
        transducer: sherpa.OfflineTransducerModelConfig(
          encoder: '$dir/encoder.int8.onnx',
          decoder: '$dir/decoder.onnx',
          joiner: '$dir/joiner.int8.onnx',
        ),
        tokens: '$dir/tokens.txt',
        numThreads: 2,
        debug: false,
        provider: 'cpu',
      ),
    );
  }

  Future<Directory> _prepareModelDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dest = Directory('${docsDir.path}/assets/models/stt');

    const files = [
      'encoder.int8.onnx',
      'decoder.onnx',
      'joiner.int8.onnx',
      'tokens.txt',
      'silero_vad.onnx',
    ];

    if (!dest.existsSync()) {
      await dest.create(recursive: true);
    }

    for (final name in files) {
      final destFile = File('${dest.path}/$name');
      if (!destFile.existsSync()) {
        final data = await rootBundle.load('assets/models/stt/$name');
        await destFile.writeAsBytes(data.buffer.asUint8List());
      }
    }

    return dest;
  }

  Future<void> _recordLoop() async {
    final vad = sherpa.VoiceActivityDetector(
      config: sherpa.VadModelConfig(
        sileroVad: sherpa.SileroVadModelConfig(
          model: '${_modelDir.path}/silero_vad.onnx',
          threshold: vadSpeechThreshold,
          minSilenceDuration: silenceThreshold,
          minSpeechDuration: 0.3,
          windowSize: 512,
          maxSpeechDuration: 30.0,
        ),
        sampleRate: 16000,
      ),
      bufferSizeInSeconds: 20,
    );

    final recorder = AudioRecorder();
    final completer = Completer<void>();

    // Buffers
    final ringBuffer = <double>[];  // raw PCM before slicing into 512-sample frames
    final speechBuffer = <double>[]; // flat accumulator for the current utterance

    // State
    var inSpeech = false;
    var silenceFrameCount = 0;
    var overlapBuffer = Float32List(0);
    var lastVadSpeaking = false;

    final hardCapSamples = hardCapSeconds * 16000;
    final overlapSamples = (overlapMs / 1000.0 * 16000).toInt();
    // ~600 ms of consecutive silence frames to trigger end-of-utterance
    const silenceTriggerFrames = 19; // 19 × (512 / 16000) ≈ 0.61 s

    void handleBytes(Uint8List bytes) {
      if (!_running) return;

      ringBuffer.addAll(_bytesToFloat32(bytes));

      while (ringBuffer.length >= 512) {
        final frame = Float32List.fromList(ringBuffer.sublist(0, 512));
        ringBuffer.removeRange(0, 512);

        final energy = _rms(frame);
        final isLoud = energy >= rmsThreshold;

        // Only feed VAD high-energy frames to avoid noise false-positives
        if (isLoud) {
          vad.acceptWaveform(frame);
        }

        final speaking = isLoud && vad.isDetected();

        // Emit speaking state transitions for UI
        if (speaking != lastVadSpeaking) {
          lastVadSpeaking = speaking;
          if (!_vadStateController.isClosed) _vadStateController.add(speaking);
        }

        if (speaking) {
          if (!inSpeech) {
            // Start of a new utterance
            inSpeech = true;
            silenceFrameCount = 0;
            speechBuffer.clear();
            // Prepend acoustic overlap from previous hard-cap segment
            if (overlapBuffer.isNotEmpty) {
              speechBuffer.addAll(overlapBuffer);
              overlapBuffer = Float32List(0);
            }
          }
          speechBuffer.addAll(frame);
          silenceFrameCount = 0;
        } else if (inSpeech) {
          // Silence frame while still inside an utterance — keep accumulating
          speechBuffer.addAll(frame);
          silenceFrameCount++;

          // Trigger A: enough consecutive silence → end of utterance
          if (silenceFrameCount >= silenceTriggerFrames) {
            inSpeech = false;
            silenceFrameCount = 0;
            overlapBuffer = Float32List(0); // clean sentence end, no overlap needed
            final segment = Float32List.fromList(speechBuffer);
            speechBuffer.clear();
            unawaited(_processSegment(segment));
          }
        }

        // Trigger B: hard cap — force transcribe before buffer grows indefinitely
        if (inSpeech && speechBuffer.length >= hardCapSamples) {
          inSpeech = false;
          silenceFrameCount = 0;
          final all = Float32List.fromList(speechBuffer);
          final overlapStart = (all.length - overlapSamples).clamp(0, all.length);
          overlapBuffer = Float32List.fromList(all.sublist(overlapStart));
          speechBuffer.clear();
          unawaited(_processSegment(all));
        }
      }
    }

    try {
      final byteStream = await recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _streamSub = byteStream.listen(
        handleBytes,
        onError: (Object e) => debugPrint('PCM stream error: $e'),
        onDone: () { if (!completer.isCompleted) completer.complete(); },
      );

      await completer.future;
    } catch (e) {
      debugPrint('Record stream setup error: $e');
    } finally {
      await _streamSub?.cancel();
      _streamSub = null;

      // Flush any partially accumulated utterance on stop
      if (speechBuffer.isNotEmpty) {
        await _processSegment(Float32List.fromList(speechBuffer));
      }

      vad.free();
      await recorder.dispose();
    }
  }

  static Float32List _bytesToFloat32(Uint8List bytes) {
    final result = Float32List(bytes.length ~/ 2);
    for (int i = 0; i < result.length; i++) {
      final lo = bytes[i * 2];
      final hi = bytes[i * 2 + 1];
      int sample = (hi << 8) | lo;
      if (sample >= 32768) sample -= 65536; // two's complement
      result[i] = sample / 32768.0;
    }
    return result;
  }

  static double _rms(Float32List samples) {
    double sum = 0;
    for (final s in samples) { sum += s * s; }
    return sqrt(sum / samples.length);
  }

  Future<void> _processSegment(Float32List samples) async {
    // Ignore very short segments (< 200ms) — likely noise
    if (samples.length < 3200) return;

    final tempFile = File(
      '${Directory.systemTemp.path}/stt_speech_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    try {
      await _writeWav(tempFile.path, samples, 16000);
      final text = await compute(_transcribeChunk, {
        'wavPath': tempFile.path,
        'modelDir': _modelDir.path,
      });
      if (text.isNotEmpty && !_transcriptController.isClosed) {
        _transcriptController.add(text);
      }
    } catch (e) {
      debugPrint('Transcription error: $e');
    } finally {
      try {
        if (tempFile.existsSync()) await tempFile.delete();
      } catch (_) {}
    }
  }

  static Future<void> _writeWav(
    String path,
    Float32List samples,
    int sampleRate,
  ) async {
    final dataSize = samples.length * 2; // 16-bit PCM
    final header = ByteData(44);

    void setFourCC(int offset, String s) {
      for (int i = 0; i < 4; i++) {
        header.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    setFourCC(0, 'RIFF');
    header.setUint32(4, 36 + dataSize, Endian.little);
    setFourCC(8, 'WAVE');
    setFourCC(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);  // chunk size
    header.setUint16(20, 1, Endian.little);   // PCM
    header.setUint16(22, 1, Endian.little);   // mono
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little); // byteRate
    header.setUint16(32, 2, Endian.little);   // blockAlign
    header.setUint16(34, 16, Endian.little);  // bitsPerSample
    setFourCC(36, 'data');
    header.setUint32(40, dataSize, Endian.little);

    final pcmBytes = ByteData(dataSize);
    for (int i = 0; i < samples.length; i++) {
      final s = (samples[i] * 32767.0).clamp(-32768.0, 32767.0).toInt();
      pcmBytes.setInt16(i * 2, s, Endian.little);
    }

    await File(path).writeAsBytes([
      ...header.buffer.asUint8List(),
      ...pcmBytes.buffer.asUint8List(),
    ]);
  }
}

// Top-level function for compute() isolate — must not capture closures.
String _transcribeChunk(Map<String, String> args) {
  // Each isolate needs its own initBindings call.
  sherpa.initBindings();

  final wavPath = args['wavPath']!;
  final modelDir = args['modelDir']!;

  final config = sherpa.OfflineRecognizerConfig(
    model: sherpa.OfflineModelConfig(
      transducer: sherpa.OfflineTransducerModelConfig(
        encoder: '$modelDir/encoder.int8.onnx',
        decoder: '$modelDir/decoder.onnx',
        joiner: '$modelDir/joiner.int8.onnx',
      ),
      tokens: '$modelDir/tokens.txt',
      numThreads: 2,
      debug: false,
      provider: 'cpu',
    ),
  );

  final recognizer = sherpa.OfflineRecognizer(config);
  try {
    final wave = sherpa.readWave(wavPath);
    final stream = recognizer.createStream();
    stream.acceptWaveform(samples: wave.samples, sampleRate: wave.sampleRate);
    recognizer.decode(stream);
    final result = recognizer.getResult(stream);
    stream.free();
    return result.text.trim();
  } finally {
    recognizer.free();
  }
}
