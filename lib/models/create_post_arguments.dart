import 'dart:typed_data';

class FilterSelectionArguments {
  const FilterSelectionArguments({
    required this.imageBytes,
    required this.fileName,
  });

  final Uint8List imageBytes;
  final String fileName;
}

class PublishPostArguments {
  const PublishPostArguments({
    required this.processedImageUrl,
    required this.fileName,
    this.originalImageUrl,
    this.selectedFilter,
    this.maskValue,
  });

  final String processedImageUrl;
  final String fileName;
  final String? originalImageUrl;
  final String? selectedFilter;
  final int? maskValue;
}
