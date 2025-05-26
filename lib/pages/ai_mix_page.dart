import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../utils/responsive_helper.dart';

class AiMixPage extends StatefulWidget {
  const AiMixPage({super.key});

  @override
  State<AiMixPage> createState() => _AiMixPageState();
}

class _AiMixPageState extends State<AiMixPage> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  List<ClothingItem> _suggestedItems = [];
  
  final List<String> _recentPrompts = [
    'Trang phục mùa hè năng động',
    'Đồ công sở lịch sự',
    'Trang phục hẹn hò',
    'Phong cách đường phố',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _generateSuggestions() {
    if (_promptController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    // Parse the prompt for keywords
    final String prompt = _promptController.text.toLowerCase();
    final List<String> keywords = prompt.split(' ');

    // Filter items based on keywords matching style, occasion, season, etc.
    _suggestedItems = sampleClothingItems.where((item) {
      return keywords.any((keyword) =>
        item.style.toLowerCase().contains(keyword) ||
        item.occasions.any((occasion) => occasion.toLowerCase().contains(keyword)) ||
        item.season.toLowerCase().contains(keyword) ||
        item.color.toLowerCase().contains(keyword) ||
        item.category.toLowerCase().contains(keyword)
      );
    }).toList();

    setState(() {
      _isLoading = false;
      if (!_recentPrompts.contains(_promptController.text)) {
        _recentPrompts.insert(0, _promptController.text);
        if (_recentPrompts.length > 5) {
          _recentPrompts.removeLast();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final crossAxisCount = ResponsiveHelper.getCrossAxisCount(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mix Đồ Thông Minh'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: ResponsiveHelper.getScreenPadding(context),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ Lý Mix Đồ AI',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy mô tả phong cách bạn muốn, tôi sẽ gợi ý những món đồ phù hợp từ tủ đồ của bạn',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                if (isDesktop || isTablet)
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _promptController,
                          decoration: InputDecoration(
                            hintText: 'Ví dụ: "đồ mùa hè năng động" hoặc "trang phục công sở"',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                          ),
                          onSubmitted: (_) => _generateSuggestions(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _generateSuggestions,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: const Text('Tìm Kiếm'),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      TextField(
                        controller: _promptController,
                        decoration: InputDecoration(
                          hintText: 'Ví dụ: "đồ mùa hè năng động" hoặc "trang phục công sở"',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        onSubmitted: (_) => _generateSuggestions(),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _generateSuggestions,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: const Text('Tìm Kiếm'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Text(
                  'Tìm Kiếm Gần Đây',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _recentPrompts
                      .map(
                        (prompt) => ActionChip(
                          label: Text(prompt),
                          onPressed: () {
                            _promptController.text = prompt;
                            _generateSuggestions();
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _suggestedItems.isEmpty && _promptController.text.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nhập yêu cầu để nhận gợi ý trang phục',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      )
                    : _suggestedItems.isEmpty
                        ? Center(
                            child: Text(
                              'Không tìm thấy trang phục phù hợp trong tủ đồ của bạn',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          )
                        : GridView.builder(
                            padding: ResponsiveHelper.getScreenPadding(context),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 0.75,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                            ),
                            itemCount: _suggestedItems.length,
                            itemBuilder: (context, index) {
                              final item = _suggestedItems[index];
                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    // TODO: Show item details
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: NetworkImage(item.imageUrl),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: Theme.of(context).textTheme.titleSmall,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 4,
                                              children: [
                                                Chip(
                                                  label: Text(
                                                    item.style,
                                                    style: const TextStyle(fontSize: 10),
                                                  ),
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                                Chip(
                                                  label: Text(
                                                    item.category,
                                                    style: const TextStyle(fontSize: 10),
                                                  ),
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
} 