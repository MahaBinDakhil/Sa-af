import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScanDetailsScreen extends StatefulWidget {
  final String scanId;

  const ScanDetailsScreen({super.key, required this.scanId});

  @override
  State<ScanDetailsScreen> createState() => _ScanDetailsScreenState();
}

class _ScanDetailsScreenState extends State<ScanDetailsScreen> {
  bool _showXAI = false;
  String _xaiTab = 'Heatmap';

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            if (_showXAI) {
              setState(() => _showXAI = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _showXAI ? 'XAI Explanation' : 'Scan Details',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      // Stream real-time scan details from Firestore using scanId
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('scans')
            .doc(widget.scanId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Scan details not found.'));
          }

          // Extract document data
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final bool isHealthy = (data['status'] ?? '').toString().toLowerCase() == 'healthy';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display the current selected image (Original, Heatmap, or Region)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _getDisplayImage(data),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(height: 200, color: Colors.grey[300], child: const Icon(Icons.image)),
                  ),
                ),
                const SizedBox(height: 16),

                if (!_showXAI) ...[
                  // Main details card
                  _buildMainDetailsCard(data, isHealthy),
                  const SizedBox(height: 16),

                  // Disease description section
                  const Text('About this disease', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    data['description'] ?? 'No description available for this condition.',
                    style: const TextStyle(color: Colors.grey, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  // Button to switch to XAI view (REQ4)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C6B50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.white),
                      label: const Text('View XAI Explanation', style: TextStyle(color: Colors.white)),
                      onPressed: () => setState(() => _showXAI = true),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Button to ask chatbot for assistance
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4C6B50)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF4C6B50)),
                      label: const Text('Ask the Chatbot', style: TextStyle(color: Color(0xFF4C6B50))),
                      onPressed: () {},
                    ),
                  ),
                ] else ...[
                  // XAI explanation view
                  _buildXaiView(data),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // Build primary summary card for diagnosis details
  Widget _buildMainDetailsCard(Map<String, dynamic> data, bool isHealthy) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['title'] ?? 'Unknown Scan', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isHealthy ? Colors.green[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data['status'] ?? 'Diseased',
                  style: TextStyle(color: isHealthy ? Colors.green[800] : Colors.orange[800], fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(data['date'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Confidence', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('${data['confidence'] ?? 0}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: ((data['confidence'] ?? 0) as num) / 100,
            backgroundColor: Colors.grey[200],
            color: Colors.brown[400],
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  // Build XAI explanation view (Heatmap & Region toggles)
  Widget _buildXaiView(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Heatmap'),
              selected: _xaiTab == 'Heatmap',
              onSelected: (val) => setState(() => _xaiTab = 'Heatmap'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Region'),
              selected: _xaiTab == 'Region',
              onSelected: (val) => setState(() => _xaiTab = 'Region'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Grad-CAM++ heatmap: red areas are the parts of the photo that influenced the AI\'s decision the most.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How the AI decided', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _buildDecisionItem('1', 'Health check', data['status'] ?? 'Diseased', '99%'),
              const Divider(),
              _buildDecisionItem('2', 'Diseases type', data['title'] ?? 'Unknown', '${data['confidence'] ?? 0}%'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4C6B50)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF4C6B50)),
            label: const Text('Ask the Chatbot about this', style: TextStyle(color: Color(0xFF4C6B50))),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildDecisionItem(String num, String title, String subTitle, String percent) {
    return Row(
      children: [
        CircleAvatar(radius: 12, backgroundColor: Colors.grey[200], child: Text(num, style: const TextStyle(fontSize: 12, color: Colors.black))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Text(subTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Text(percent, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  // Get image URL dynamically depending on selected XAI tab
  String _getDisplayImage(Map<String, dynamic> data) {
    if (_showXAI) {
      if (_xaiTab == 'Heatmap') {
        return data['heatmapUrl'] ?? data['imageUrl'] ?? '';
      } else {
        return data['regionUrl'] ?? data['imageUrl'] ?? '';
      }
    }
    return data['imageUrl'] ?? '';
  }
}