import 'package:flutter_test/flutter_test.dart';
import 'package:whack_a_word_ham/models/accessory_model.dart';
import 'package:whack_a_word_ham/services/player_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('WardrobeCatalog defines 6 items matching avatar_shop.py', () {
    expect(WardrobeCatalog.accessories.length, equals(6));
    expect(WardrobeCatalog.findById('cap')?.price, equals(30));
    expect(WardrobeCatalog.findById('glasses')?.price, equals(50));
    expect(WardrobeCatalog.findById('headphones')?.price, equals(80));
    expect(WardrobeCatalog.findById('ninja_mask')?.price, equals(100));
    expect(WardrobeCatalog.findById('crown')?.price, equals(150));
    expect(WardrobeCatalog.findById('wizard_hat')?.price, equals(200));
  });

  test('PlayerDataService default stage and coins match player_data.json', () {
    final player = PlayerDataService.instance;
    expect(player.currentStage, equals(16));
    expect(player.coins, equals(94));
    expect(player.equippedAccessory, equals('glasses'));
  });
}
