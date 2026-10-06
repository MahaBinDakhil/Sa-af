// lib/services/model_service.dart
//
// Talks to the Sa'af model server (Hugging Face Space).
//   ModelService.predict(photo)               -> fast result
//   ModelService.explain(photo, method: ...)  -> result + XAI images
//
// Needs the http package:  flutter pub add http
//
// ─────────────────────────────────────────────────────────────────────────
// HOW TO USE
//
//   // Scan button: fast result (no images)
//   final result = await ModelService.predict(photo);
//   result.diseaseName      // "Leaf Spots"
//   result.diseaseNameAr    // "تبقع الأوراق"
//   result.confidenceText   // "75%"
//   result.predictions      // top 3, for "How the AI decided"
//   result.lowConfidence    // true -> show "try a clearer photo"
//
//   // "View XAI Explanation" button
//   final xai = await ModelService.explain(photo);   // GradCAM++ by default
//   Image.memory(xai.heatmap!)                        // Heatmap tab
//   Image.memory(xai.region!)                         // Region tab (red outlines)
//
// XAI METHODS
//
//   Method       | Call                                          | Images
//   -------------|-----------------------------------------------|-----------------------------------------
//   GradCAM++    | explain(photo)                                | heatmap, region
//   Attention    | explain(photo, method: XaiMethod.attention)   | swinMap, effnetMap, disagreementMap
//   LIME (slow)  | explain(photo, method: XaiMethod.lime)        | limeBoundary, limeFill
//
// NOTES
//   - Healthy leaf: explain() returns no images (hasXai == false),
//     so hide the XAI button when result.isHealthy.
//   - Use JPG or PNG photos. HEIC (iPhone) photos are rejected by the server.
//   - The XAI images are PNG (~300 KB each): fine to show,
//     but do NOT save them inside Firestore documents (1 MB limit).
// ─────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// The 3 XAI methods the server supports.
enum XaiMethod {
  gradcamPP('GradCAM++'),   // images: heatmap, contours          (fast)
  attention('attention'),   // images: swin, effnet, disagreement (fast)
  lime('lime');             // images: boundary, fill             (slow)

  final String apiName;
  const XaiMethod(this.apiName);
}

class ModelService {
  static const String baseUrl = 'https://anfalalobeid-palm-disease-api.hf.space';

  /// Wakes the server up (Spaces sleep when unused).
  /// Call this when the app opens, so the first scan is faster.
  static Future<void> wakeUp() async {
    try {
      await http.get(Uri.parse('$baseUrl/')).timeout(const Duration(seconds: 60));
    } catch (_) {}
  }

  /// Fast prediction: disease, confidence, probabilities. No images.
  static Future<ScanResult> predict(File image) async {
    return _send(Uri.parse('$baseUrl/predict'), image, const Duration(seconds: 120));
  }

  /// Prediction + XAI images.
  /// For a healthy leaf the server returns no images (result.hasXai == false).
  /// [limeSamples] is only used by XaiMethod.lime (50..1000; more = slower).
  static Future<ScanResult> explain(
    File image, {
    XaiMethod method = XaiMethod.gradcamPP,
    int limeSamples = 150,
  }) async {
    final uri = Uri.parse('$baseUrl/explain').replace(queryParameters: {
      'method': method.apiName,          // "+" is encoded as %2B automatically
      'lime_samples': '$limeSamples',
    });
    return _send(uri, image, const Duration(seconds: 300));
  }

  static Future<ScanResult> _send(Uri uri, File image, Duration timeout) async {
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final streamed = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 400) {
      throw Exception('Invalid image. Please use a JPG or PNG photo.');
    }
    if (response.statusCode != 200) {
      throw Exception('Server error (${response.statusCode}): ${response.body}');
    }
    return ScanResult.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
  }
}

/// Display names for each class id (same ids as the Firestore "diseases" collection).
const Map<String, String> diseaseNames = {
  'potassium_deficiency': 'Potassium Deficiency',
  'manganese_deficiency': 'Manganese Deficiency',
  'magnesium_deficiency': 'Magnesium Deficiency',
  'black_scorch': 'Black Scorch',
  'leaf_spots': 'Leaf Spots',
  'fusarium_wilt': 'Fusarium Wilt',
  'rachis_blight': 'Rachis Blight',
  'parlatoria_blanchardi': 'Parlatoria Blanchardi',
  'healthy': 'Healthy',
};

