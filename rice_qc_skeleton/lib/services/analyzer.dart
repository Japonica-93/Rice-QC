import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../data/labels.dart';
import '../main.dart';

class Detection {
  final Rect box; // normalized [0,1] coords
  final String label;
  final double score;
  Detection(this.box, this.label, this.score);
}

class Analyzer {
  Interpreter? _interpreter;
  bool _mockMode = false;

  Analyzer();

  Future<void> _ensureModelLoaded() async {
    if (_interpreter != null || _mockMode) return;
    try {
      // attempt to load from asset. If not present, fall back to mock mode
      await rootBundle.load('assets/model/rice_qc.tflite');
      _interpreter = await Interpreter.fromAsset('assets/model/rice_qc.tflite');
    } catch (_) {
      _mockMode = true;
    }
  }

  Future<List<Detection>> analyze(File imageFile, SampleType type) async {
    await _ensureModelLoaded();
    if (_mockMode) {
      // generate deterministic pseudo detections based on file length hash
      final r = Random(imageFile.path.hashCode);
      final labels = type == SampleType.rice ? riceLabels : paddyLabels;
      final n = 20 + r.nextInt(30);
      final List<Detection> out = [];
      for (int i = 0; i < n; i++) {
        final x = r.nextDouble() * 0.8;
        final y = r.nextDouble() * 0.8;
        final w = 0.1 + r.nextDouble() * 0.15;
        final h = 0.04 + r.nextDouble() * 0.08;
        final isDefect = r.nextDouble() < 0.2;
        final label = isDefect ? labels[r.nextInt(max(1, labels.length - 1)) + 1] : labels[0];
        final score = 0.5 + r.nextDouble() * 0.5;
        out.add(Detection(Rect.fromLTWH(x, y, w, h), label, score));
      }
      return out;
    }

    // TODO: implement real preprocessing and inference
    // For now, fallback to mock to keep app usable
    _mockMode = true;
    return analyze(imageFile, type);
  }
}
