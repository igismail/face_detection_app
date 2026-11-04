import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';

import 'package:face_detection_app/main.dart';

void main() {
  testWidgets('shows upload prompt and initial screen requirements', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FaceDetectionApp());

    expect(find.text('Face Detection & Smile Analysis'), findsOneWidget);
    expect(find.text('Upload Image'), findsOneWidget);
    expect(find.text('Your image goes here'), findsOneWidget);
  });

  test('smiling percentage rounds correctly and empty images return zero', () {
    expect(calculateSmilingPercentage(smilingFaces: 3, totalFaces: 4), 75);
    expect(calculateSmilingPercentage(smilingFaces: 0, totalFaces: 0), 0);
  });

  test('a smile is classified at a probability of 70% or higher', () {
    const bounds = Rect.fromLTWH(0, 0, 20, 20);
    expect(
      const FaceAnalysis(bounds: bounds, smileProbability: 0.7).isSmiling,
      isTrue,
    );
    expect(
      const FaceAnalysis(bounds: bounds, smileProbability: 0.69).isSmiling,
      isFalse,
    );
  });
}
