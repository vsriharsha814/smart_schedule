import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Phase III: On-device text extraction (printed/handwriting, Latin-first).
///
/// This is a thin wrapper around Google ML Kit's TextRecognizer. It operates
/// entirely on-device and returns the raw recognized text for a given image.
class MlkitTextExtractor {
  MlkitTextExtractor._();

  static final MlkitTextExtractor instance = MlkitTextExtractor._();

  /// Extracts all recognized text from an image file path.
  /// Returns null if nothing was recognized or an error occurred.
  Future<String?> extractTextFromImageFile(File file) async {
    try {
      final inputImage = InputImage.fromFile(file);
      final recognizer =
          TextRecognizer(script: TextRecognitionScript.latin); // printed + handwriting (Latin)

      final recognized = await recognizer.processImage(inputImage);
      await recognizer.close();

      final text = recognized.text.trim();
      if (text.isEmpty) return null;
      return text;
    } catch (_) {
      // We keep failures silent for now and just return null.
      return null;
    }
  }
}

