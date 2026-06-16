import 'package:flutter/material.dart';

import '../models/item.dart';
import '../models/order_item.dart';

class BoardPage extends StatelessWidget {
  final List<OrderItem> orders;

  const BoardPage({
    super.key,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    final boardOrders = orders.where(
      (o) =>
          o.quantity > 0 &&
          o.item.orderType == OrderType.part,
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホワイトボード記入'),
      ),

      body: ListView.builder(
        itemCount: boardOrders.length,

        itemBuilder: (context, index) {
          final order = boardOrders[index];

          final quantityText =
              order.quantity == 0.5
                  ? '1/2'
                  : order.quantity.toStringAsFixed(
                      order.quantity ==
                              order.quantity.toInt()
                          ? 0
                          : 1,
                    );

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            child: Text(
              '${order.item.name} × $quantityText',
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
          );
        },
      ),
    );
  }
}