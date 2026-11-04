import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const FaceDetectionApp());
}

int calculateSmilingPercentage({
  required int smilingFaces,
  required int totalFaces,
}) {
  if (totalFaces == 0) return 0;
  return ((smilingFaces / totalFaces) * 100).round();
}

class FaceDetectionApp extends StatelessWidget {
  const FaceDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF087F70);
    return MaterialApp(
      title: 'Face Detection & Smile Analysis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          surface: const Color(0xFFF5F8F7),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F8F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F8F7),
          foregroundColor: Color(0xFF162421),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE6ECE9)),
          ),
        ),
      ),
      home: const FaceAnalysisPage(),
    );
  }
}

class FaceAnalysisPage extends StatefulWidget {
  const FaceAnalysisPage({super.key});

  @override
  State<FaceAnalysisPage> createState() => _FaceAnalysisPageState();
}

class _FaceAnalysisPageState extends State<FaceAnalysisPage> {
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _imageBytes;
  Size? _imageSize;
  List<FaceAnalysis> _faces = [];
  bool _isBusy = false;

  int get _smilingCount => _faces.where((face) => face.isSmiling).length;

  Future<void> _pickAndAnalyzeImage() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        if (mounted) setState(() => _isBusy = false);
        return;
      }

      final bytes = await image.readAsBytes();
      final imageSize = await _getImageSize(bytes);
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageSize = imageSize;
        _faces = [];
      });

      final detector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );
      try {
        final detectedFaces = await detector.processImage(
          InputImage.fromFilePath(image.path),
        );
        if (!mounted) return;
        setState(() {
          _faces = detectedFaces.map(FaceAnalysis.fromFace).toList();
        });
      } finally {
        await detector.close();
      }
    } on PlatformException catch (error) {
      _showError(
        'Could not access the gallery or analyze this image: '
        '${error.message ?? error.code}',
      );
    } on Exception catch (error) {
      _showError('Could not analyze this image: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<Size> _getImageSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      final size = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      return size;
    } finally {
      codec.dispose();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final faces = _faces;
    final smilePercent = calculateSmilingPercentage(
      smilingFaces: _smilingCount,
      totalFaces: faces.length,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Face Detection & Smile Analysis',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              'AI VISION STUDIO',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF087F70),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A closer look at every smile.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF162421),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const ValueKey('upload-image-button'),
              onPressed: _isBusy ? null : _pickAndAnalyzeImage,
              icon: _isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _isBusy
                    ? (_imageBytes == null
                          ? 'Opening gallery...'
                          : 'Analyzing image...')
                    : _imageBytes == null
                    ? 'Upload Image'
                    : 'Upload Another Image',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: const Color(0xFF087F70),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 22),
            if (_imageBytes == null)
              const _EmptyImageCard()
            else ...[
              _SectionHeading(
                title: 'Uploaded image',
                trailing: _isBusy
                    ? 'Analyzing'
                    : '${faces.length} ${faces.length == 1 ? 'face' : 'faces'}',
              ),
              const SizedBox(height: 10),
              _ImagePreview(
                imageBytes: _imageBytes!,
                imageSize: _imageSize!,
                faces: faces,
              ),
              const SizedBox(height: 22),
              const _SectionHeading(title: 'Image analytics'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.face_retouching_natural,
                      label: 'Total faces',
                      value: '${faces.length}',
                      detail: faces.isEmpty
                          ? 'No faces found'
                          : 'In this image',
                      color: const Color(0xFF087F70),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.sentiment_satisfied_alt,
                      label: 'Smiling',
                      value: '$smilePercent%',
                      detail: 'of detected faces',
                      color: const Color(0xFFD58B20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _SectionHeading(title: 'Individual face information'),
              const SizedBox(height: 10),
              if (_isBusy && faces.isEmpty)
                const _InfoCard(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Detecting faces and analyzing smiles...'),
                    ],
                  ),
                )
              else if (faces.isEmpty)
                const _InfoCard(
                  child: Text(
                    'No faces were detected. Try an image with clear, '
                    'front-facing people.',
                    style: TextStyle(color: Color(0xFF63716D), height: 1.5),
                  ),
                )
              else
                ...List.generate(
                  faces.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FaceInfoCard(
                      faceNumber: index + 1,
                      face: faces[index],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class FaceAnalysis {
  const FaceAnalysis({required this.bounds, required this.smileProbability});

  factory FaceAnalysis.fromFace(Face face) => FaceAnalysis(
    bounds: face.boundingBox,
    smileProbability: (face.smilingProbability ?? 0).clamp(0, 1).toDouble(),
  );

  final Rect bounds;
  final double smileProbability;

  bool get isSmiling => smileProbability >= 0.7;
}

class _EmptyImageCard extends StatelessWidget {
  const _EmptyImageCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              radius: 34,
              backgroundColor: Color(0xFFE7F3F0),
              child: Icon(
                Icons.image_search_outlined,
                size: 32,
                color: Color(0xFF087F70),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Your image goes here',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF20302C),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Choose a photo to find faces and measure smiles.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF63716D), height: 1.4),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF20302C),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              color: Color(0xFF63716D),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.imageBytes,
    required this.imageSize,
    required this.faces,
  });

  final Uint8List imageBytes;
  final Size imageSize;
  final List<FaceAnalysis> faces;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / imageSize.width).clamp(
          0.0,
          360 / imageSize.height,
        );
        final displayWidth = imageSize.width * scale;
        final displayHeight = imageSize.height * scale;
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: displayWidth,
              height: displayHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(imageBytes, fit: BoxFit.fill),
                  CustomPaint(
                    painter: _FaceBoundsPainter(
                      faces: faces,
                      imageSize: imageSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FaceBoundsPainter extends CustomPainter {
  const _FaceBoundsPainter({required this.faces, required this.imageSize});

  final List<FaceAnalysis> faces;
  final Size imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    final borderPaint = Paint()
      ..color = const Color(0xFF59F0BB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (var index = 0; index < faces.length; index++) {
      final face = faces[index];
      final rect = Rect.fromLTRB(
        face.bounds.left * scaleX,
        face.bounds.top * scaleY,
        face.bounds.right * scaleX,
        face.bounds.bottom * scaleY,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        borderPaint,
      );

      final label = TextPainter(
        text: TextSpan(
          text: 'Face ${index + 1}',
          style: const TextStyle(
            color: Color(0xFF10251F),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelRect = Rect.fromLTWH(
        rect.left,
        (rect.top - label.height - 8).clamp(0, size.height).toDouble(),
        label.width + 12,
        label.height + 6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(5)),
        Paint()..color = const Color(0xFF59F0BB),
      );
      label.paint(canvas, labelRect.topLeft + const Offset(6, 3));
    }
  }

  @override
  bool shouldRepaint(_FaceBoundsPainter oldDelegate) =>
      oldDelegate.faces != faces || oldDelegate.imageSize != imageSize;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 21, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF162421),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF20302C),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF7A8783), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _FaceInfoCard extends StatelessWidget {
  const _FaceInfoCard({required this.faceNumber, required this.face});

  final int faceNumber;
  final FaceAnalysis face;

  @override
  Widget build(BuildContext context) {
    final statusColor = face.isSmiling
        ? const Color(0xFF087F70)
        : const Color(0xFF697570);

    return _InfoCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE7F3F0),
            child: Text(
              '$faceNumber',
              style: const TextStyle(
                color: Color(0xFF087F70),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Face $faceNumber',
                  style: const TextStyle(
                    color: Color(0xFF20302C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  face.isSmiling ? 'Smiling' : 'Not smiling',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(face.smileProbability * 100).round()}%',
                style: const TextStyle(
                  color: Color(0xFF20302C),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'smile probability',
                style: TextStyle(color: Color(0xFF7A8783), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