class Prediction {
  final String name;
  final double score;
  Prediction(this.name, this.score);

  String get scoreText => '${(score * 100).round()}%';
  Map<String, dynamic> toMap() => {'name': name, 'score': score};
}

class ScanResult {
  // ---- prediction (from /predict and /explain) ----
  final String status;            // "healthy" or "diseased"
  final String diseaseId;         // e.g. "leaf_spots" -> diseases/{diseaseId}
  final String diseaseName;       // e.g. "Leaf Spots"
  final String diseaseNameAr;     // e.g. "تبقع الأوراق"
  final double confidence;        // 0..1  (0.75 = 75%)
  final bool lowConfidence;       // true = ask the user for a clearer photo
  final double pDiseased;         // Head A: probability the leaf is diseased
  final List<Prediction> predictions; // top 3, highest first

  // ---- XAI (only from /explain) ----
  final String xaiMethod;         // "GradCAM++", "attention" or "lime"
  final Map<String, Uint8List> images; // every image the server sent, by name
  final double? branchCorrelation;     // attention only: Swin vs EffNet agreement
  final double? xaiSeconds;            // how long the explanation took
  final String? note;                  // e.g. "healthy leaf - nothing to explain"

  ScanResult({
    required this.status,
    required this.diseaseId,
    required this.diseaseName,
    required this.diseaseNameAr,
    required this.confidence,
    required this.lowConfidence,
    required this.pDiseased,
    required this.predictions,
    this.xaiMethod = '',
    this.images = const {},
    this.branchCorrelation,
    this.xaiSeconds,
    this.note,
  });

  bool get isHealthy => status == 'healthy';
  bool get hasXai => images.isNotEmpty;
  String get confidenceText => '${(confidence * 100).round()}%';

  // ---- GradCAM++ images (the Figma "Heatmap" and "Region" tabs) ----
  Uint8List? get heatmap => images['heatmap'];
  Uint8List? get region => images['contours'];

  // ---- attention images ----
  Uint8List? get swinMap => images['swin'];
  Uint8List? get effnetMap => images['effnet'];
  Uint8List? get disagreementMap => images['disagreement'];

  // ---- LIME images ----
  Uint8List? get limeBoundary => images['boundary'];
  Uint8List? get limeFill => images['fill'];

  factory ScanResult.fromJson(Map<String, dynamic> j) {
    final label = (j['label'] ?? '').toString();
    final healthy = j['is_healthy'] == true || label == 'healthy';
    final pDiseased = (j['p_diseased'] as num?)?.toDouble() ?? 0.0;

    // disease_probabilities -> sorted, highest first
    final probs = (j['disease_probabilities'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
    final sorted = probs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final predictions = <Prediction>[];
    if (healthy) predictions.add(Prediction('Healthy', 1.0 - pDiseased));
    for (final e in sorted.take(healthy ? 2 : 3)) {
      predictions.add(Prediction(diseaseNames[e.key] ?? e.key, e.value));
    }

    // XAI images: base64 PNG strings -> bytes
    final images = <String, Uint8List>{};
    (j['images'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      if (v is String && v.isNotEmpty) images[k] = base64Decode(v);
    });

    return ScanResult(
      status: healthy ? 'healthy' : 'diseased',
      diseaseId: healthy ? 'healthy' : label,
      diseaseName: diseaseNames[label] ?? label,
      diseaseNameAr: (j['label_ar'] ?? '').toString(),
      confidence: (j['confidence'] as num?)?.toDouble() ?? 0.0,
      lowConfidence: j['low_confidence'] == true,
      pDiseased: pDiseased,
      predictions: predictions,
      xaiMethod: (j['method'] ?? '').toString(),
      images: images,
      branchCorrelation: (j['branch_attention_correlation'] as num?)?.toDouble(),
      xaiSeconds: (j['seconds'] as num?)?.toDouble(),
      note: j['note']?.toString(),
    );
  }

  /// Ready to save in Firestore: users/{uid}/scans/{scanId}
  /// (add imageUrl, heatmapUrl, regionUrl and createdAt when saving)
  Map<String, dynamic> toFirestore() => {
        'status': status,
        'diseaseId': diseaseId,
        'diseaseName': diseaseName,
        'confidence': confidence,
        'predictions': predictions.map((p) => p.toMap()).toList(),
      };
}