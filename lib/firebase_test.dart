import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saaf',
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase Test')),
        body: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('diseases').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final docs = snapshot.data!.docs;
            return ListView(
              children: [
                ListTile(title: Text('✅ Connected! ${docs.length} diseases found')),
                ...docs.map((d) => ListTile(title: Text(d['name']))),
              ],
            );
          },
        ),
      ),
    );
  }
}