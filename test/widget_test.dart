import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('completion threshold is 90%', () {
    expect(AppConstants.isLessonCompleted(90, 100), isTrue);
    expect(AppConstants.isLessonCompleted(89, 100), isFalse);
  });
}
