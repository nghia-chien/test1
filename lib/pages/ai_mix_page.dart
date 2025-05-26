import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import 'chat_screen.dart';

class AiMixPage extends StatelessWidget {
  const AiMixPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'AI Fashion Assistant',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Magic',
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Get personalized fashion advice and recommendations',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontFamily: 'Bildan',
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    isDarkMode: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat),
            label: const Text(
              'Chat with AI Assistant',
              style: TextStyle(fontFamily: 'Bildan'),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Get instant fashion advice, outfit recommendations, and style tips from our AI assistant',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontFamily: 'Bildan',
              ),
            ),
          ),
        ],
      ),
    );
  }
} 