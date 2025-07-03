import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _userName;  

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userName = doc.data()?['name'] ?? 'Guest';
        });
      } else {
        setState(() {
          _userName = 'Guest';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7ECEF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 16.0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Greeting on the left
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Hi, ${_userName ?? 'Loading...'} 👋",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Icons on the right
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none, size: 28),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_outline, size: 28),
                      onPressed: () {},
                    ),
                  ],
                )
              ],
            ),
          )
          ,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _actionButton(Icons.file_upload, "Upload"),
                  _actionButton(Icons.checkroom, "Create"),
                  _actionButton(Icons.calendar_today, "Plan"),
                  _actionButton(Icons.bar_chart, "Review"),
                  _actionButton(Icons.history, "History"),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFA3C7E6),
                    radius: 20,
                    child: Image.network(
                      'https://storage.googleapis.com/a1aa/image/e1813bb2-c35b-444d-183b-06a6e0a3d4b6.jpg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7941D),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("Hỏi gì cũng được!", style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 64.0, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("AI Stylish", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF3A8EDC), width: 2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Gợi ý phong cách?',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      color: const Color(0xFF3A8EDC),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward, color: Colors.white),
                        onPressed: () {},
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Recent Outfits", style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _recentOutfitImg('https://storage.googleapis.com/a1aa/image/99891187-057f-40f6-48e3-726c266b71c7.jpg'),
                  _recentOutfitImg('https://storage.googleapis.com/a1aa/image/a7e61f45-ca02-4b50-d3ac-b305024747e3.jpg'),
                  _recentOutfitImg('https://storage.googleapis.com/a1aa/image/2b1cb033-039d-46b9-66a2-da15b53a35a4.jpg'),
                  _recentOutfitImg('https://storage.googleapis.com/a1aa/image/bd7e2998-776c-40ce-04d1-916082f07f7e.jpg'),
                  _recentOutfitImg('https://storage.googleapis.com/a1aa/image/9dc0b7b2-83af-4b1d-4690-6970febc8c92.jpg'),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF3A8EDC),
        unselectedItemColor: const Color(0xFF7F8C8D),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.sync), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'AI Stylist'),
          BottomNavigationBarItem(icon: Icon(Icons.checkroom), label: 'Welcome'),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Icon(icon, color: const Color(0xFF2C3E50), size: 24),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF2C3E50)))
      ],
    );
  }

  Widget _recentOutfitImg(String url) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 80,
      height: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(url, fit: BoxFit.cover),
      ),
    );
  }
}
