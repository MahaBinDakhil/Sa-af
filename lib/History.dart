import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'scan_details_screen_History.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text('History', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Search bar (REQ7)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by diseases name',
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter chips for status selection (REQ3)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['All', 'Healthy', 'Diseased'].map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  selectedColor: const Color(0xFF4C6B50),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Real-time listener for user scans ordered from newest to oldest (REQ1)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('scans')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Show empty state if no scans exist (REQ5)
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(context);
                }

                // Local filtering logic for search and status chips
                var docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final status = (data['status'] ?? '').toString();

                  bool matchesSearch = title.contains(_searchQuery);
                  bool matchesFilter = true;

                  if (_selectedFilter == 'Healthy') {
                    matchesFilter = status.toLowerCase() == 'healthy';
                  } else if (_selectedFilter == 'Diseased') {
                    matchesFilter = status.toLowerCase() != 'healthy';
                  }

                  return matchesSearch && matchesFilter;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No matching scans found.'));
                }

                return Column(
                  children: [
                    // Display total scans count (REQ1)
                    Text(
                      '${docs.length} scan saved',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          return _buildScanCard(context, doc.id, data);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Individual scan card item (REQ2)
  Widget _buildScanCard(BuildContext context, String docId, Map<String, dynamic> data) {
    final bool isHealthy = (data['status'] ?? '').toString().toLowerCase() == 'healthy';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () {
          // Navigate to scan details screen passing document ID (REQ4)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScanDetailsScreen(scanId: docId),
            ),
          );
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            data['imageUrl'] ?? '',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(width: 50, height: 50, color: Colors.grey[300], child: const Icon(Icons.image)),
          ),
        ),
        title: Row(
          children: [
            Text(data['title'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isHealthy ? Colors.green[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                data['status'] ?? '',
                style: TextStyle(
                  fontSize: 10,
                  color: isHealthy ? Colors.green[800] : Colors.orange[800],
                ),
              ),
            ),
          ],
        ),
        subtitle: Text('Confidence: ${data['confidence'] ?? 0}%'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.grey),
          onPressed: () {
            // Trigger confirmation dialog for deletion (REQ6)
            _showDeleteDialog(context, docId);
          },
        ),
      ),
    );
  }

  // Empty state screen widget (REQ5)
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No scans yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Scan your first date palm and its\ndiagnosis will show up here.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C6B50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {},
            child: const Text('Start Scan', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // Deletion confirmation dialog (REQ6)
  void _showDeleteDialog(BuildContext context, String docId) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this scan?'),
        content: const Text('This scan will be removed from your history. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('scans')
                  .doc(docId)
                  .delete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}