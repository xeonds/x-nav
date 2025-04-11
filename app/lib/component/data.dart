// 数据展示控件合集
import 'package:flutter/material.dart';

// statistic统计组件
// 用于突出某个或者某组数据
class Statistic extends StatelessWidget {
  final String data;
  final String? label;
  final String subtitle;

  const Statistic({
    super.key,
    required this.data,
    this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              data,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}
