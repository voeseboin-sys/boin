import 'package:flutter/material.dart';
import '../core/core.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool isLarge;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.backgroundColor,
    this.onTap,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppTheme.primaryColor;
    final bgColor = backgroundColor ?? AppTheme.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 20 : 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cardColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: cardColor,
                    size: isLarge ? 24 : 20,
                  ),
                ),
                const Spacer(),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.textTertiary,
                    size: 14,
                  ),
              ],
            ),
            SizedBox(height: isLarge ? 16 : 12),
            Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: isLarge ? 24 : 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: isLarge ? 14 : 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class MetricCardGrid extends StatelessWidget {
  final List<MetricCardData> metrics;

  const MetricCardGrid({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return MetricCard(
          title: metric.title,
          value: metric.value,
          icon: metric.icon,
          color: metric.color,
          onTap: metric.onTap,
        );
      },
    );
  }
}

class MetricCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  MetricCardData({
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });
}
