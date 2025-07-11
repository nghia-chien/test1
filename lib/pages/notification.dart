// notification_panel.dart
import 'package:flutter/material.dart';

class NotificationPanel extends StatelessWidget {
  const NotificationPanel({super.key});

  final List<String> sampleNotifications = const [
    'Lan đã theo dõi bạn',
    'Lan đã bình luận bài đăng của bạn',
    'Hùng vừa đăng bài viết mới',
    'Bạn có 2 lời mời kết bạn mới',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thông báo mới',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                )
              ],
            ),
            const SizedBox(height: 8),
            ...sampleNotifications.map((message) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    height: 44,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      message,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey.shade800),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
