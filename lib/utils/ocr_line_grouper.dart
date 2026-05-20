import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class _OcrLine {
  const _OcrLine(this.text, this.top, this.left, this.height);

  final String text;
  final double top;
  final double left;
  final double height;
}

double _rowClusterThreshold(List<_OcrLine> lines) {
  if (lines.isEmpty) return 14;
  final heights = lines.map((l) => l.height).where((h) => h > 2).toList()..sort();
  if (heights.isEmpty) return 14;
  final median = heights[heights.length ~/ 2];
  return (median * 0.62).clamp(12.0, 36.0);
}

/// Groups ML Kit lines by vertical position so enrolment table rows stay intact.
String groupRecognizedTextIntoRows(RecognizedText recognized) {
  final lines = <_OcrLine>[];
  for (final block in recognized.blocks) {
    for (final line in block.lines) {
      final text = line.text.trim();
      if (text.isEmpty) continue;
      final box = line.boundingBox;
      lines.add(_OcrLine(text, box.top, box.left, box.height));
    }
  }

  if (lines.isEmpty) return recognized.text.trim();

  final threshold = _rowClusterThreshold(lines);
  lines.sort((a, b) {
    final rowDelta = (a.top - b.top).abs();
    if (rowDelta > threshold) return a.top.compareTo(b.top);
    final leftDelta = (a.left - b.left).abs();
    if (leftDelta > 80) return a.left.compareTo(b.left);
    return a.top.compareTo(b.top);
  });

  final rows = <String>[];
  final buffer = StringBuffer();
  double? rowTop;

  for (final line in lines) {
    final newRow = rowTop == null || (line.top - rowTop).abs() > threshold;
    if (newRow) {
      if (buffer.isNotEmpty) {
        rows.add(buffer.toString().trim());
        buffer.clear();
      }
      rowTop = line.top;
    } else if (buffer.isNotEmpty) {
      buffer.write(' ');
    }
    buffer.write(line.text);
  }
  if (buffer.isNotEmpty) rows.add(buffer.toString().trim());

  final joined = rows.join('\n');
  return joined.isNotEmpty ? joined : recognized.text.trim();
}
