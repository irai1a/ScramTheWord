class Accessory {
  final String id;
  final String name;
  final String description;
  final int price;
  final String assetName;

  const Accessory({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.assetName,
  });
}

class WardrobeCatalog {
  static const List<Accessory> accessories = [
    Accessory(
      id: 'cap',
      name: 'Cap',
      description: 'Trendy red snapback cap',
      price: 30,
      assetName: 'cap.png',
    ),
    Accessory(
      id: 'glasses',
      name: 'Glasses',
      description: 'Cool golden pixel shades',
      price: 50,
      assetName: 'glasses.png',
    ),
    Accessory(
      id: 'headphones',
      name: 'Headphones',
      description: 'Neon cyan gaming headset',
      price: 80,
      assetName: 'headphones.png',
    ),
    Accessory(
      id: 'ninja_mask',
      name: 'Ninja Mask',
      description: 'Stealth rogue face mask',
      price: 100,
      assetName: 'ninja_mask.png',
    ),
    Accessory(
      id: 'crown',
      name: 'Crown',
      description: 'Royal golden jeweled crown',
      price: 150,
      assetName: 'crown.png',
    ),
    Accessory(
      id: 'wizard_hat',
      name: 'Wizard Hat',
      description: 'Enchanted celestial hat',
      price: 200,
      assetName: 'wizard_hat.png',
    ),
  ];

  static Accessory? findById(String id) {
    if (id == 'empty') return null;
    try {
      return accessories.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
