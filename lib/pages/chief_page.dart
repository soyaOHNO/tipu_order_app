import 'package:flutter/material.dart';

import '../models/item.dart';
import '../models/order_item.dart';

class ChiefPage extends StatelessWidget {
  final List<OrderItem> orders;
  

  const ChiefPage({
    super.key,
    required this.orders,
  });
  

  @override
  Widget build(BuildContext context) {
    final chiefOrders = orders.where(
      (o) =>
          o.quantity > 0 &&
          o.item.orderType == OrderType.chief,
    ).toList();

    final ownerOrders = orders.where(
      (o) =>
          o.quantity > 0 &&
          o.item.orderType == OrderType.owner,
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('発注確認'),
      ),

      body: ListView(
        children: [
        
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '発注',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      
          ...chiefOrders.map(
            (order) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              child: Text(
                '${order.item.name} × '
                '${order.quantity == 0.5 ? '1/2' : order.quantity.toStringAsFixed(
                  order.quantity == order.quantity.toInt() ? 0 : 1,
                )}',
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ),
      
          const Divider(),
      
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'とも兄さんにお願いするもの',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      
          ...ownerOrders.map(
            (order) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              child: Text(
                '${order.item.name} × '
                '${order.quantity == 0.5 ? '1/2' : order.quantity.toStringAsFixed(
                  order.quantity == order.quantity.toInt() ? 0 : 1,
                )}',
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}