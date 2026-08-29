import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:microlend/store/offline_store.dart';
import 'package:microlend/store/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppState import/export', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('exports and imports json data correctly', () async {
      final store = await OfflineStore.init();
      final appState = AppState(store);

      expect(appState.borrowers.length, 3);
      expect(appState.loans.length, 3);

      final exportedJson = appState.exportDataJson();

      await appState.clearAllData();
      expect(appState.borrowers.length, 0);
      expect(appState.loans.length, 0);

      await appState.importDataJson(exportedJson);
      expect(appState.borrowers.length, 3);
      expect(appState.loans.length, 3);
    });

    test('throws FormatException on malformed json import', () async {
      final store = await OfflineStore.init();
      final appState = AppState(store);

      expect(
        () => appState.importDataJson('{"invalid": true}'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
