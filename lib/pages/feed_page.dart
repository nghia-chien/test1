import 'package:flutter/material.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<FashionPost> _posts = [
    FashionPost(
      username: 'Sophie_Style',
      title: 'Summer Vibes Collection',
      description: 'Perfect outfit for a beach day! 🌊',
      imageUrl: 'https://picsum.photos/400/600?random=1',
      likes: 234,
      comments: 45,
    ),
    FashionPost(
      username: 'Fashion_Forward',
      title: 'Urban Street Style',
      description: 'Mixing casual with chic for the perfect street look 🌆',
      imageUrl: 'https://picsum.photos/400/600?random=2',
      likes: 567,
      comments: 89,
    ),
    FashionPost(
      username: 'Trendsetter',
      title: 'Autumn Essentials',
      description: 'Cozy and stylish pieces for fall 🍂',
      imageUrl: 'https://picsum.photos/400/600?random=3',
      likes: 789,
      comments: 123,
    ),
    FashionPost(
      username: 'ClassicWardrobe',
      title: 'Timeless Elegance',
      description: 'Classic pieces that never go out of style ✨',
      imageUrl: 'https://picsum.photos/400/600?random=4',
      likes: 432,
      comments: 67,
    ),
  ];

  List<FashionPost> get filteredPosts {
    if (_searchQuery.isEmpty) {
      return _posts;
    }
    return _posts.where((post) {
      return post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          post.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          post.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search fashion items...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Posts List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                final post = filteredPosts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            'https://picsum.photos/50/50?random=${index + 10}',
                          ),
                        ),
                        title: Text(
                          post.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(post.title),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            // TODO: Implement post options
                          },
                        ),
                      ),

                      // Image
                      AspectRatio(
                        aspectRatio: 4 / 5,
                        child: Image.network(
                          post.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // Actions
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.favorite_border),
                              onPressed: () {
                                // TODO: Implement like functionality
                              },
                            ),
                            Text('${post.likes}'),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.comment_outlined),
                              onPressed: () {
                                // TODO: Implement comment functionality
                              },
                            ),
                            Text('${post.comments}'),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.bookmark_border),
                              onPressed: () {
                                // TODO: Implement save functionality
                              },
                            ),
                          ],
                        ),
                      ),

                      // Description
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '2 hours ago',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class FashionPost {
  final String username;
  final String title;
  final String description;
  final String imageUrl;
  final int likes;
  final int comments;

  FashionPost({
    required this.username,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.likes,
    required this.comments,
  });
} 