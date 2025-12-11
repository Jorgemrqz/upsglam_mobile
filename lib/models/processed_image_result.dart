class ProcessedImageResult {
  const ProcessedImageResult({
    required this.originalUrl,
    required this.processedUrl,
  });

  final String? originalUrl;
  final String? processedUrl;

  factory ProcessedImageResult.fromJson(Map<String, dynamic> json) {
    return ProcessedImageResult(
      originalUrl: (json['originalUrl'] as String?)?.trim(),
      processedUrl: (json['processedUrl'] as String?)?.trim(),
    );
  }

  bool get hasProcessedUrl => processedUrl != null && processedUrl!.isNotEmpty;
}
