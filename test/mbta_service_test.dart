import 'package:flutter_test/flutter_test.dart';
import 'package:yathrikan/services/mbta_service.dart';

void main() {
  test('verify fetchVehicles', () async {
    final res = await MbtaService.fetchVehicles();
    expect(res, isNotEmpty);
  });
}
