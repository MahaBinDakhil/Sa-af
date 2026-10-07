import 'package:flutter/material.dart';

import 'theme/app_colors.dart';
import 'widgets/app_bottom_nav.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _cameraMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan',
          style: TextStyle(
            color: AppColors.forest,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Scan a palm leaf',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose a photo from your device or take a new one',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 36),

              // Upload and Camera switch
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    _modeButton(
                      title: 'Upload',
                      selected: !_cameraMode,
                      onTap: () => setState(() => _cameraMode = false),
                    ),
                    _modeButton(
                      title: 'Camera',
                      selected: _cameraMode,
                      onTap: () => setState(() => _cameraMode = true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // The large preview box changes with the selected mode
              Container(
                height: 340,
                decoration: BoxDecoration(
                  color: _cameraMode
                      ? const Color(0xFF222222)
                      : const Color(0xFFF0F5EA),
                  borderRadius: BorderRadius.circular(28),
                  border: _cameraMode
                      ? null
                      : Border.all(color: AppColors.forest, width: 2),
                ),
                child: Center(
                  child: Icon(
                    _cameraMode
                        ? Icons.photo_camera_outlined
                        : Icons.cloud_upload_outlined,
                    size: 70,
                    color: _cameraMode ? Colors.white : AppColors.forest,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // These buttons are visual only for now
              SizedBox(
                height: 74,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    _cameraMode
                        ? Icons.camera_alt_outlined
                        : Icons.photo_library_outlined,
                  ),
                  label: Text(
                    _cameraMode ? 'Take a photo' : 'Browse files',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Photo tips
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Photo tips',
                      style: TextStyle(
                        color: AppColors.forest,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text('• Take a clear photo of the leaf.'),
                    SizedBox(height: 6),
                    Text('• Make sure the lighting is good.'),
                    SizedBox(height: 6),
                    Text('• Make sure the whole leaf is visible in the photo.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        current: NavTab.scan,
        onHomeTap: () => Navigator.pop(context),
        onChatbotTap: () {},
        onFrameTap: () {},
        onHistoryTap: () {},
        onSettingsTap: () {},
      ),
    );
  }

  Widget _modeButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.forest : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.forest,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
