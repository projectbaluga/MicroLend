import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:microlend/store/offline_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('seeds 3 borrowers and 3 loans when empty', () async {
      final store = await OfflineStore.init();
      final borrowers = store.getCollection('borrowers');
      final loans = store.getCollection('loans');

      expect(borrowers.length, 3);
      expect(loans.length, 3);
    });

    test('performs CRUD and updates write queue', () async {
      final store = await OfflineStore.init();
      final newItem = await store.addItem('borrowers', {
        'full_name': 'Test User',
        'monthly_income': 5000.0,
      });

      expect(newItem['id'], isNotNull);
      final list = store.getCollection('borrowers');
      expect(list.length, 4);

      await store.updateItem('borrowers', newItem['id'], {'full_name': 'Updated User'});
      final updatedList = store.getCollection('borrowers');
      final updatedUser = updatedList.firstWhere((b) => b['id'] == newItem['id']);
      expect(updatedUser['full_name'], 'Updated User');

      await store.deleteItem('borrowers', newItem['id']);
      final finalCount = store.getCollection('borrowers').length;
      expect(finalCount, 3);

      final queue = store.getQueue();
      expect(queue.length, greaterThanOrEqualTo(3));

      final syncResult = await store.syncAll();
      expect(syncResult['success'], true);
      expect(store.getQueue().length, 0);
    });
  });
}
