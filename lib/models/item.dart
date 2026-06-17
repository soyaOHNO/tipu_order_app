enum OrderType {
  part,
  chief,
  owner,
  regular,
  preparation,
}

class Item {
  final int id;
  final String name;
  final String minimum;
  final String category;
  final String supplier;
  final OrderType orderType;
  final bool alive;

  const Item({
    required this.id,
    required this.name,
    required this.minimum,
    required this.category,
    required this.supplier,
    required this.orderType,
    this.alive = true,
  });
}