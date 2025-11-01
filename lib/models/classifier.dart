import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class WasteClassifier {
  static const String modelPath = 'assets/model.tflite';
  static const String labelsPath = 'assets/labels.txt';
  static const int inputSize = 224;
  
  Interpreter? _interpreter;
  List<String>? _labels;
  
  bool get isInitialized => _interpreter != null && _labels != null;

  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      print('✅ Model loaded successfully');
      
      final labelsData = await rootBundle.loadString(labelsPath);
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      print('✅ Labels loaded: $_labels');
      
    } catch (e) {
      print('❌ Error loading model: $e');
      rethrow;
    }
  }

  Future<ClassificationResult> classifyImage(File imageFile) async {
    if (!isInitialized) {
      throw Exception('Model not initialized. Call initialize() first.');
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final input = _preprocessImage(image);
      final output = List.filled(1 * 2, 0.0).reshape([1, 2]);
      _interpreter!.run(input, output);
      
      final probabilities = output[0] as List<double>;
      final maxIndex = probabilities.indexOf(probabilities.reduce((a, b) => a > b ? a : b));
      final confidence = probabilities[maxIndex];
      final label = _labels![maxIndex];
      
      // DEBUG: Print probabilities
      print('🔍 PROBABILITIES:');
      print('   Index 0 (${_labels![0]}): ${(probabilities[0] * 100).toStringAsFixed(2)}%');
      print('   Index 1 (${_labels![1]}): ${(probabilities[1] * 100).toStringAsFixed(2)}%');
      print('   Predicted: $label (index: $maxIndex)');
      
      return ClassificationResult(
        label: label,
        confidence: confidence,
        probabilities: probabilities,
      );
      
    } catch (e) {
      print('❌ Classification error: $e');
      rethrow;
    }
  }

  Future<ClassificationResult> classifyImageBytes(Uint8List bytes) async {
    if (!isInitialized) {
      throw Exception('Model not initialized');
    }

    try {
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final input = _preprocessImage(image);
      final output = List.filled(1 * 2, 0.0).reshape([1, 2]);
      _interpreter!.run(input, output);
      
      final probabilities = output[0] as List<double>;
      final maxIndex = probabilities.indexOf(probabilities.reduce((a, b) => a > b ? a : b));
      final confidence = probabilities[maxIndex];
      final label = _labels![maxIndex];
      
      // DEBUG: Print probabilities
      print('🔍 PROBABILITIES (Bytes):');
      print('   Index 0 (${_labels![0]}): ${(probabilities[0] * 100).toStringAsFixed(2)}%');
      print('   Index 1 (${_labels![1]}): ${(probabilities[1] * 100).toStringAsFixed(2)}%');
      print('   Predicted: $label (index: $maxIndex)');
      
      return ClassificationResult(
        label: label,
        confidence: confidence,
        probabilities: probabilities,
      );
      
    } catch (e) {
      print('❌ Classification error: $e');
      rethrow;
    }
  }

  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    final input = List.generate(
      1,
      (b) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            // MobileNetV2 preprocessing: normalize to [-1, 1]
            return [
              (pixel.r / 127.5) - 1,
              (pixel.g / 127.5) - 1,
              (pixel.b / 127.5) - 1,
            ];
          },
        ),
      ),
    );

    return input;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
  }
}

class ClassificationResult {
  final String label;
  final double confidence;
  final List<double> probabilities;

  ClassificationResult({
    required this.label,
    required this.confidence,
    required this.probabilities,
  });

  String get displayLabel {
    if (label == 'O' || label.toLowerCase().contains('organik')) {
      return 'Organik';
    } else {
      return 'Anorganik';
    }
  }
  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';
  
  bool get isOrganic => label == 'O' || label.toLowerCase().contains('organik');
  bool get isAnorganic => label == 'R' || label.toLowerCase().contains('anorganik') || label.toLowerCase().contains('recyclable');
  
  @override
  String toString() {
    return 'ClassificationResult(label: $label, confidence: $confidencePercentage)';
  }
}