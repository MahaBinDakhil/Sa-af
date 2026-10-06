import 'package:flutter/material.dart';
import 'analysis_result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Sample data simulating scan history records retrieved from database or local storage
  final List<Map<String, dynamic>> _historyData = [
    {
      'id': '1',
      'title': 'Healthy Leaf',
      'date': 'Oct 24, 2023 - 10:30 AM',
      'status': 'Healthy',
      'confidence': '98.5%',
      'imagePath': 'assets/images/leaf_sample.png',
      'isHealthy': true,
    },
    {
      'id': '2',
      'title': 'Leaf Spot Disease',
      'date': 'Oct 22, 2023 - 02:15 PM',
      'status': 'Infected',
      'confidence': '92.1%',
      'imagePath': 'assets/images/leaf_sample.png',
      'isHealthy': false,
    },
    {
      'id': '3',
      'title': 'Red Palm Weevil',
      'date': 'Oct 15, 2023 - 09:45 AM',
      'status': 'Infected',
      'confidence': '95.0%',
      'imagePath': 'assets/images/leaf_sample.png',
      'isHealthy': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF17372A);
    const Color backgroundColor = Color(0xFFF4FFF5);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Scan History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _historyData.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _historyData.length,
              itemBuilder: (context, index) {
                final item = _historyData[index];
                return _buildHistoryCard(context, item);
              },
            ),
    );
  }

  // Widget to display when history list is empty
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.history_toggle_off,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No scan history found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Widget to build individual scan history cards
  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> item) {
    final bool isHealthy = item['isHealthy'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          // Navigating to AnalysisResultScreen upon tapping an item
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AnalysisResultScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Scan Thumbnail Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(
                    item['imagePath'],
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),

                // Scan Details Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF17372A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['date'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Status Tag (Healthy / Infected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isHealthy
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['status'],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isHealthy
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Confidence Score
                          Text(
                            'Confidence: ${item['confidence']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Forward Arrow Icon
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}