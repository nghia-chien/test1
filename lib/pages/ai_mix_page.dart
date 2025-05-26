import 'package:flutter/material.dart';

class AiMixPage extends StatefulWidget {
  const AiMixPage({super.key});

  @override
  State<AiMixPage> createState() => _AiMixPageState();
}

class _AiMixPageState extends State<AiMixPage> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  List<String> _generatedOutfits = [];
  
  final List<String> _recentPrompts = [
    'Summer casual outfit',
    'Business formal attire',
    'Date night look',
    'Street style fashion',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _generateOutfit() {
    if (_promptController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    // TODO: Implement actual AI generation logic
    // This is just a mock response
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
        _generatedOutfits.insert(0, 'Generated outfit for: ${_promptController.text}');
        _promptController.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Fashion Mix'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
                  'Create Your Perfect Outfit',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        decoration: InputDecoration(
                          hintText: 'Describe your desired outfit...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _generateOutfit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Recent Prompts',
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
                : _generatedOutfits.isEmpty
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
                              'Your AI-generated outfits will appear here',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _generatedOutfits.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.auto_awesome),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _generatedOutfits[index],
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.favorite_border),
                                        onPressed: () {
                                          // TODO: Implement save to favorites
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.share),
                                        onPressed: () {
                                          // TODO: Implement share functionality
                                        },
                                      ),
                                    ],
                                  ),
                                  // TODO: Add generated image placeholder
                                  Container(
                                    height: 200,
                                    margin: const EdgeInsets.only(top: 16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.image,
                                        size: 48,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
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