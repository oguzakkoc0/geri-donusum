import 'package:flutter/material.dart';

class WeeklyChart extends StatelessWidget {
  final List<int> weeklyPoints;

  const WeeklyChart({super.key, required this.weeklyPoints});

  @override
  Widget build(BuildContext context) {
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final point = weeklyPoints.length > index ? weeklyPoints[index] : 0;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(point.toString()),
                const SizedBox(height: 4),
                Container(
                  height: point.toDouble() * 2,
                  width: 16,
                  decoration: BoxDecoration(
                    color: Colors.green[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(days[index]),
              ],
            ),
          );
        }),
      ),
    );
  }
}
