import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Default admin credentials
  static const String defaultAdminEmail = "admin@fashionmix.com";
  static const String defaultAdminPassword = "Admin@123";

  Future<UserCredential> signInAsAdmin() async {
    try {
      // Try to sign in with default admin credentials
      return await auth.signInWithEmailAndPassword(
        email: defaultAdminEmail,
        password: defaultAdminPassword,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // If admin doesn't exist, create one
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: defaultAdminEmail,
          password: defaultAdminPassword,
        );

        // Create admin document in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': defaultAdminEmail,
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });

        // Generate some test data after creating admin
        await _generateTestData();

        return userCredential;
      }
      rethrow;
    }
  }

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    final user = auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['role'] == 'admin';
  }

  // Generate test data for the app
  Future<void> _generateTestData() async {
    // Add test clothing items
    await _addTestClothingItems();
    
    // Add test users
    await _addTestUsers();
    
    // Add test outfits
    await _addTestOutfits();
  }

  Future<void> _addTestClothingItems() async {
    final clothingItems = [
      {
        'name': 'Basic White T-Shirt',
        'category': 'tops',
        'color': 'white',
        'imageUrl': 'https://example.com/white-tshirt.jpg',
        'brand': 'Test Brand',
        'price': 29.99,
      },
      {
        'name': 'Blue Jeans',
        'category': 'bottoms',
        'color': 'blue',
        'imageUrl': 'https://example.com/blue-jeans.jpg',
        'brand': 'Test Brand',
        'price': 59.99,
      },
      {
        'name': 'Black Sneakers',
        'category': 'shoes',
        'color': 'black',
        'imageUrl': 'https://example.com/black-sneakers.jpg',
        'brand': 'Test Brand',
        'price': 89.99,
      }
    ];

    for (var item in clothingItems) {
      await _firestore.collection('clothing').add({
        ...item,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin',
      });
    }
  }

  Future<void> _addTestUsers() async {
    final testUsers = [
      {
        'email': 'test1@example.com',
        'name': 'Test User 1',
        'role': 'user',
      },
      {
        'email': 'test2@example.com',
        'name': 'Test User 2',
        'role': 'user',
      }
    ];

    for (var user in testUsers) {
      await _firestore.collection('users').add({
        ...user,
        'createdAt': FieldValue.serverTimestamp(),
        'isTestAccount': true,
      });
    }
  }

  Future<void> _addTestOutfits() async {
    final testOutfits = [
      {
        'name': 'Casual Day Out',
        'description': 'Perfect for a casual day out with friends',
        'items': ['Basic White T-Shirt', 'Blue Jeans', 'Black Sneakers'],
        'style': 'casual',
        'season': 'all',
      },
      {
        'name': 'Summer Style',
        'description': 'Light and comfortable summer outfit',
        'items': ['Basic White T-Shirt', 'Blue Jeans'],
        'style': 'summer',
        'season': 'summer',
      }
    ];

    for (var outfit in testOutfits) {
      await _firestore.collection('outfits').add({
        ...outfit,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin',
        'isTestData': true,
      });
    }
  }

  // Method to clear test data
  Future<void> clearTestData() async {
    // Clear test clothing items
    final clothingQuery = await _firestore.collection('clothing')
        .where('createdBy', isEqualTo: 'admin')
        .get();
    for (var doc in clothingQuery.docs) {
      await doc.reference.delete();
    }

    // Clear test users
    final usersQuery = await _firestore.collection('users')
        .where('isTestAccount', isEqualTo: true)
        .get();
    for (var doc in usersQuery.docs) {
      await doc.reference.delete();
    }

    // Clear test outfits
    final outfitsQuery = await _firestore.collection('outfits')
        .where('isTestData', isEqualTo: true)
        .get();
    for (var doc in outfitsQuery.docs) {
      await doc.reference.delete();
    }
  }
} 